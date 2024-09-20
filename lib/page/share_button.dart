import 'dart:io'; // To check platform
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For clipboard
import 'package:share_plus/share_plus.dart';
export 'package:share_plus/share_plus.dart'; // For XFile

class ShareFile extends StatefulWidget {
  final Widget button;
  final String subject;
  final Future<XFile> file; // Future of XFile

  const ShareFile({
    super.key,
    required this.button,
    required this.subject,
    required this.file, // Accept Future<XFile>
  });

  @override
  ShareFileState createState() => ShareFileState();
}

class ShareFileState extends State<ShareFile> {
  XFile? _file;

  void shareFile() {
    if (_file == null) return;

    if (Platform.isAndroid || Platform.isIOS) {
      // Use share_plus package to share the file on Android/iOS
      Share.shareXFiles([_file!], subject: widget.subject);
    } else {
      showClipboardDialog();
    }
  }

  void showClipboardDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.subject),
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
      future: widget.file, // Build the widget with the Future<XFile>
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading indicator or disable the button while waiting
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          // Handle any error that occurred while loading the file
          return IconButton(
            icon: const Icon(Icons.error),
            onPressed: () {},
          );
        } else if (snapshot.hasData) {
          _file = snapshot.data; // Assign the loaded XFile
          return GestureDetector(
            onTap: () {
              shareFile();
            },
            child: widget.button,
          );
        } else {
          // Handle the case where no file is available (null case)
          return const SizedBox.shrink();
        }
      },
    );
  }
}
