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
        title: const Text(
          'Log History',
          style: TextStyle(color: Color.fromARGB(255, 0, 172, 252)),
        ),
        backgroundColor:
            const Color.fromARGB(255, 0, 8, 44), // Set AppBar background color
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 0, 172, 252)),
        actions: [
          SizedBox(
            width: 125,
            height: 50,
            child: MultiSelectDialogField<LogLevel>(
              backgroundColor:
                  const Color.fromARGB(255, 0, 8, 44), // Set background color
              title: const Text(
                'Filter by Log Level',
                style: TextStyle(
                    color: Color.fromARGB(
                        255, 0, 172, 252)), // Set title text color
              ),
              buttonText: const Text(
                'Log Level',
                style: TextStyle(
                    color: Color.fromARGB(
                        255, 0, 172, 252)), // Set button text color
              ),
              buttonIcon: const Icon(Icons.menu,
                  color: Color.fromARGB(255, 0, 172, 252)), // Set icon color
              items: LogLevel.values
                  .map((level) => MultiSelectItem<LogLevel>(
                      level, level.name.toUpperCase()))
                  .toList(),
              initialValue: LogLevel.values,
              chipDisplay: MultiSelectChipDisplay.none(),
              onConfirm: (values) {
                setState(() {
                  logLevels = values;
                  _fetchLogHistory();
                });
              },
              selectedColor:
                  const Color.fromARGB(255, 0, 172, 252), // Set selected option color
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(15)),
                border: Border.all(
                  color: const Color.fromARGB(255, 0, 172, 252), // Set border color
                  width: 2,
                ),
              ),
              dialogHeight: 400,
              itemsTextStyle: const TextStyle(
                  color:
                      Color.fromARGB(255, 0, 172, 252)), // Set items text color
              selectedItemsTextStyle: const TextStyle(
                  color: Color.fromARGB(255, 0, 172, 252),
                  fontFamily: 'SourceCodePro',
                  fontWeight: FontWeight.bold), // Set selected items text color
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete,
                color: Color.fromARGB(255, 0, 172, 252)), // Set icon color
            onPressed: _clearLogFile,
            tooltip: 'Clear Log',
          ),
        ],
      ),
      backgroundColor:
          const Color.fromARGB(255, 0, 8, 44), // Set Scaffold background color
      body: _buildLogList(),
      floatingActionButton: ShareFileFloatingActionButton(
        file: Future.value(XFile(Logging().getLogFilePath())),
      ),
    );
  }

  // Build the ListView to display the log history
  Widget _buildLogList() {
    if (_logHistory.isEmpty) {
      return const Center(
        child: Text(
          'No logs available.',
          style: TextStyle(
              color: Color.fromARGB(255, 0, 172, 252)), // Set text color
        ),
      );
    }

    return ListView.builder(
      itemCount: _logHistory.length,
      itemBuilder: (context, index) {
        final log = _logHistory[index];
        final _timestamp = csvHeaders[0];
        final _level = csvHeaders[1];
        final _message = csvHeaders[2];
        final _identifier = csvHeaders[3];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color:
                const Color.fromARGB(255, 8, 0, 44), // Set container background color
            borderRadius: BorderRadius.circular(15), // Circular border
            border: Border.all(
              color: const Color.fromARGB(255, 0, 172, 252), // Border color
              width: 2.0, // Border width
            ),
          ),
          child: ListTile(
            title: log.containsKey(_identifier) && log[_identifier] != ''
                ? Text(
                    '${log[_timestamp]} - ${log[_level]} - ${log[_identifier]}',
                    style: const TextStyle(
                        color: Color.fromARGB(
                            255, 0, 172, 252)), 
                  )
                : Text(
                    '${log[_timestamp]} - ${log[_level]}',
                    style: const TextStyle(
                        color: Color.fromARGB(
                            255, 0, 172, 252)), // Set title text color
                  ),
            subtitle: Text(
              log[_message]!,
              style: const TextStyle(
                  color: Color.fromARGB(
                      255, 0, 172, 252)), // Set subtitle text color
            ),
          ),
        );
      },
    );
  }
}
