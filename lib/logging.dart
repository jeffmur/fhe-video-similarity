import 'dart:io';
import 'package:path/path.dart';

/// Print [Duration] in seconds, milliseconds or microseconds.
///
String nonZeroDuration(Duration duration) {
  if (duration >= const Duration(milliseconds: 1000)) {
    return '${duration.inSeconds}s';
  } else if (duration >= const Duration(milliseconds: 1)) {
    return '${duration.inMilliseconds}ms';
  } else {
    return '${duration.inMicroseconds}µs';
  }
}

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

String csvDelimiter = ';';
List<String> csvHeaders = ['Timestamp', 'LogLevel', 'Message', 'CorrelationId'];

enum LogLevel { info, metric, debug, warning, error }

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
      _logFile.writeAsStringSync('${csvHeaders.join(csvDelimiter)}\n',
          mode: FileMode.write); // CSV header
    }
  }

  factory Logging() {
    return _instance;
  }

  // Synchronous log writing
  void log(LogLevel level, String message, {String? correlationId}) {
    final String timestamp = _getFormattedTimestamp();
    final String logLevel = _getLogLevelString(level);
    final String identifier = correlationId ?? '';

    // Write to file in append mode
    final String logEntry =
        '${[timestamp, logLevel, message, identifier].join(csvDelimiter)}\n';
    _logFile.writeAsStringSync(logEntry, mode: FileMode.append, flush: true);
  }

  void metric(String message, {String? correlationId}) {
    log(LogLevel.metric, message, correlationId: correlationId);
  }

  void info(String message, {String? correlationId}) {
    log(LogLevel.info, message, correlationId: correlationId);
  }

  void debug(String message, {String? correlationId}) {
    log(LogLevel.debug, message, correlationId: correlationId);
  }

  void warning(String message, {String? correlationId}) {
    log(LogLevel.warning, message, correlationId: correlationId);
  }

  void error(String message, {String? correlationId}) {
    log(LogLevel.error, message, correlationId: correlationId);
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
    _logFile.writeAsStringSync('${csvHeaders.join(csvDelimiter)}\n',
        mode: FileMode.write); // CSV header
  }

  String getLogFilePath() {
    return _logFile.path;
  }

  /// Read full log history from the CSV file
  ///
  /// Optionally, you can pass a [filter] function to filter the log entries.
  ///
  List<Map<String, String>> readLogHistory(
      {bool Function(Map<String, String>)? filter}) {
    final List<Map<String, String>> logHistory = [];
    final List<String> lines = _logFile.readAsLinesSync();

    for (int i = 1; i < lines.length; i++) {
      final List<String> values = lines[i].split(csvDelimiter);
      final Map<String, String> logEntry = {
        'Timestamp': values[0],
        'LogLevel': values[1],
        'Message': values[2],
        'CorrelationId': values[3],
      };

      if (filter == null || filter(logEntry)) {
        logHistory.add(logEntry);
      }
    }

    return logHistory;
  }
}
