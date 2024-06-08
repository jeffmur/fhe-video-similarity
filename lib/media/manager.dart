import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:io';
import 'uploader.dart';
import 'storage.dart';
import 'processor.dart';
import 'primatives.dart' show Video, Thumbnail, opencvInfo;
import 'package:image_picker/image_picker.dart' show XFile, ImageSource;

// Expose additional classes so caller doesn't have to import them separately
export 'primatives.dart' show Video, Thumbnail;
export 'processor.dart' show PreprocessType;

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
    return storage;
  }

  Future<String> workingDirectory(Video video, DateTime timestamp) async {
    final parentDir = await video.sha256(chars: 8);
    return '$parentDir/${video.startFrame}-${video.endFrame}-${timestamp.millisecondsSinceEpoch}';
  }

  /// Store the metadata for the video
  ///
  Future<XFileStorage> storeVideoMetadata(Video video) async {
    Map stats = video.stats;
    final timestamp = video.created;
    stats['timestamp'] = timestamp.toString();
    // convert stats to Uint8List
    final content = jsonEncode(stats).codeUnits;
    final pwd = await workingDirectory(video, timestamp);
    
    return storeNewMedia(content, pwd, "meta", extension: "json");
  }

  /// Store the thumbnail for the video
  ///
  Future<XFileStorage> storeThumbnail(Thumbnail thumbnail) async {
    final pwd = await workingDirectory(thumbnail.video, thumbnail.video.created);
    final bytes = thumbnail.buffer.toList();
    return storeNewMedia(bytes, pwd, "thumbnail", extension: "jpg");
  }

  /// Preprocess the video
  Map preprocessVideo(Video video, PreprocessType type) {
    return NormalizedByteArray(type).preprocess(video);
  }

  Future<XFileStorage> storeProcessedVideoCSV(Video video, PreprocessType type) async {
    final pwd = await workingDirectory(video, video.created);
    final content = preprocessVideo(video, type);

    final List<List<int>> bytes = content['bytes'];
    final List<List<double>> normalized = content['normalized'];
    final List<DateTime> timestamps = content['timestamps'];

    // Translate to CSV rows
    ListToCsvConverter csv = const ListToCsvConverter();

    List<List<dynamic>> rows = [['index', 'timestamp', 'normalized', 'byte']];

    for (var i = 0; i < bytes.length; i++) {
      List<dynamic> data = [i, timestamps[i].toString(), normalized[i], bytes[i]];
      rows.add(data);
    }

    return storeNewMedia(csv.convert(rows).codeUnits, pwd, type.name, extension: "csv");

  }
  
}
