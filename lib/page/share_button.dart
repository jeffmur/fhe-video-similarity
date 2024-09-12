import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For clipboard
import 'package:share_plus/share_plus.dart';
import 'dart:io'; // To check platform

class ShareString extends StatefulWidget {
  final String subject;
  final String text;
  const ShareString({super.key, required this.subject, required this.text});

  @override
  ShareStringState createState() => ShareStringState();
}

class ShareStringState extends State<ShareString> {
  void shareBase64String() {
    if (Platform.isAndroid) {
      // Use share_plus package to share on Android
      Share.share(widget.text, subject: widget.subject);
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
                const Text('Copy the following string:'),
                const SizedBox(height: 10),
                SelectableText(widget.text, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard!')),
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
      onPressed: shareBase64String,
    );
  }
}
