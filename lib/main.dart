import 'dart:ui';
import 'package:chuni_player_revamped/custom_widgets.dart';
import 'package:chuni_player_revamped/ui/equalizer.dart';
import 'package:chuni_player_revamped/ui/mediateka.dart';
import 'package:chuni_player_revamped/ui/playlist.dart';
import 'package:chuni_player_revamped/ui/search&load.dart';
import 'package:chuni_player_revamped/ui/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chuni_player_revamped/provider/provider.dart';
import 'package:chuni_player_revamped/ui/menu(obsolete).dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:logger/logger.dart';
import 'package:chuni_player_revamped/log/logger.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  MetadataGod.initialize(); // Библиотека для вытаскивания метаданных из аудио файлов
  await Hive.initFlutter(); // Библиотека для хранения данных между перезапусками
  await Hive.openBox('playerData');
  final playerProvider = PlayerProvider();

  // Для перехвата всех ошибок
  FlutterError.onError = (details) {
    appLog.e("FLUTTER ERROR", error: details.exception, stackTrace: details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    appLog.e("DART ASYNC ERROR", error: error, stackTrace: stack);
    return true;
  };
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  runApp(ChangeNotifierProvider.value(
      value: playerProvider,
      child: MyApp(),
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Colors.transparent;
    return MaterialApp(
        navigatorKey: navigatorKey,
        theme: ThemeData(
            pageTransitionsTheme: PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: ZoomPageTransitionsBuilder(
                      backgroundColor: backgroundColor
                  ),
                }
            )
        ),
        initialRoute: '/',
        routes: {
          '/': (_) => Mediateka(),
          '/settings': (_) => Settings(),
          '/playlist': (_) => Playlist(),
          '/search&load': (_) => SearchAndLoad(),
          '/equalizer': (_) => Equalizer(),
        }
    );
  }
}

