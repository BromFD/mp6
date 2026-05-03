import 'package:logger/logger.dart';

var appLog = Logger(
  output: MultiOutput([
    ConsoleOutput(),
  ]),
  printer: PrettyPrinter(
    methodCount: 0,
    colors: false,
    dateTimeFormat: DateTimeFormat.dateAndTime,
  ),
);