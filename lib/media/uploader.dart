// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:opencv_dart/opencv_dart.dart';
export 'package:image_picker/image_picker.dart' show ImageSource;
export 'package:file_picker/file_picker.dart' show FileType;

/// Pop up a dialog to select an image from the [ImageSource].
///
Future<XFile> selectImage(ImageSource source) async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: source);
  return image!;
}

Future<XFile> selectVideo(ImageSource source, BuildContext context) async {
  final ImagePicker picker = ImagePicker();

  // Show a customized "Please wait" dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return WillPopScope(
        onWillPop: () async => false, // Prevent dismissal
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.blue.shade700),
              const SizedBox(height: 20),
              const Text(
                "Please wait a moment...",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            
          ),
        ),
      );
    },
  );

  try {
    // Pick the video asynchronously
    final video = await picker.pickVideo(source: source);

    // Handle the case where no video is selected
    if (video == null) {
      throw Exception("No video selected");
    }

    return video;
  } catch (e) {
    print("Error picking video: $e");
    throw Exception("Failed to pick video: $e");
  } finally {
    // Ensure the dialog is dismissed
    Navigator.of(context, rootNavigator: true).pop();
  }
}

/// Pop up a dialog to select a file.
///
Future<XFile> selectFile() async {
  final FilePickerResult? file = await FilePicker.platform.pickFiles();
  final String? path = file?.files.single.path;
  return XFile(path!);
}

Widget selectVideoFromGallery(
    BuildContext context, Function(XFile, DateTime, int, int) onVideoSelected) {
  return SizedBox(
    width: 125,
    height: 56,
    child: FloatingActionButton.extended(
      heroTag: 'selectVideoFromGallery',
      onPressed: () async {
        videoContextDialog(context,
            (DateTime start, int trimStart, int trimEnd) async {
          final XFile video = await selectVideo(ImageSource.gallery, context);
          onVideoSelected(video, start, trimStart, trimEnd);
        });
      },
      tooltip: 'Select video',
      backgroundColor: const Color.fromARGB(255, 0, 172, 252),
      splashColor: Colors.blueAccent,
      icon: const Icon(Icons.video_library,
          size: 20, color: Color.fromARGB(255, 8, 0, 44)),
      label: const Text(
        'Upload Video',
        style: TextStyle(
          color: Color.fromARGB(255, 8, 0, 44),
          fontSize: 14,
        ),
      ),
    ),
  );
}

Widget selectZipFromSystem(
    BuildContext context, Function(XFile) onZipSelected) {
  return SizedBox(
    width: 125,
    height: 56,
    child: FloatingActionButton.extended(
      heroTag: 'selectZipFromSystem',
      onPressed: () async => onZipSelected(await selectFile()),
      tooltip: 'Select zip',
      backgroundColor: const Color.fromARGB(255, 0, 172, 252),
      splashColor: Colors.blueAccent,
      icon: const Icon(Icons.archive,
          size: 20, color: Color.fromARGB(255, 8, 0, 44)),
      label: const Text(
        'Upload Zip',
        style: TextStyle(
          color: Color.fromARGB(255, 8, 0, 44),
          fontSize: 14,
        ),
      ),
    ),
  );
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
      '${dateTime.second.toString().padLeft(2, '0')}Z';
}

/// Prompt the user to add context to the video.
///
Future<void> videoContextDialog(
  BuildContext context,
  // TextEditingController videoStartDateTimeController,
  Function(DateTime startTime, int trimStart, int trimEnd) callback,
) async {
  TextEditingController videoStartDateTimeController = TextEditingController();
  // TextEditingController videoTrimStartController = TextEditingController();
  // TextEditingController videoTrimEndController = TextEditingController();
  DateTime timestamp = DateTime.now().toUtc();
  int trimStart = 0;
  int trimEnd = 0;
  await showDialog(
      context: context,
      builder: (BuildContext context) {
        final formKey = GlobalKey<FormState>();
        return AlertDialog(
            backgroundColor: const Color.fromARGB(255, 0, 8, 44),
            title: const Text('Context for the video', style: TextStyle(color:Color.fromARGB(255, 0, 172, 252))),
            content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: videoStartDateTimeController,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.calendar_today, color: Color.fromARGB(255, 0, 172, 252)),
                        labelText: "YYYY-MM-DDTHH:MM:SSZ",
                        hintText: "UTC Date and Time the video was taken",
                        labelStyle: TextStyle(color: Color.fromARGB(255, 0, 172, 252)), 
                        hintStyle: TextStyle(fontSize: 12, color: Color.fromARGB(255, 0, 172, 252)),
                      ),
                      style: const TextStyle(color: Colors.blue),
                      onSaved: (String? value) =>
                          timestamp = DateTime.parse(value!).toLocal(),
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return 'Required field';
                        }
                        if (DateTime.tryParse(value) == null) {
                          return 'Invalid date format';
                        }
                        return null;
                      },
                    ),
                    ButtonBar(
                      children: <Widget>[
                        TextButton(
                          onPressed: () => videoStartDateTimeController.text =
                              formatDateTime(timestamp),
                          child: const Text('Now', style: TextStyle(color:Color.fromARGB(255, 0, 172, 252))),
                        ),
                        TextButton(
                          onPressed: () => videoStartDateTimeController.text =
                              formatDateTime(
                                  timestamp.subtract(const Duration(hours: 1))),
                          child: const Text('Last Hour', style: TextStyle(color:Color.fromARGB(255, 0, 172, 252))),
                        ),
                        TextButton(
                          onPressed: () => videoStartDateTimeController.text =
                              formatDateTime(
                                  timestamp.subtract(const Duration(days: 1))),
                          child: const Text('Yesterday', style: TextStyle(color:Color.fromARGB(255, 0, 172, 252))),
                        ),
                      ],
                    ),
                    TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.cut_outlined, color: Color.fromARGB(255, 0, 172, 252)),
                        hintText: "Duration in seconds (optional)",
                        labelText: "Trim the first N seconds of video",
                        labelStyle: TextStyle(color: Color.fromARGB(255, 0, 172, 252), fontSize: 12),
                        hintStyle: TextStyle(color: Color.fromARGB(255, 0, 172, 252), fontSize: 10), 
                      ),
                      style: const TextStyle(color: Colors.blue),
                      onSaved: (String? value) {
                        if (value != null && value.isNotEmpty) {
                          trimStart = int.parse(value);
                        }
                      },
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return null;
                        }
                        try {
                          int.parse(value);
                          return null;
                        } catch (e) {
                          return 'Invalid number';
                        }
                      },
                    ),
                    TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.cut_outlined, color: Color.fromARGB(255, 0, 172, 252)),
                        hintText: "Duration in seconds (optional)",
                        labelText: "Trim the last N seconds of video",
                        labelStyle: TextStyle(color: Color.fromARGB(255, 0, 172, 252), fontSize: 12),
                        hintStyle: TextStyle(color: Color.fromARGB(255, 0, 172, 252), fontSize: 10), 
                      ),
                      style: const TextStyle(color: Colors.blue),
                      onSaved: (String? value) {
                        if (value != null && value.isNotEmpty) {
                          trimEnd = int.parse(value);
                        }
                      },
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return null;
                        }
                        try {
                          int.parse(value);
                          return null;
                        } catch (e) {
                          return 'Invalid number';
                        }
                      },
                    ),
                    ButtonBar(
                      children: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel', style: TextStyle(color: Color.fromARGB(255, 0, 172, 252))),
                        ),
                        TextButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              formKey.currentState!.save();
                              Navigator.of(context).pop();
                              callback(timestamp, trimStart, trimEnd);
                            }
                          },
                          child: const Text('OK', style: TextStyle(color: Color.fromARGB(255, 0, 172, 252))),
                        ),
                      ],
                    )
                  ],
                )));
      });
}
