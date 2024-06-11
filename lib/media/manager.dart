import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'uploader.dart';
import 'storage.dart';
import 'processor.dart';
import 'cache.dart' show manifest;
import 'primatives.dart' show opencvInfo;
import 'video.dart' show Video;
import 'package:image_picker/image_picker.dart' show XFile, ImageSource;

// Expose additional classes so caller doesn't have to import them separately
export 'video.dart' show Video, Thumbnail;
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

  // Future<Thumbnail> loadThumbnail(Video video) async {
  //   final pwd = await workingDirectory(video, video.created);
  //   final bytes = await manifest.read(pwd, "thumbnail.jpg");
  //   return Thumbnail.fromBytes(video, bytes);
  // }

  /// Store the processed video as a CSV file
  ///
  Future<XFileStorage> storeProcessedVideoCSV(Video video, PreprocessType type) {
    final content = NormalizedByteArray(type).preprocess(video);

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

    return manifest.write(csv.convert(rows).codeUnits, video.pwd, "${type.name}.csv");

  }
  
}
