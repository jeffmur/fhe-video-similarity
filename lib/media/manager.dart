import 'package:flutter/material.dart';
import 'dart:io';

import 'uploader.dart';
import 'storage.dart';
import 'processor.dart';
import 'primatives.dart' show opencvInfo;
import 'package:image_picker/image_picker.dart' show XFile, ImageSource;

// Expose additional classes so caller doesn't have to import them separately
export 'primatives.dart' show Video, Thumbnail;

enum MediaType { video }

/// Singleton class to manage all the media related operations
/// 
class Manager {
  static final Manager _instance = Manager._internal();

  /// Get the only instance of the manager
  factory Manager() {
    return _instance;
  }

  /// Initialize the manager
  Manager._internal();

  /// Backend library build information
  String get backendInfo => opencvInfo;

  /// Widget to display the backend library information
  Widget get backendInfoWidget =>
    Expanded(
      child: SingleChildScrollView(
        child: Text(backendInfo)));

  /// Upload media from the gallery
  ///
  Future<XFile> xFileFromGallery(MediaType source) async {
    switch (source) {
      case MediaType.video:
        return selectVideo(ImageSource.gallery);
      default:
        throw UnsupportedError('Unsupported media type');
    }
  }

  /// Select media from the gallery
  ///
  FloatingActionButton floatingSelectMediaFromGallery(
    MediaType mediaType,
    BuildContext context,
    Function(XFile) onMediaSelected
  ) {
    switch (mediaType) {
      case MediaType.video:
        return selectVideoFromGallery(context, onMediaSelected);
      default:
        throw UnsupportedError('Unsupported media type');
    }
  }

  /// Store the video file
  /// 
  /// Store the video file in the application directory, and compute the SHA-256 hash of the file.
  /// The first 8 characters of the hash are used as the parent directory.
  ///
  Future<XFileStorage> storeVideo(XFile video) async {
    final sha256 = await sha256ofFile(video.path);
    // First 8 characters of the SHA-256 hash
    final sha = sha256.toString().substring(0, 8);
    return storeMedia(sha, 'raw', video);
  }

  /// Cache the media file nested the parent key
  ///
  Future<XFileStorage> storeMedia(String parentDirectory, String filename, XFile media) async {
    final stored = XFileStorage(parentDirectory, filename, media);

    // Check if the media is already stored
    if (await stored.exists()) {
      print('Media already stored at: ${await stored.path}');
      return stored;
    }
    File atRest = await stored.write();
    DateTime lastAccessed = await media.lastModified();
    atRest.setLastAccessedSync(lastAccessed);

    print('Stored media at: ${atRest.path}');
    return stored;
  }
  
}
