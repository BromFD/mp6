import 'dart:ui';
import 'package:chuni_player_revamped/custom_widgets.dart';
import 'package:chuni_player_revamped/ui/mediateka.dart';
import 'package:chuni_player_revamped/ui/playlist.dart';
import 'package:chuni_player_revamped/ui/search&load.dart';
import 'package:chuni_player_revamped/ui/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chuni_player_revamped/provider/provider.dart';
import 'package:chuni_player_revamped/ui/menu.dart';
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
  runApp(ChangeNotifierProvider(
      create: (_) => PlayerProvider(),
      child: Builder(
        builder: (context) {
          final provider = context.watch<PlayerProvider>();
          Color? backgroundColor = provider.colorScheme["background"];
          return MaterialApp(
            navigatorKey: navigatorKey,
            theme: ThemeData(
              pageTransitionsTheme: PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: ZoomPageTransitionsBuilder(backgroundColor: backgroundColor),
                }
              )
            ),
              initialRoute: '/',
              routes: {
                '/': (_) => Menu(),
                '/settings': (_) => Settings(),
                '/mediateka': (_) => Mediateka(),
                '/playlist': (_) => Playlist(),
                '/search&load': (_) => SearchAndLoad(),
              }
          );
        }
      )
    )
  );
}


