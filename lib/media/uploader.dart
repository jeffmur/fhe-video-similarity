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
  return FloatingActionButton(
    onPressed: () async {
      final XFile video = await selectVideo(ImageSource.gallery);
      print('Selected video: ${video.path}');
      onVideoSelected(video);
    },
    tooltip: 'Select video',
    child: const Icon(Icons.image),
  );
}
