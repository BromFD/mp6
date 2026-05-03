import 'dart:async';
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
  Map<int, Map<String, dynamic>> audioFiles = {}; // Список аудиофайлов с метаданными
  List<AudioSource> audioSources = []; // Список текущих треков с которыми будет работать аудио плеер (UI тоже будет полагатся на него)
  List<AudioSource> currentAudioSources = []; // Аудио сурсы текущего прослушеваемого плейлиста
  Set<int> audioSourcesIds = {}; // Индексы audioSources которые будут добавлены в плейлист
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
  int? currentId; // id текущего трека в audioFiles
  Map<String, Set<int>> playlists = {}; // Хранит плейлисты
  bool isUserMakingPlaylist = false; // Используется для того, чтобы реюзнуть страницу медиатеки, для выбора песен в плейлисте.
  bool isUserAddToExistingPlaylist = false; // Используется для того, чтобы реюзнуть страницу плейлистов, для выбора плейлиста куда пользователь захочет добавить песню.
  List<dynamic> addedAudio = []; // Хранит данные о том куда и что добавлять в плейлист
  String currentPlaylist = ""; // Текущий выбранный плейлист
  List<AudioSource> filteredSources = []; // Отфильтрованные по названию песни
  bool isSearchMode = false; // Показывает использовал ли пользователь поиск
  bool isInteractingWithInput = false;
  List<int> indexesOfSearchedAudios = []; // Индекс найденного поиском трека в его плейлисте
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
  double downloadProgress = 0; // Отображает прогресс скачивания
  int? indexOfDownloaded; // Индекс трека который скачивается в данных момент в найденных треках
  bool readyToSetAudio = false; // Показывает готовность поставить аудио сурсы
  Map<String, dynamic> currentAudioInfo = {}; // Информация о текущем аудиотреке
  Timer? currentAudioTimer; // Ежесекундно обновляет информацию о текущем треке
  Map<int, String> audioPictures = {}; // Изображения к трекам
  Map<int, int?> sourcePositionTracker = {}; // Отслеживает текущее положение аудиосурсов
  bool shuffleMode = false;
  List<int> order = [];

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
    await loadAudioPictures();
    colorScheme.isEmpty ? updateColors() : null;
    await setStreams();
    await currentAudioUpdater();
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

  // Тут сидят все подписки
  Future<void> setStreams() async {

    // Сбор информации о текущем треке
    player.currentIndexStream.listen((index) { //Автоматическое обновление информации о текущем аудиофайле при смене индекса трека
      appLog.i(index);
      if (index != null && audioSources.isNotEmpty) {
        int sourceIndex = shuffleMode ? order[index] : index;
        currentId = int.parse((currentAudioSources[sourceIndex] as IndexedAudioSource).tag.id);
        currentAudioFile = audioFiles[currentId];
        currentAudioInfo["sourceIndex"] = sourceIndex;
        notifyListeners();
      }
    });

    player.positionStream.listen((position) { //Автоматическое обновление информации о текущем аудиофайле при смене позиции трека
      if (audioSources.isNotEmpty) {
        currentAudioInfo["position"] = position.inMicroseconds;
      }
    });

  }

  // Обновляет информацию о текущем треке
  Future<void> currentAudioUpdater() async {
    currentAudioTimer?.cancel();
    
    currentAudioTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      addItemToBox(currentAudioInfo, "currentAudioInfo");
    });
  }

  // Сканирование и загрузка аудио файлов с помощью on_audio_query
  Future<void> scanAudioFiles() async {
    audioFiles = {};
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
            "index": index, // Индекс для связи с audioSources
            "uri": Uri.parse(audio.uri!),
            "rawPath": audio.data,
            "name": audio.title,
            "picture": metadata.picture,
            "duration": metadata.durationMs,
            "size": metadata.fileSize,
          };
          audioFiles[audio.id] = audioFile;
          index++;
        } catch (e) {
          appLog.e(e);
          null;
        }
      }
      await checkDisposedTracks();
      await createMainList();
  }
}

Future<void> checkDisposedTracks() async {
    Set<int> allAudioIds = Set.from(audioFiles.keys);
    for (var playlist in playlists.values) {
      for (int id in List.from(playlist)) {
        if (!allAudioIds.contains(id)) {
          playlist.remove(id);
        }
      }
    }
    notifyListeners();
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
    audioSourcesIds = {for (var id in audioFiles.keys) id};
    playlists["main"] = audioSourcesIds;
    currentPlaylist = currentAudioInfo["playlist"];
    await setCurrentPlaylist(currentPlaylist);
    audioSourcesIds = {};
    order.isNotEmpty ? await setSources() : await setSources(initialIndex: currentAudioInfo["sourceIndex"], initialPosition: Duration(microseconds: currentAudioInfo["position"]));
    order.isNotEmpty ? await setShuffle(true, initialOrder: order) : null;
    notifyListeners();
  }

  // Запускает выбранный трек
  void setAudioFile(int index) {
    player.seek(Duration.zero, index: index);
    notifyListeners();
    play();
  }

  // Ставить аудио сурсы
  Future<void> setSources({int initialIndex = 0, Duration initialPosition = Duration.zero}) async {

      player.setAudioSources(
        audioSources,
        initialIndex: initialIndex,
        initialPosition: initialPosition,
    );
    readyToSetAudio = false;
    currentAudioSources = List.from(audioSources);
    notifyListeners();
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

  void updateSourcePositions() {
    int index = 0;
    List<int> correctOrder = order.isEmpty ? [] : [for (int i = 0; i < order.length; i++) order.indexOf(i)];
    for (var source in audioSources) {
      if (order.isEmpty) {
        sourcePositionTracker[int.parse((source as IndexedAudioSource).tag.id)] = index;
      } else {
        sourcePositionTracker[int.parse((source as IndexedAudioSource).tag.id)] = correctOrder[index];
      }
      index++;
    }
    notifyListeners();
  }

  // Создаёт новый плейлист
  void createPlaylist(String name) {
    playlists[name] = {};
    audioSourcesIds = {};
    setCurrentPlaylist("main");
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
  void addAudioToPlaylist(int id) {
    audioSourcesIds.add(id);
    notifyListeners();
  }

  // Убирает индекс из плейлиста в процессе создания
  void removeAudioFromPlaylist(int id) {
    audioSourcesIds.remove(id);
    notifyListeners();
  }

  // Добавляет индексы треков в плейлист
  void addSourcesToPlaylist() {
    playlists[playlists.keys.last] = audioSourcesIds;
    audioSourcesIds = {};
    addItemToBox(playlists, "playlist");
    notifyListeners();
  }

  // Очищает списки id
  void clearIds() {
    audioSourcesIds = {};
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
    currentAudioInfo["playlist"] = currentPlaylist;
    currentAudioInfo["order"] = [];
    if (currentPlaylist != "favorite") {
      audioSources = [for (var id in playlists[name]!) AudioSource.uri(
        audioFiles[id]?["uri"],
          tag: MediaItem(
            id: '$id',
            title: audioFiles[id]?["name"],
          ),
      )];
    } else {
      audioSources = [for (var id in favoriteAudios) AudioSource.uri(
        audioFiles[id]?["uri"],
        tag: MediaItem(
          id: '$id',
          title: audioFiles[id]?["name"],
        ),
      )];
    }
    updateSourcePositions();
    readyToSetAudio = true;
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
  void addToFavorites(int id) {
    favoriteAudios.add(id);
    addItemToBox(favoriteAudios.toList(), "favoriteAudios");
    notifyListeners();
  }

  // Убирает из избранного
  void removeFromFavorites(int index) {
    favoriteAudios.remove(index);
    addItemToBox(favoriteAudios.toList(), "favoriteAudios");
    notifyListeners();
  }

  // Тут понятно из названия и содержания
  void switchAddToExistingPlaylistFlag() {
    isUserAddToExistingPlaylist ? isUserAddToExistingPlaylist = false : isUserAddToExistingPlaylist = true;
    notifyListeners();
  }

  // Переключает смешанный режим воспроизведения
  Future<void> setShuffle(bool enabled, {List<int> initialOrder = const []}) async {
    shuffleMode = enabled;
    if (shuffleMode){
      if (initialOrder.isNotEmpty) {
        if (player.processingState == ProcessingState.idle || player.processingState == ProcessingState.loading) { // Ждём загрузки треков
          await player.processingStateStream.firstWhere(
                  (state) => state != ProcessingState.idle && state != ProcessingState.loading
          );
        }
        currentAudioInfo["order"] = initialOrder;
        final orderedSources = [for (int index in initialOrder) audioSources[index]];
        await player.removeAudioSourceRange(0, audioSources.length);
        await player.addAudioSources(orderedSources);
        await player.seek(Duration(microseconds: currentAudioInfo["position"]), index: order.indexOf(currentAudioInfo["sourceIndex"]));
      } else {
        final shuffledIndices = [for (int index in player.effectiveIndices) if (index != sourcePositionTracker[currentId]) index];
        shuffledIndices.shuffle();
        final shuffledSources = [for (int index in shuffledIndices) audioSources[index]];
        order = [sourcePositionTracker[currentId]!] + shuffledIndices;
        currentAudioInfo["order"] = order;
        await player.moveAudioSource(sourcePositionTracker[currentId]!, 0);
        await player.removeAudioSourceRange(1, audioSources.length);
        await player.addAudioSources(shuffledSources);
      }
      updateSourcePositions();
      notifyListeners();
    } else {
      disableShuffle();
      setSources();
    }
  }

  Future<void> disableShuffle() async {
    shuffleMode = false;
    order = [];
    currentAudioInfo["order"] = order;
    updateSourcePositions();
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
      Set<int> currentPlaylistIds = currentPlaylist == "favorite" ? favoriteAudios : playlists[currentPlaylist]!;
        indexesOfSearchedAudios = [for (var id in currentPlaylistIds) if (audioFiles[id]!["name"].toLowerCase().contains(name.toLowerCase())) id];
    }
    notifyListeners();
  }


  void setIsInteractingWithInput(bool isInteracting) async {
    isInteractingWithInput = isInteracting;
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

  Future<void> loadAudioPictures() async {
    for (var id in audioPictures.keys) {
      audioFiles[id]!["picture"] = Picture(mimeType: "image/${audioPictures[id]!.substring(audioPictures[id]!.lastIndexOf(".") + 1)}", data: File(audioPictures[id]!).readAsBytesSync());
    }
    notifyListeners();
  }

  Future<void> setAudioPicture() async {
    FilePickerResult? trackImage = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (trackImage != null) {
      String trackImagePath = trackImage.files.first.path!;
      File trackImageFile = File(trackImagePath);
      Picture trackPicture = Picture(mimeType: "image/${trackImagePath.substring(trackImagePath.lastIndexOf(".") + 1)}", data: trackImageFile.readAsBytesSync());
      audioFiles[currentId]!["picture"] = trackPicture;
      audioPictures[currentId!] = trackImagePath;
      addItemToBox(audioPictures, "audioPictures");
      notifyListeners();
    }
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

  // Ищет аудио по названию
  Future<void> searchAudioFiles(String title) async {
    String correctTitle = generateCorrectTitle(title);
    String searchQueryLink = Uri.parse("https://$correctTitle.skysound7.com/").toString();
    Response? response;
    Document? searchQueryPage;
    try {
      response = await dio.get(searchQueryLink);
      searchQueryPage = parse(response.data);
    } on Exception {
      try {
        response = await dio.get(
            "http://82.202.136.97:8080/fetch",
            queryParameters: {"target_url": searchQueryLink}
        );
        searchQueryPage = parse(response.data['html']);
      } catch (e) {
        showNotification("Не удалось установить соединение. Проверьте соединение с интернетом или отключите ВПН.");
      }
    }

    if (searchQueryPage == null) return;

    if (response?.statusCode == 200) {
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
  Future<void> downloadAudio(String url, String name, int id) async {

    String correctName = name.replaceAll(RegExp(r'[^\p{L}0-9 ().-]', unicode: true), "");
    Response? response;
    Document? trackPage;
    try {
      response = await dio.get(url);
      trackPage = parse(response.data);
    } on Exception {
      try {
        response = await dio.get(
            "http://82.202.136.97:8080/fetch",
            queryParameters: {"target_url": url}
        );
        trackPage = parse(response.data['html']);
      } catch(e) {
        showNotification("Не удалось установить соединение. Проверьте соединение с интернетом или отключите ВПН.");
      }
    }

    if (trackPage == null) return;

    if (response?.statusCode == 200) {
      String? downloadLink = trackPage.getElementById("SongView")?.attributes["href"].toString();
      Directory tempDir = await getApplicationDocumentsDirectory();
      String tempPath = "${tempDir.path}/$correctName.mp3";
      if (downloadLink != null) {
        try {
          indexOfDownloaded = id;
          notifyListeners();
          await dio.download(
            downloadLink,
            tempPath,
            onReceiveProgress: (resieved, total) {
              double threshold = total / 10;
              if (resieved > threshold) {
                downloadProgress = resieved / total;
                threshold += total / 10;
                notifyListeners();
              }
            }
          );
          await mediaStorePlugin.saveFile(
            tempFilePath: tempPath,
            dirType: DirType.audio,
            dirName: DirName.music,
          );

          File disposed = File(tempPath);
          if (await disposed.exists()){
            await disposed.delete();
          }

          downloadProgress = 0;
          showNotification("Файл скачен успешно");
          await scanAudioFiles();
          pause();
        } catch (e) {
          showNotification("Ошибка скачивания");
        }
      }
    }
  }

  // Запускает предпросмотр найденного трека
  Future<void> playFound(String url, String name, int id) async {
    String correctName = name.replaceAll(RegExp(r'[^\p{L}0-9 ().-]', unicode: true), "");
    Response? response;
    Document? trackPage;
    try {
      response = await dio.get(url);
      trackPage = parse(response.data);
    } on Exception {
      try {
        response = await dio.get(
            "http://82.202.136.97:8080/fetch",
            queryParameters: {"target_url": url}
        );
        trackPage = parse(response.data['html']);
      } catch (e) {
        showNotification("Не удалось установить соединение. Проверьте соединение с интернетом или отключите ВПН.");
      }
    }

    if (trackPage == null) return;

    if (response?.statusCode == 200) {
      try {
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
      } catch (e) {
        showNotification("Ошибка скачивания");
      }
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
    currentAudioInfo = {
      "sourceIndex" : ((playerData.get("currentAudioInfo", defaultValue: {}) as Map)["sourceIndex"] as int? ?? 0),
      "position" : ((playerData.get("currentAudioInfo", defaultValue: {}) as Map)["position"] as int? ?? 0),
      "playlist": ((playerData.get("currentAudioInfo", defaultValue: {}) as Map)["playlist"] as String? ?? "main"),
      "order": [for (var id in ((playerData.get("currentAudioInfo", defaultValue: {}) as Map)["order"] as List? ?? [])) id as int],
    };
    order = currentAudioInfo["order"];
    audioPictures = {for (var pictureInfo in (playerData.get("audioPictures", defaultValue: {}) as Map).entries)
      pictureInfo.key as int : pictureInfo.value as String
    };
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

