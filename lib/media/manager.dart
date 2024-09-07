import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'uploader.dart';
import 'dart:convert';
import 'storage.dart';
import 'processor.dart';
import 'seal.dart';
import 'cache.dart' show manifest;
import 'primatives.dart' show opencvInfo, resolveNestedValue;
import 'video.dart' show Thumbnail, Video, VideoMeta, FrameCount;
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
      Expanded(child: SingleChildScrollView(child: Text(backendInfo)));

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
      Function(XFile, DateTime, int, int) onMediaSelected) {
    switch (mediaType) {
      case MediaType.video:
        return selectVideoFromGallery(context, onMediaSelected);
      default:
        throw UnsupportedError('Unsupported media type');
    }
  }

  // Read JSON metadata from the file
  Map<String, dynamic> loadManifest() {
    return manifest.map;
  }

  bool isProcessed(Video video, PreprocessType type, FrameCount frameCount) {
    List<String> pwd = video.pwd.split('/');
    pwd.add("${type.name}-${frameCount.name}");
    return resolveNestedValue(loadManifest(), pwd) != null;
  }

  Future<Video> loadVideo(String pwd, VideoMeta meta,
      [String filename = "video.mp4"]) async {
    XFile cached = await manifest.read(pwd, filename);

    return Video.fromeCache(cached, meta.created, meta.sha256, meta.startFrame,
        meta.endFrame, meta.totalFrames);
  }

  Future<VideoMeta> loadMeta(String pwd,
      [String filename = "meta.json"]) async {
    XFile cached = await manifest.read(pwd, filename);
    return VideoMeta.fromJSON(jsonDecode(await cached.readAsString()));
  }

  Future<Thumbnail> loadThumbnail(String pwd,
      [String filename = "thumbnail.jpg"]) async {
    if (pwd.contains(filename)) {
      pwd = pwd.substring(1, pwd.indexOf(filename) - 1);
    }
    VideoMeta meta = await loadMeta(pwd);
    Video video = await loadVideo(pwd, meta);

    XFile cached = await manifest.read(pwd, filename);
    return Thumbnail.fromBytes(await cached.readAsBytes(), video, 0);
  }

  /// Store the processed video as a CSV file
  ///
  Future<XFileStorage> storeProcessedVideoCSV(
      Video video, PreprocessType type, FrameCount frameCount) async {
    final content = await NormalizedByteArray(type).preprocess(video, frameCount);

    final List<List<int>> bytes = content['bytes'];
    final List<double> normalized = content['normalized'];
    final List<DateTime> timestamps = content['timestamps'];

    // Translate to CSV rows
    ListToCsvConverter csv = const ListToCsvConverter();

    List<List<dynamic>> rows = [
      ['index', 'timestamp', 'normalized', 'byte']
    ];

    for (var i = 0; i < bytes.length; i++) {
      List<dynamic> data = [
        i,
        timestamps[i].toString(),
        normalized[i],
        bytes[i]
      ];
      rows.add(data);
    }

    return manifest.write(csv.convert(rows).codeUnits, video.pwd,
        "${type.name}-${frameCount.name}.csv");
  }

  Future<List<double>> getCachedNormalized(
      Video video, PreprocessType type, FrameCount frameCount) async {
    return manifest
        .read(video.pwd, "${type.name}-${frameCount.name}.csv")
        .then((XFile file) async {
      final String csv = await file.readAsString();
      final List<List<dynamic>> rows = const CsvToListConverter().convert(csv);

      final headers = rows[0];
      final data = rows.sublist(1);

      final dictionaryList = data.map((row) {
        final dictionary = <String, dynamic>{};
        for (var i = 0; i < headers.length; i++) {
          dictionary[headers[i].toString()] = row[i];
        }
        return dictionary;
      }).toList();

      List<dynamic> normalized = dictionaryList.map((row) {
        return row['normalized'];
      }).toList();

      List<String> flatStrings = normalized
          .expand(
              (i) => i.toString().replaceAll(RegExp(r'\[|\]'), '').split(', '))
          .toList();

      List<double> flatDoubles =
          flatStrings.map((i) => double.parse(i)).toList();
      return flatDoubles;
    });
  }
}
