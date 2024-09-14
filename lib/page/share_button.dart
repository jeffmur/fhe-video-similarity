import 'dart:io'; // To check platform
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For clipboard
import 'package:share_plus/share_plus.dart';
export 'package:share_plus/share_plus.dart'; // For XFile

class ShareFile extends StatefulWidget {
  final String subject;
  final XFile file;

  const ShareFile({super.key, required this.subject, required this.file});

  @override
  ShareFileState createState() => ShareFileState();
}

class ShareFileState extends State<ShareFile> {
  void shareFile() {
    if (Platform.isAndroid || Platform.isIOS) {
      // Use share_plus package to share the file on Android/iOS
      Share.shareXFiles([widget.file], subject: widget.subject);
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
                SelectableText(widget.file.path, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.file.path));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File path copied to clipboard!')),
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
    return IconButton(
      icon: const Icon(Icons.share),
      onPressed: shareFile,
    );
  }
}
