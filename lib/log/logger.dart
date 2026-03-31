import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:chuni_player_revamped/custom_widgets.dart';

class FileLogs extends LogOutput {
  File? file;
  List<String> logList = [];

  @override
  Future<void> init() async {
    super.init();
    final logDir = await getApplicationDocumentsDirectory();
    final directory = Directory(logDir.path);
    if (await directory.exists()) {
      await directory.create(recursive: true);
    }

    file = File("${logDir.path}/log.txt");
    try {
      if (logList.isNotEmpty) {
        final logLine = logList.join();
        await file!.writeAsString(logLine, mode: FileMode.append, flush: true,);
        logList = [];
      }
    } catch (e) {
      showNotification("Ошибка сохранения лог файла: ${e.toString()}");
    }
  }

  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      print(line);
    }
    try {
      final logLine = "${DateTime.now()} : ${event.lines.join('\n')}\n'";
      if (file != null) {
        file!.writeAsStringSync(logLine, mode: FileMode.append, flush: true,);
      } else {
        logList.add(logLine);
      }
    } catch(e) {
      showNotification("Ошибка сохранения лог файла: ${e.toString()}");
    }
  }
}

var appLog = Logger(
  output: MultiOutput([
    FileLogs(),
    ConsoleOutput(),
  ]),
  printer: PrettyPrinter(
    methodCount: 0,
    colors: false,
    dateTimeFormat: DateTimeFormat.dateAndTime,
  ),
);