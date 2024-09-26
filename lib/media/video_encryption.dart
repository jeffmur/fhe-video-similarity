import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_fhe_video_similarity/logging.dart';
import 'package:flutter_fhe_video_similarity/media/primatives.dart';
import 'package:flutter_fhe_video_similarity/media/storage.dart';
import 'package:opencv_dart/opencv_dart.dart';

import 'image.dart';
import 'package:flutter/material.dart' as mat;
import 'package:flutter_fhe_video_similarity/media/cache.dart';

import 'seal.dart';
import 'video.dart';
export 'dart:io' show File;

List<Ciphertext> encryptVideoFrames(Session session, List<double> frames) {
  return session.encryptVecDouble(frames);
}

List<Ciphertext> ciphertextFromFiles(List<File> file, Afhe fhe) {
  return file
      .map((f) => Ciphertext.fromBytes(fhe, f.readAsBytesSync()))
      .toList();
}

List<File> filesFromSimilarityType(List<File> files, String type) {
  return files.where((f) => f.path.contains('/$type/')).toList();
}

class CiphertextVideo extends UploadedMedia implements Video {
  // Breakdown by similarity
  late List<Ciphertext> kld;
  late List<Ciphertext> kldLog;
  late List<Ciphertext> bhattacharyya;
  late List<Ciphertext> cramer;

  @override
  final VideoMeta meta;

  @override
  late VideoCapture video;

  @override
  late int startFrame;

  @override
  late int endFrame;

  @override
  late int totalFrames;

  @override
  late String hash;

  void init() {
    video = VideoCapture.empty();
    startFrame = meta.startFrame;
    endFrame = meta.endFrame;
    totalFrames = meta.totalFrames;
    hash = meta.sha256;
  }

  CiphertextVideo({required this.meta})
      : super(XFile('${meta.path}/meta.json'), meta.created) {
    init();
  }

  /// We require a library pointer to import the [Ciphertext], I plan to update this later, as it is confusing
  /// to require the object rather than the library selection (seal)
  CiphertextVideo.fromBinaryFiles(
      List<File> binFiles, Session session, this.meta)
      : kld = ciphertextFromFiles(
            filesFromSimilarityType(binFiles, 'kld'), session.seal),
        kldLog = ciphertextFromFiles(
            filesFromSimilarityType(binFiles, 'kld_log'), session.seal),
        bhattacharyya = ciphertextFromFiles(
            filesFromSimilarityType(binFiles, 'bhattacharyya'), session.seal),
        cramer = ciphertextFromFiles(
            filesFromSimilarityType(binFiles, 'cramer'), session.seal),
        super(XFile('${meta.path}/meta.json'), meta.created) {
    init();
  }

  @override
  get stats => meta;

  @override
  Duration get duration =>
      Duration(milliseconds: ((endFrame - startFrame) / fps * 1000).round());

  @override
  get fps => meta.fps;

  @override
  Future<void> cache() async {} // [ctFrames] are already cached

  @override
  int get frameCount => meta.totalFrames;

  @override
  String get pwd => meta.path;

  @override
  void trim(Duration start, Duration end) {
    const segmentDuration = Duration(seconds: 1); // Assuming 1-second segments

    // Calculate start index based on the start time
    int startIdx = (start.inSeconds / segmentDuration.inSeconds).floor();

    // Update startFrame based on start index
    startFrame = fps * startIdx;

    // Calculate end index based on the end time
    int? endIdx = (end == Duration.zero)
        ? null
        : (duration.inSeconds -
            (end.inSeconds / segmentDuration.inSeconds).floor());

    // If endIdx is not null, update endFrame based on end index
    if (endIdx != null) {
      endFrame = fps * endIdx;
    }

    // Debug log for trimming
    Logging().debug(
        'Trimming CiphertextVideo List<Ciphertext> from $startIdx to $endIdx');

    kld = kld.sublist(startIdx, endIdx);
    kldLog = kldLog.sublist(startIdx, endIdx);
    bhattacharyya = bhattacharyya.sublist(startIdx, endIdx);
    cramer = cramer.sublist(startIdx, endIdx);
  }

  @override
  Future<Image> thumbnail(String filename, [frameIdx = 0]) async {
    return Image.fromBytes(Uint8List(0), DateTime.now(), meta.path, filename);
  }

  @override
  Future<List<Uint8List>> probeFrames(
      {List<int> frameIds = const [0], String frameFormat = 'png'}) async {
    throw UnsupportedError('CiphertextVideo does not support frames');
  }

  @override
  Future<List<int>> probeFrameSizes(
      {List<int> frameIds = const [0], String frameFormat = 'png'}) async {
    throw UnsupportedError('CiphertextVideo does not support frames');
  }

  @override
  Future<Uint8List> get asBytes async {
    throw UnsupportedError('CiphertextVideo does not support asBytes');
  }
}

class CiphertextThumbnail implements Thumbnail {
  @override
  bool isCached = false;
  @override
  int frameIdx = 0;
  @override
  String filename = 'thumbnail.jpg';
  @override
  Video video;

  final VideoMeta meta;

  CiphertextThumbnail({required this.video, required this.meta});

  Uint8List get bytes => Uint8List(1);

  @override
  // Generate a black thumbnail, as tmp
  Future<Image> get image => Future.value(video.thumbnail(filename));

  @override
  Future<Uint8List> get cachedBytes => Future.value(bytes);

  @override
  Future<void> cache() async {
    await manifest.write(bytes, meta.path, filename);
    isCached = true;
  }

  @override
  Future<mat.Widget> get widget async => mat.Image.memory(bytes);
}
