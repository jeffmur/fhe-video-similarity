// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

export 'package:image_picker/image_picker.dart' show ImageSource;
export 'package:file_picker/file_picker.dart' show FileType;

/// Pop up a dialog to select an image from the [ImageSource].
///
Future<XFile> selectImage(ImageSource source) async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: source);
  return image!;
}

/// Pop up a dialog to select a video from the [ImageSource].
///
Future<XFile> selectVideo(ImageSource source) async {
  final ImagePicker picker = ImagePicker();
  final XFile? video = await picker.pickVideo(source: source);
  return video!;
}

/// Pop up a dialog to select a file.
///
Future<XFile> selectFile() async {
  final FilePickerResult? file = await FilePicker.platform.pickFiles();
  final String? path = file?.files.single.path;
  return XFile(path!);
}

/// A floating action button to select an image.
///
FloatingActionButton selectVideoFromGallery(
    BuildContext context, Function(XFile, DateTime, int, int) onVideoSelected) {
  return FloatingActionButton(
    heroTag: 'selectVideoFromGallery',
    onPressed: () async {
      videoContextDialog(context,
          (DateTime start, int trimStart, int trimEnd) async {
        final XFile video = await selectVideo(ImageSource.gallery);

        onVideoSelected(video, start, trimStart, trimEnd);
      });
    },
    tooltip: 'Select video',
    child: const Icon(Icons.image),
  );
}

/// A floating action button to select a zip file.
///
FloatingActionButton selectZipFromSystem(
    BuildContext context, Function(XFile) onZipSelected) {
  return FloatingActionButton(
    heroTag: 'selectZipFromSystem',
    onPressed: () async => onZipSelected(await selectFile()),
    tooltip: 'Select zip',
    child: const Icon(Icons.archive),
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
            title: const Text('Context for the video'),
            content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextFormField(
                      controller: videoStartDateTimeController,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.calendar_today),
                        labelText: "YYYY-MM-DDTHH:MM:SSZ",
                        hintText: "UTC Date and Time the video was taken",
                      ),
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
                          child: const Text('Now'),
                        ),
                        TextButton(
                          onPressed: () => videoStartDateTimeController.text =
                              formatDateTime(
                                  timestamp.subtract(const Duration(hours: 1))),
                          child: const Text('Last Hour'),
                        ),
                        TextButton(
                          onPressed: () => videoStartDateTimeController.text =
                              formatDateTime(
                                  timestamp.subtract(const Duration(days: 1))),
                          child: const Text('Yesterday'),
                        ),
                      ],
                    ),
                    TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.start),
                        hintText: "Duration in seconds",
                        labelText: "Trim the first N seconds of the video",
                      ),
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
                        icon: Icon(Icons.stop),
                        hintText: "Duration in seconds",
                        labelText: "Trim the last N seconds of the video",
                      ),
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
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              formKey.currentState!.save();
                              Navigator.of(context).pop();
                              callback(timestamp, trimStart, trimEnd);
                            }
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    )
                  ],
                )));
      });
}
