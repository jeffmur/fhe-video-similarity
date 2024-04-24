// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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

/// A floating action button to select an image.
/// 
FloatingActionButton selectVideoFromGallery(
  BuildContext context,
  Function(XFile) onVideoSelected
) {
  TextEditingController videoStartDateTimeController = TextEditingController();
  return FloatingActionButton(
    onPressed: () async {
      videoContextDialog(context, videoStartDateTimeController,
      () async {
        final XFile video = await selectVideo(ImageSource.gallery);
        print('Selected video: ${video.path}');
        print('Start DateTime: ${videoStartDateTimeController.text}');
        onVideoSelected(video);
      });
    },
    tooltip: 'Select video',
    child: const Icon(Icons.image),
  );
}


class SelectDate extends StatefulWidget {
  const SelectDate({super.key, required this.title});

  final String title;

  @override
  State<SelectDate> createState() => _SelectDate();
}

class _SelectDate extends State<SelectDate> {
  DateTime selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
    );
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
         '${dateTime.second.toString().padLeft(2, '0')}Z';


  //return '${dateTime.year}-${dateTime.month}-${dateTime.day}T${dateTime.hour}:${dateTime.minute}:${dateTime.second}Z';
}

/// Prompt the user to add context to the video.
/// 
Future<void> videoContextDialog(
  BuildContext context,
  TextEditingController videoStartDateTimeController,
  Function() callback,
) async {
  await
  showDialog(context: context,
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
                  hintText: "Enter the date and time the video was taken",
                ),
                onSaved: (String? value) {
                  // This optional block of code can be used to run
                  // code when the user saves the form.
                },
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
                    onPressed: () => videoStartDateTimeController.text = formatDateTime(DateTime.now()),
                    child: const Text('Today'),
                  ),
                  TextButton(
                    onPressed: () => videoStartDateTimeController.text = formatDateTime(DateTime.now().subtract(const Duration(days: 1))),
                    child: const Text('Yesterday'),
                  ),
                ],
              ),
              // const TextField(
              //   // controller: qualityController,
              //   keyboardType: TextInputType.number,
              //   decoration: InputDecoration(
              //       hintText: 'Enter quality if desired'),
              // ),
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
                      if(formKey.currentState!.validate()) {
                        formKey.currentState!.save();
                        Navigator.of(context).pop();
                        callback();
                      }
                    },
                    child: const Text('OK'),
                  ),
                ],
              )
            ],
          )
        )
      );
    }
  );
}
