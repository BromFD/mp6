import 'package:flutter/material.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';

class PlayerProvider extends ChangeNotifier {
  Directory audioFilesDirectory = Directory("/storage/emulated/0/Music"); // Папка с музыкой
  List<String> audioFilesPaths = []; // Пути к файлам внутри папки с музыкой
  List<Map<String, dynamic>> audioFiles = []; // Список аудиофайлов с метаданными
  List<AudioSource> audioSources = []; // Список текущих треков с которыми будет работать аудио плеер (UI тоже будет полагатся на него)
  Set<int> audioSourcesIndexes = {}; // Индексы audioSources которые будут добавлены в плейлист
  Map<String, int> colorSchemeHexCodes = { // Hex коды цветовой схемы, нужны т.к Hive не хранит объекты типа Color
    "background": 0xFF000000,
    "icon": 0xFF9C27B0,
    "text": 0xFFFFFFFF,
  };
  Map<String, Color> colorScheme = {};  // Отвечает за цветовую схему которую пользователь выбирает в настройках
  final AudioPlayer player = AudioPlayer(); // Экземпляр класса AudioPlayer
  Map<String, dynamic>? currentAudioFile; // Текущий включенный трек и его метаданные
  Map<String, Set<int>> playlists = {}; // Хранит плейлисты
  bool isUserMakingPlaylist = false; // Используется для того, чтобы реюзнуть страницу медиатеки, для выбора песен в плейлисте.
  bool isUserAddToExistingPlaylist = false; // Используется для того, чтобы реюзнуть страницу плейлистов, для выбора плейлиста куда пользователь захочет добавить песню.
  List<dynamic> addedAudio = []; // Хранит данные о том куда и что добавлять в плейлист
  String currentPlaylist = ""; // Текущий выбранный плейлист
  List<AudioSource> filteredSources = []; // Отфильтрованные по названию песни
  bool isSearchMode = false; // Показывает использовал ли пользователь поиск
  Map<int, int> indexesOfSearchedAudios = {}; // Индекс найденного поиском трека в его плейлисте


  PlayerProvider() { // Срабатывает на старте
    onLaunch();
  }

  // Нераспределённые функции

  // Штуки которые мы делаем 1 раз при загрузке приложения
  Future<void> onLaunch () async {
    await askPermissions();
    await loadItemsFromBoxes(); // Загружает элементы из коробок
    colorScheme.isEmpty ? updateColors() : null;
    await scanAudioFiles();
    await loadAudioFiles(); // Загружает аудиофайлы 1 раз при старте
    player.currentIndexStream.listen((index) { //Автоматическое обновление информации о текущем аудиофайле при смене индекса трека
      if (index != null) {
        currentAudioFile = audioFiles[int.parse((audioSources[index] as IndexedAudioSource).tag.id)];
        notifyListeners();
      }
    });
  }

  //Запрос разрешений на чтение и запись в хранилище телефона (Для библиотек)
  Future<void> askPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.audio.isDenied) {
        await Permission.audio.request();
      }

      if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }

      if (await Permission.manageExternalStorage.isDenied) {
        await Permission.manageExternalStorage.request();
      }
    }
  }

  // Сканирование аудио файлов с помощью PhotoManager
  Future<void> scanAudioFiles() async {
      final List<String> supportedFormats = ['.mp3', '.flac', '.m4a', '.wav', '.ogg'];
      List<String> foundSongs = [];

      List<Directory> directoriesToScan = [Directory("/storage/emulated/0/")];

      while (directoriesToScan.isNotEmpty) {
        Directory currentDir = directoriesToScan.removeAt(0);

        try {
          List<FileSystemEntity> entities = currentDir.listSync();

          for (var entity in entities) {
            if (entity is Directory) {
              String folderName = p.basename(entity.path);
              if (!folderName.startsWith('.') && folderName != 'Android') {
                directoriesToScan.add(entity);
              }
            } else if (entity is File) {
              String ext = p.extension(entity.path).toLowerCase();
              if (supportedFormats.contains(ext)) {
                foundSongs.add(entity.path);
              }
            }
          }
        } catch (e) {
          continue;
        }
      }
      audioFilesPaths = foundSongs;
      notifyListeners();
  }

  //Выбор директории c аудио файлами при помощи библиотеки FilePicker
  Future<void> pickAudioFilesDirectory() async {
    audioFilesPaths = []; // Очищаем пути, чтобы перезаписать, те которые были загружены сканером
    String? path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      audioFilesDirectory = Directory(path);
      addItemToBox(audioFilesDirectory.path, "audioFilesDirectory");
      notifyListeners();
      loadAudioFiles();
    }
  }

  // Функции для работы с аудио

  //Загрузка аудио файлов из указанной директории
  Future<void> loadAudioFiles() async {
    audioFiles = [];
    audioFilesPaths.isEmpty ? audioFilesPaths = [for (var file in audioFilesDirectory.listSync()) if(file is File) file.path] : null;
    int index = 0;
    for (var path in audioFilesPaths) {
      try {
        Metadata metadata = await MetadataGod.readMetadata(file: path);
        Map<String, dynamic> audioFile = {
          "id": index,
          "url": path,
          "name": p.basename(path),
          "picture": metadata.picture,
          "duration": metadata.durationMs,
          "size": metadata.fileSize,
        };
        audioFiles.add(audioFile);
        index++;
      } catch(e) {
        null;
      }
    }
    createMainList();
  }

  // Задание списка всех треков для управления
  Future<void> createMainList () async {
    audioSourcesIndexes = {for (var index = 0; index < audioFiles.length; index++) index};
    playlists["main"] = audioSourcesIndexes;
    currentPlaylist = "main";
    audioSources = [for (var index in audioSourcesIndexes) AudioSource.uri(Uri.parse(audioFiles[index]["url"]),
        tag: MediaItem(
          id: '$index',
          title: audioFiles[index]["name"],
        ),
    )];
    await player.setAudioSources(audioSources, initialIndex: 0, initialPosition: Duration.zero,
    shuffleOrder: DefaultShuffleOrder());
    notifyListeners();
  }

  // Запускает выбранный трек
  void setAudioFile(int index) {
    player.seek(Duration.zero, index: index);
    notifyListeners();
    play();
  }

  // Запуск проигрывания аудио файла
  void play() {
    player.play();
    notifyListeners();
  }

  // Постановка проигрывания на паузу
  void pause() {
    player.pause();
    notifyListeners();
  }

  // Поставить следующий трек в списке
  void playNext() {
    player.seekToNext();
    notifyListeners();
  }

  // Поставить предыдущий трек в списке
  void playPrevious() {
    player.seekToPrevious();
    notifyListeners();
  }

  // Создаёт новый плейлист
  void createPlaylist(String name) {
    playlists[name] = {};
    audioSourcesIndexes = {};
    notifyListeners();
  }

  // Отменяет создание плейлиста
  void denyCreation() {
    playlists.remove(playlists.keys.last);
    notifyListeners();
  }

  // Удаляет плейлист
  void deletePlaylist(String name) {
    playlists.remove(name);
    addItemToBox(playlists, "playlist");
    notifyListeners();
  }

  // Переименовывает плейлист
  Future<void> renamePlaylist(String oldName, String newName) async {
    playlists[newName] = playlists.remove(oldName)!;
    addItemToBox(playlists, "playlist");
    notifyListeners();
  }

  // Добавляет индекс в плейлист в процессе создания
  void addAudioToPlaylist(int index) {
    audioSourcesIndexes.add(index);
    notifyListeners();
  }

  // Убирает индекс из плейлиста в процессе создания
  void removeAudioFromPlaylist(int index) {
    audioSourcesIndexes.remove(index);
    notifyListeners();
  }

  // Добавляет индексы треков в плейлист
  void addSourcesToPlaylist() {
    playlists[playlists.keys.last] = audioSourcesIndexes;
    audioSourcesIndexes = {};
    addItemToBox(playlists, "playlist");
    notifyListeners();
  }

  // Очищает списки id
  void clearIds() {
    audioSourcesIndexes = {};
    notifyListeners();
  }

  // Тут понятно из названия и содержания
  Future<void> switchPlaylistCreationFlag() async {
    isUserMakingPlaylist ? isUserMakingPlaylist = false : isUserMakingPlaylist = true;
    notifyListeners();
  }

  // Устанавливает текущий плейлист
  Future<void> setCurrentPlaylist(String name) async {
    currentPlaylist = name;
    audioSources = [for (var index in playlists[name]!) AudioSource.uri(Uri.parse(audioFiles[index]["url"]),
        tag: MediaItem(
          id: '$index',
          title: audioFiles[index]["name"],
        ),
    )];
    await player.setAudioSources(audioSources, initialIndex: 0, initialPosition: Duration.zero,
        shuffleOrder: DefaultShuffleOrder());
    notifyListeners();
  }

  // Добавляет аудио в уже созданный плейлист
  void addToExistingPlaylist() {
    playlists[addedAudio[1]]!.add(addedAudio[0]);
    addedAudio = [];
    addItemToBox(playlists, "playlist");
    notifyListeners();
  }

  // Удаляет аудио из текущего плейлиста
  Future<void> removeFromExistingPlaylist(int audioId) async {
    playlists[currentPlaylist]!.remove(audioId);
    int index = 0;
    int? removeIndex;
    List<AudioSource> tempSources = [];
    for (var (source as IndexedAudioSource) in audioSources){
      if (int.parse(source.tag.id) != audioId) {
        tempSources.add(source);
      } else {
        removeIndex = index;
      }
      index++;
    }
    audioSources = tempSources;
    player.removeAudioSourceAt(removeIndex!);
    addItemToBox(playlists, "playlist");
    notifyListeners();
  }

  // Тут понятно из названия и содержания
  void switchAddToExistingPlaylistFlag() {
    isUserAddToExistingPlaylist ? isUserAddToExistingPlaylist = false : isUserAddToExistingPlaylist = true;
    notifyListeners();
  }

  // Переключает смешанный режим воспроизведения
  void switchShuffle(bool enabled) {
    player.setShuffleModeEnabled(enabled);
    notifyListeners();
  }

  // Выводит найденные по названию треки
  Future<void> showOnlySearched(String name) async {
    isSearchMode = true;
    if (name != "") {
      Set<int> currentPlaylistIndexes = playlists[currentPlaylist]!;
      filteredSources = [];
      int index = 0;
      for (var sourceIndex in currentPlaylistIndexes) {
        if ((audioFiles[sourceIndex]["name"].toLowerCase()).contains(name.toLowerCase())){
          filteredSources.add(AudioSource.uri(Uri.parse(audioFiles[sourceIndex]["url"]),
            tag: MediaItem(
              id: '$sourceIndex',
              title: audioFiles[sourceIndex]["name"],
              ),
            ),
          );
          indexesOfSearchedAudios[sourceIndex] = index;
        }
        index++;
      }
      audioSources = filteredSources;
    } else {
      audioSources = [for (var sourceIndex in playlists[currentPlaylist]!)
        AudioSource.uri(Uri.parse(audioFiles[sourceIndex]["url"]),
          tag: MediaItem(
            id: '$sourceIndex',
            title: audioFiles[sourceIndex]["name"],
          ),
        ),
      ];
    }
    notifyListeners();
  }

  // Функции для изменения внешнего вида приложения

  //Изменение цветовой схемы приложения
  Future<void> changeColorScheme(int hexCode, String object) async {
    colorSchemeHexCodes[object] = hexCode;
    addItemToBox(colorSchemeHexCodes, "colorScheme");
    updateColor(hexCode, object);
    notifyListeners();
  }

  // Обновление цвета
  void updateColor(int hexCode, String object){
    colorScheme[object] = Color(hexCode);
    notifyListeners();
  }

  // Обновление всех цветов
  void updateColors() {
    colorScheme = {
      for (var scheme in (colorSchemeHexCodes).entries)
        scheme.key : Color(scheme.value)
    };
    notifyListeners();
  }

  // Функции связанные с хранением данных между перезаходами

  void addItemToBox(dynamic item, String key) {
    final box = Hive.box("playerData");
    if (key == "playlist") {
      item = {
        for (var playlist in item.entries)
          playlist.key : List<int>.from(playlist.value)
      };
    }
    box.put(key, item);
  }

  Future<void> loadItemsFromBoxes() async {
    final playerData = Hive.box("playerData");
    final rawPlaylists = playerData.get("playlist", defaultValue: {});
    final rawColorScheme = playerData.get("colorScheme", defaultValue: colorSchemeHexCodes);
    playlists = convertRawToOriginal(rawPlaylists, "playlist");
    colorSchemeHexCodes = convertRawToOriginal(rawColorScheme, "colorScheme");
    audioFilesDirectory = Directory(playerData.get("audioFilesDirectory", defaultValue: audioFilesDirectory.path).toString());
    updateColors();
    notifyListeners();
  }

  dynamic convertRawToOriginal(dynamic raw, String object) {
    dynamic original;
    if (object == "playlist") {
      original = {
        for (var playlist in (raw as Map).entries)
          playlist.key.toString(): {for (var index in (playlist.value as List<int>)) index}
      };
    }

    if (object == "colorScheme") {
      original = {
        for (var scheme in (raw as Map).entries)
          scheme.key.toString() : (scheme.value as int)
      };
    }
    return original;
  }
}

