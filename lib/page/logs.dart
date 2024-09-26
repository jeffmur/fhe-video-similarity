import 'package:flutter/material.dart';
import 'package:flutter_fhe_video_similarity/page/share_button.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import '../logging.dart'; // Import the logging class

class LoggingPage extends StatefulWidget {
  const LoggingPage({super.key});

  @override
  LoggingPageState createState() => LoggingPageState();
}

class LoggingPageState extends State<LoggingPage> {
  List<Map<String, String>> _logHistory = [];
  List<LogLevel> logLevels = LogLevel.values;

  @override
  void initState() {
    super.initState();
    _fetchLogHistory();
  }

  bool filterByLogLevel(Map<String, String> log) {
    List<String> levels =
        logLevels.map((level) => level.name.toUpperCase()).toList();
    return levels.contains(log['LogLevel']);
  }

  // Fetch the log history from the Logging class
  void _fetchLogHistory() {
    final Logging logger = Logging();
    setState(() {
      _logHistory = logger.readLogHistory(filter: filterByLogLevel);
    });
  }

  // Clear the log file
  void _clearLogFile() {
    final Logging logger = Logging();
    logger.clearLog(); // Call the clear function in Logging class
    setState(() {
      _logHistory.clear(); // Clear the UI list
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log History'),
        actions: [
          SizedBox(
            width: 125,
            height: 50,
            child: MultiSelectDialogField<LogLevel>(
              title: const Text('Filter by Log Level'),
              buttonText: const Text('Log Level'),
              buttonIcon: const Icon(Icons.filter_list),
              items: LogLevel.values
                  .map((level) => MultiSelectItem<LogLevel>(level, level.name.toUpperCase()))
                  .toList(),
              initialValue: LogLevel.values,
              chipDisplay: MultiSelectChipDisplay.none(),
              onConfirm: (values) {
                setState(() {
                  logLevels = values;
                  _fetchLogHistory();
                });
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearLogFile,
            tooltip: 'Clear Log',
          ),
        ],
      ),
      body: _buildLogList(),
      floatingActionButton: ShareFileFloatingActionButton(
        file: Future.value(XFile(Logging().getLogFilePath()))
      ),
    );
  }

  // Build the ListView to display the log history
  Widget _buildLogList() {
    if (_logHistory.isEmpty) {
      return const Center(child: Text('No logs available.'));
    }

    return ListView.builder(
      itemCount: _logHistory.length,
      itemBuilder: (context, index) {
        final log = _logHistory[index];
        final _timestamp = csvHeaders[0];
        final _level = csvHeaders[1];
        final _message = csvHeaders[2];
        final _identifier = csvHeaders[3];
        return ListTile(
          title: log.containsKey(_identifier) && log[_identifier] != ''
              ? Text(
                  '${log[_timestamp]} - ${log[_level]} - ${log[_identifier]}')
              : Text('${log[_timestamp]} - ${log[_level]}'),
          subtitle: Text(log[_message]!),
        );
      },
    );
  }
}
