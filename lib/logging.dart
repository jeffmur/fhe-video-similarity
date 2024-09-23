import 'dart:io';
import 'package:path/path.dart';

/// Format a [DateTime] object as a string.
///
/// Format the [DateTime] object as a string in the format 'YYYY-MM-DDTHH:MM:SSZ'.
///
String formatDateTime(DateTime dateTime) {
  return '${(dateTime.year).toString().padLeft(4, '0')}-'
      '${dateTime.month.toString().padLeft(2, '0')}-'
      '${dateTime.day.toString().padLeft(2, '0')}T'
      '${dateTime.hour.toString().padLeft(2, '0')}:'
      '${dateTime.minute.toString().padLeft(2, '0')}:'
      '${dateTime.second.toString().padLeft(2, '0')}.'
      '${dateTime.millisecond.toString().padLeft(3, '0')}Z';
}

enum LogLevel { metric, info, debug, warning, error }

class Logging {
  static final Logging _instance = Logging._internal();
  late final File _logFile;
  static const String _fileName = 'ghost_peer_share_log.csv';

  // Singleton Constructor
  Logging._internal() {
    final String directoryPath = Directory.systemTemp.path;
    _logFile = File(join(directoryPath, _fileName));

    // Initialize the log file with headers if not present
    if (!_logFile.existsSync()) {
      _logFile.createSync();
      _logFile.writeAsStringSync('Timestamp,Level,Message\n',
          mode: FileMode.write); // CSV header
    }
  }

  factory Logging() {
    return _instance;
  }

  // Synchronous log writing
  void log(LogLevel level, String message) {
    final String timestamp = _getFormattedTimestamp();
    final String logLevel = _getLogLevelString(level);

    // Write to file in append mode
    final String logEntry = '$timestamp,$logLevel,$message\n';
    _logFile.writeAsStringSync(logEntry, mode: FileMode.append, flush: true);
  }

  void metric(String message) {
    log(LogLevel.metric, message);
  }

  void info(String message) {
    log(LogLevel.info, message);
  }

  void debug(String message) {
    log(LogLevel.debug, message);
  }

  void warning(String message) {
    log(LogLevel.warning, message);
  }

  void error(String message) {
    log(LogLevel.error, message);
  }

  // Helper to format the current timestamp
  String _getFormattedTimestamp() {
    final DateTime now = DateTime.now();
    return formatDateTime(now);
  }

  // Convert LogLevel enum to string
  String _getLogLevelString(LogLevel level) {
    switch (level) {
      case LogLevel.metric:
        return 'METRIC';
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.warning:
        return 'WARNING';
      case LogLevel.error:
        return 'ERROR';
      default:
        return 'INFO';
    }
  }

  void clearLog() {
    _logFile.writeAsStringSync('Timestamp,Level,Message\n',
        mode: FileMode.write); // CSV header
  }

  String getLogFilePath() {
    return _logFile.path;
  }

  // Read full log history from the CSV file
  List<Map<String, String>> readLogHistory() {
    if (!_logFile.existsSync()) {
      return [];
    }

    final List<Map<String, String>> logHistory = [];
    final List<String> lines = _logFile.readAsLinesSync();

    // Skip the first line (CSV header)
    for (int i = 1; i < lines.length; i++) {
      final List<String> fields = lines[i].split(',');

      if (fields.length == 3) {
        logHistory.add({
          'timestamp': fields[0],
          'level': fields[1],
          'message': fields[2],
        });
      }
    }

    return logHistory;
  }
}
