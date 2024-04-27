import 'package:flutter/material.dart';
import 'dart:io';
import 'uploader.dart';
import 'storage.dart';
import 'processor.dart';
import 'primatives.dart' show Video, opencvInfo;
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
    Function(XFile, DateTime, int, int) onMediaSelected
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
    final sha = await sha256ofFileAsString(video.path, 8);
    final ext = video.path.split('.').last;
    return storeMediaFromXFile(sha, 'raw.$ext', video);
  }

  /// Cache the media file nested the parent key
  ///
  Future<XFileStorage> storeMediaFromXFile(String parentDirectory, String filename, XFile media) async {
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

  Future<XFileStorage> storeNewMedia(List<int> bytes, String parentDirectory, String filename, {String extension="txt"}) async {

    XFileStorage storage = XFileStorage.fromBytes(parentDirectory, "$filename.$extension", bytes);

    await storage.write();

    print('Wrote new media at: $parentDirectory/$filename');

    return storage;
  }

  /// Store the metadata for the video
  ///
  Future<XFileStorage> storeVideoMetadata(Video video, DateTime timestamp) async {
    Map stats = video.stats;
    stats['timestamp'] = timestamp.toString();
    // convert stats to Uint8List
    final content = stats.toString().codeUnits;

    final parentDir = await video.sha256(chars: 8);
    final filename = '${video.startFrame}-${video.endFrame}-${timestamp.millisecondsSinceEpoch}';
    
    return storeNewMedia(content, parentDir, filename, extension: "meta");
  }
  
}
