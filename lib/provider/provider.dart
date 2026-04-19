import 'dart:math';

import 'package:chuni_player_revamped/custom_widgets.dart';
import 'package:chuni_player_revamped/log/logger.dart';
import 'package:flutter/material.dart' hide Element;
import 'package:metadata_god/metadata_god.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/dom_parsing.dart';
import 'package:html/parser.dart';
import 'package:punycoder/punycoder.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:media_store_plus/media_store_plus.dart' hide Document;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:on_audio_query/on_audio_query.dart';

class PlayerProvider extends ChangeNotifier {
  Directory audioFilesDirectory = Directory("/storage/emulated/0/Music"); // Папка с музыкой
  List<Uri> audioFilesUris = []; // Пути к файлам внутри папки с музыкой
  List<Map<String, dynamic>> audioFiles = []; // Список аудиофайлов с метаданными
  List<AudioSource> audioSources = []; // Список текущих треков с которыми будет работать аудио плеер (UI тоже будет полагатся на него)
  Set<int> audioSourcesIndexes = {}; // Индексы audioSources которые будут добавлены в плейлист
  Map<String, int> colorSchemeHexCodes = { // Hex коды цветовой схемы, нужны т.к Hive не хранит объекты типа Color
    "background": 0xFF1E1E1E,
    "icon": 0xFF9C27B0,
    "text": 0xFFFFFFFF,
  };
  Map<String, Color> colorScheme = {};  // Отвечает за цветовую схему которую пользователь выбирает в настройках
  final equalizer = AndroidEqualizer(); // Эквалайзер
  late final AndroidEqualizerParameters parameters; // Параметры эквалайзера
  late final List<AndroidEqualizerBand> bands; // Дорожки
  List<double> gainList = []; // Усиление дорожек
  AudioPlayer player = AudioPlayer(); // Экземпляр класса AudioPlayer
  Map<String, dynamic>? currentAudioFile; // Текущий включенный трек и его метаданные
  Map<String, Set<int>> playlists = {}; // Хранит плейлисты
  bool isUserMakingPlaylist = false; // Используется для того, чтобы реюзнуть страницу медиатеки, для выбора песен в плейлисте.
  bool isUserAddToExistingPlaylist = false; // Используется для того, чтобы реюзнуть страницу плейлистов, для выбора плейлиста куда пользователь захочет добавить песню.
  List<dynamic> addedAudio = []; // Хранит данные о том куда и что добавлять в плейлист
  String currentPlaylist = ""; // Текущий выбранный плейлист
  List<AudioSource> filteredSources = []; // Отфильтрованные по названию песни
  bool isSearchMode = false; // Показывает использовал ли пользователь поиск
  Map<int, int> indexesOfSearchedAudios = {}; // Индекс найденного поиском трека в его плейлисте
  int sleepId = 0; // Нужен для того, чтобы сработала только последняя функция ухода в сон, также позволяет отменить уход в сон
  List<Map<String, String>> foundAudioFiles = []; // Отображает найденные в поиске по интернету треки
  final dio = Dio( // Делает запросы
      BaseOptions(
        followRedirects: true,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
          'Accept-Language': 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7',
          'Referer': 'https://google.com/',
        },
      )
  );
  bool loaded = false; // Чекает прогружены ли треки на старте
  late int sdkVersion; // Текущая версия SDK
  final mediaStorePlugin = MediaStore(); // Объект класса медиастор, тащит из файлов URI
  final onAudioQuery = OnAudioQuery(); // Старый, но не добрый товарищ
  bool ignoreInterruptions = false; // Отвечает за игнорирование прерывания воспроизведения
  Set<int> favoriteAudios = {}; // Избранные треки
  List<String> redirects = [];

  PlayerProvider() { // Срабатывает на старте
    onLaunch();
  }

  // Нераспределённые функции

  // Штуки которые мы делаем 1 раз при загрузке приложения
  Future<void> onLaunch () async {
    MediaStore.appFolder = "ChuniPlayer"; // Ставит папку для media_store_plus
    await loadItemsFromBoxes(); // Загружает элементы из коробок
    await checkSdk(); // Смотрит и ставит SDK версию
    await askPermissions(); // Разрешения
    player = AudioPlayer(
      handleInterruptions: !ignoreInterruptions,
      audioPipeline: AudioPipeline(
          androidAudioEffects: [
            equalizer,
          ]
      )
    ); // Создаём плеер
    await scanAudioFiles();
    colorScheme.isEmpty ? updateColors() : null;
    player.currentIndexStream.listen((index) { //Автоматическое обновление информации о текущем аудиофайле при смене индекса трека
      if (index != null && audioSources.isNotEmpty) {
        currentAudioFile = audioFiles[int.parse((audioSources[index] as IndexedAudioSource).tag.id)];
        notifyListeners();
      }
    });
    await initializeEqualizer();
    await prepareCookieManager();
    await MediaStore.ensureInitialized();
    await loadGain();
    loaded = true;
    notifyListeners();
  }

  // Проверка SDK версии
  Future<void> checkSdk() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    sdkVersion = androidInfo.version.sdkInt;
  }

  //Запрос разрешений на чтение и запись в хранилище телефона (Для библиотек)
  Future<void> askPermissions() async {
    if (Platform.isAndroid) {
      if (sdkVersion >= 33) {
        if (await Permission.audio.isDenied) {
          await Permission.audio.request();
        }
        if (await Permission.videos.isDenied) {
          await Permission.videos.request();
        }
        if (await Permission.photos.isDenied) {
          await Permission.photos.request();
        }
      } else {
        if (await Permission.storage.isDenied) {
          await Permission.storage.request();
        }
      }
    }
  }

  // Поделится лог файлом
  Future<void> shareLogFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logFile = File('${directory.path}/log.txt');

      if (await logFile.exists()) {
        await SharePlus.instance.share(
            ShareParams(
              text: 'Отправить файл логов',
              files: [XFile(logFile.path)],
            )
        );
      } else {
        showNotification("Файл логов еще не создан");
      }
    } catch (e) {
      showNotification("Ошибка при отправке логов: $e");
    }
  }

  // Изменяет переменную отвечающую за то как плеер реагирут на попытки поставить его на паузу извне
  void setInterruptionMode(bool mode) {
    ignoreInterruptions = mode;
    addItemToBox(ignoreInterruptions, "ignoreInterruptions");
    notifyListeners();
  }

  // Сканирование и загрузка аудио файлов с помощью on_audio_query
  Future<void> scanAudioFiles() async {
    audioFiles = [];
    if (await onAudioQuery.permissionsStatus()) {
      List<SongModel> audios = await onAudioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      int index = 0;
      for (var audio in audios) {
        try {
          Metadata metadata = await MetadataGod.readMetadata(file: audio.data);
          Map<String, dynamic> audioFile = {
            "id": index,
            "uri": Uri.parse(audio.uri!),
            "name": audio.title,
            "picture": metadata.picture,
            "duration": metadata.durationMs,
            "size": metadata.fileSize,
          };
          audioFiles.add(audioFile);
          index++;
        } catch (e) {
          appLog.e(e);
          null;
        }
      }
      createMainList();
  }
}

  //Выбор директории c аудио файлами при помощи библиотеки FilePicker
  //Временно убран (Может и навсегда)
  /* Future<void> pickAudioFilesDirectory() async {
    audioFilesPaths = []; // Очищаем пути, чтобы перезаписать, те которые были загружены сканером
    String? path = await FilePicker.platform.getDirectoryPath();
    if (path != null) {
      audioFilesDirectory = Directory(path);
      addItemToBox(audioFilesDirectory.path, "audioFilesDirectory");
      notifyListeners();
      loadAudioFiles();
    }
  } */

  // Функции для работы с аудио

  // Задание списка всех треков для управления
  Future<void> createMainList () async {
    audioSourcesIndexes = {for (var index = 0; index < audioFiles.length; index++) index};
    playlists["main"] = audioSourcesIndexes;
    currentPlaylist = "main";
    audioSources = [for (var index in audioSourcesIndexes) AudioSource.uri(
      audioFiles[index]["uri"],
        tag: MediaItem(
          id: '$index',
          title: audioFiles[index]["name"],
        ),
    )];
    audioSourcesIndexes = {};
    notifyListeners();
    await player.setAudioSources(audioSources, initialIndex: 0, initialPosition: Duration.zero,
    shuffleOrder: DefaultShuffleOrder());
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
    audioSources = [for (var index in playlists[name]!) AudioSource.uri(
      audioFiles[index]["uri"],
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

  // Добавляет в избранное
  void addToFavorites(int index) {
    favoriteAudios.add(index);
    addItemToBox(favoriteAudios.toList(), "favoriteAudios");
    notifyListeners();
  }

  // Убирает из избранного
  void removeFromFavorites(int index) {
    favoriteAudios.remove(index);
    addItemToBox(favoriteAudios.toList(), "favoriteAudios");
    notifyListeners();
  }

  Future<void> setFavoriteAudios() async {
    audioSources = [for (var index in favoriteAudios) AudioSource.uri(
      audioFiles[index]["uri"],
      tag: MediaItem(
        id: '$index',
        title: audioFiles[index]["name"],
      ),
    )];
    await player.setAudioSources(audioSources, initialIndex: 0, initialPosition: Duration.zero,
        shuffleOrder: DefaultShuffleOrder());
    notifyListeners();
  }

  // Тут понятно из названия и содержания
  void switchAddToExistingPlaylistFlag() {
    isUserAddToExistingPlaylist ? isUserAddToExistingPlaylist = false : isUserAddToExistingPlaylist = true;
    notifyListeners();
  }

  // Переключает смешанный режим воспроизведения
  void switchShuffle(bool enabled) {
    player.shuffle();
    player.setShuffleModeEnabled(enabled);
    notifyListeners();
  }

  // Устанавливает режим циклического произведения для одного или всех треков
  void setLoopMode (LoopMode mode) {
    player.setLoopMode(mode);
    notifyListeners();
  }

  // Установить таймер сна
  Future<void> setSleepTimer(int minutes) async {
    sleepId += 1;
    final mySleepId = sleepId;
    await Future.delayed(Duration(minutes: minutes));
    if (mySleepId == sleepId) {
      double currentVolume = player.volume;
      double fadePerSecond = currentVolume / 120;
      double volume = currentVolume;
      for (int second = 0; second < 120; second++) {
        volume = volume - fadePerSecond;
        await Future.delayed(Duration(seconds: 1));
        await player.setVolume(volume);
      }
      player.pause();
    }
  }

  // Отменить таймер сна
  Future<void> denySleepTimer() async {
    sleepId += 1;
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
          filteredSources.add(AudioSource.uri(
            audioFiles[sourceIndex]["uri"],
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
        AudioSource.uri(
          audioFiles[sourceIndex]["uri"],
          tag: MediaItem(
            id: '$sourceIndex',
            title: audioFiles[sourceIndex]["name"],
          ),
        ),
      ];
    }
    notifyListeners();
  }

  // Эквалайзер

  Future<void> initializeEqualizer() async {
    parameters = await equalizer.parameters;
    bands = parameters.bands;
    equalizer.setEnabled(true);
    notifyListeners();
  }

  void setGainList() async {
    gainList = [for (var band in bands) band.gain];
    addItemToBox(gainList, "gainList");
  }

  Future<void> loadGain() async {
    if (gainList.isNotEmpty) {
      int index = 0;
      for (var band in bands) {
        band.setGain(gainList[index]);
        index += 1;
      }
      notifyListeners();
    }
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

  void setTheme (String theme) {
    if (theme == "light") {
      colorSchemeHexCodes = {
        "background": 0xFFFFFFFF,
        "icon": 0xFF1E1E1E,
        "text": 0xFF1E1E1E,
      };
    }
    else if (theme == "dark") {
      colorSchemeHexCodes = {
        "background": 0xFF1E1E1E,
        "icon": 0xFFFFFFFF,
        "text": 0xFFFFFFFF,
      };
    }
    else if (theme == "blueSky") {
      colorSchemeHexCodes = {
        "background": 0xFF42AAFF,
        "icon": 0xFFFFFFFF,
        "text": 0xFFFFFFFF,
      };
    }
    addItemToBox(colorSchemeHexCodes, "colorScheme");
    updateColors();
  }

  // Функции связанные с поиском и скачиванием аудио с интернета

  // Сохраняет куки между редиректами
  Future<void> prepareCookieManager() async {
    final directory = await getApplicationDocumentsDirectory();
    final cookieJar = PersistCookieJar(
      ignoreExpires: true,
      storage: FileStorage(p.join(directory.path, ".cookies")),
    );
    dio.interceptors.add(CookieManager(cookieJar));
  }

  Future<void> showRedirects() async {
    for (var redirect in redirects) {
      showNotification(redirect);
      await Future.delayed(Duration(seconds: 3));
    }
  }

  // Ищет аудио по названию
  Future<void> searchAudioFiles(String title) async {
    String correctTitle = generateCorrectTitle(title);
    String searchQueryLink = Uri.parse("https://$correctTitle.skysound7.com/").toString();
    Response? response;
    try {
      response = await dio.get(searchQueryLink);
    } on DioException catch (e) {
      appLog.e(e);
    }
    if (response!.statusCode == 200) {
      Document searchQueryPage = parse(response.data);
      List<Element> foundAudio = searchQueryPage.querySelectorAll('[class*="adv_list_track"]');
      foundAudioFiles = [
        for (var audioData in foundAudio)
          {
            "name": audioData.querySelector('[class*="adv_name"]')?.querySelector("em")?.text ?? "",
            "artist": audioData.querySelector('[class*="adv_artist"]')?.text ?? "",
            "duration": audioData.querySelector('[class*="adv_duration"]')?.text ?? "",
            "trackPageUrl": audioData.querySelector('[class*="playlist-down"]')?.attributes['href'] ?? "",
          }
      ];
    }
    notifyListeners();
  }

  // Скачивает аудио
  Future<void> downloadAudio(String url, String name) async {

    String correctName = name.replaceAll(RegExp(r'[^\p{L}0-9 ().-]', unicode: true), "");
    try {
      var response = await dio.get(url);
      if (response.statusCode == 200) {
        Document trackPage = parse(response.data);
        String? downloadLink = trackPage.getElementById("SongView")?.attributes["href"].toString();
        Directory tempDir = await getApplicationDocumentsDirectory();
        String tempPath = "${tempDir.path}/$correctName.mp3";
        if (downloadLink != null) {
          try {
            await dio.download(downloadLink, tempPath);
            await mediaStorePlugin.saveFile(
                tempFilePath: tempPath,
                dirType: DirType.audio,
                dirName: DirName.music,
            );

            File disposed = File(tempPath);
            if (await disposed.exists()){
              await disposed.delete();
            }

            showNotification("Файл скачен успешно");
          } on Exception catch (e) {
            appLog.e(e);
            return showNotification(e.toString());
          }
        }
      }
      await scanAudioFiles();
      pause();
      return showNotification("Файл скачен успешно");

    } on DioException catch (e) {
      appLog.e(e);
      return showNotification(e.toString());
    }
  }

  // Запускает предпросмотр найденного трека
  Future<void> playFound(String url, String name, int id) async {
    String correctName = name.replaceAll(RegExp(r'[^\p{L}0-9 ().-]', unicode: true), "");
    try {
      var response = await dio.get(url);
      if (response.statusCode == 200) {
        Document trackPage = parse(response.data);
        String? downloadLink = trackPage.getElementById("SongView")?.attributes["href"].toString();
        if (downloadLink != null) {
          player.stop();
          await player.setUrl(downloadLink, tag:
          MediaItem(
            id: "f$id",
            title: correctName,
          ),);
          play();
        }
      }
    } on DioException catch (e) {
      appLog.e(e);
      return showNotification(e.toString());
    }
  }

  // Генерирует правильное название
  String generateCorrectTitle(String title) {
    String cleanedTitle = title.toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}0-9]', unicode: true), "-")
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    String encodedTitle;
    if (RegExp(r'[^a-zA-Z0-9-]').hasMatch(cleanedTitle)) {
      encodedTitle = "xn--${punycode.encode(cleanedTitle)}";
    } else {
      encodedTitle = cleanedTitle;
    }

    return encodedTitle;
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
    gainList = [for (var gain in playerData.get("gainList", defaultValue: [])) (gain as double)];
    ignoreInterruptions = playerData.get("ignoreInterruptions", defaultValue: false);
    favoriteAudios = {for (var index in playerData.get("favoriteAudios", defaultValue: [])) (index as int)};
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

