import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart'; // Clipboard

export 'package:cross_file/cross_file.dart' show XFile;

class ShareFileTrigger extends StatefulWidget {
  final Future<XFile> file;
  final Widget Function(VoidCallback)
      builder; // Builder for any button or widget with onPressed

  const ShareFileTrigger({
    super.key,
    required this.file,
    required this.builder,
  });

  @override
  _ShareFileTriggerState createState() => _ShareFileTriggerState();
}

class _ShareFileTriggerState extends State<ShareFileTrigger> {
  XFile? _file;

  Future<void> shareFile() async {
    if (_file == null) return;

    if (Platform.isAndroid || Platform.isIOS) {
      Share.shareXFiles([_file!]);
    } else {
      showClipboardDialog();
    }
  }

  void showClipboardDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Copy the file path to clipboard:'),
                const SizedBox(height: 10),
                SelectableText(_file?.path ?? '',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _file?.path ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('File path copied to clipboard!')),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Copy to Clipboard'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<XFile>(
      future: widget.file,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          print(snapshot.error);
          return IconButton(
            icon: const Icon(Icons.error),
            onPressed: () {},
          );
        } else if (snapshot.hasData) {
          _file = snapshot.data; // Store the loaded file
          return widget.builder(() {
            shareFile(); // Pass shareFile as onPressed to the widget
          });
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}

class ShareFileElevatedButton extends StatelessWidget {
  final Future<XFile> file;
  final Widget child;

  const ShareFileElevatedButton(
      {super.key, required this.file, required this.child});

  @override
  Widget build(BuildContext context) {
    return ShareFileTrigger(
      file: file,
      builder: (onPressed) {
        return ElevatedButton(onPressed: onPressed, child: child);
      },
    );
  }
}

class ShareFileFloatingActionButton extends StatelessWidget {
  final Future<XFile> file;

  const ShareFileFloatingActionButton({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return ShareFileTrigger(
      file: file,
      builder: (onPressed) {
        return FloatingActionButton(
          onPressed: onPressed,
          child: const Icon(Icons.share),
        );
      },
    );
  }
}
