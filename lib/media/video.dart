import 'dart:convert';

import 'package:flutter/material.dart' as mat;
import 'package:flutter_fhe_video_similarity/logging.dart';
import 'package:flutter_fhe_video_similarity/media/cache.dart';
import 'package:flutter_fhe_video_similarity/media/storage.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:flutter/foundation.dart';

import 'processor.dart';
import 'image.dart';

export 'package:flutter_fhe_video_similarity/media/video_opencv.dart';
export 'package:flutter_fhe_video_similarity/media/video_meta.dart';

class Video extends UploadedMedia {
  // Logger log = Logger('Video');
  int startFrame = 0;

  late int endFrame;
  late int totalFrames;
  late cv.VideoCapture video;
  late String hash;

  Video(XFile file, DateTime timestamp,
      {Duration start = Duration.zero, Duration end = Duration.zero})
      : super(file, timestamp) {
    video = cv.VideoCapture.fromFile(file.path, apiPreference: cvApiPreference);
    created = timestamp;

    // Get frame count
    totalFrames = frameCount(file.path);

    // Calculate the number of 'extra' frames exceeding the absolute second
    var extraFrames = (totalFrames % fps).toInt();

    // Set the end frame (used for trimming)
    endFrame = totalFrames - extraFrames;

    // Set the start and end positions, based on user input
    trim(start, end);

    // Calculate the hash
    hash = sha256ofBytes(video.read().$2.data, 8);
  }

  Video.fromeCache(XFile file, DateTime timestamp, this.hash, this.startFrame,
      this.endFrame, this.totalFrames)
      : super(file, timestamp) {
    video = cv.VideoCapture.fromFile(file.path, apiPreference: cvApiPreference);
    created = timestamp;
  }

  VideoMeta get stats => VideoMeta(
      codec: video.codec,
      fps: video.get(cv.CAP_PROP_FPS).toInt(),
      totalFrames: totalFrames,
      duration: duration,
      sha256: hash,
      startFrame: startFrame,
      endFrame: endFrame,
      name: xfile.name,
      extension: xfile.path.split('.').last,
      created: created,
      modified: lastModified,
      encryptionStatus: 'plain',
      path: xfile.path);

  // Future<String> sha256({chars=8}) async => await sha256ofFileAsString(xfile.path, chars);

  String get pwd =>
      '$hash/$startFrame-$endFrame-${created.millisecondsSinceEpoch}';

  Future<void> cache() async {
    final bytes = await asBytes;
    manifest.write(bytes.toList(), pwd, "video.mp4");

    final List<int> metaBytes = utf8.encode(jsonEncode(stats.toJson())).toList();
    manifest.write(metaBytes, pwd, "meta.json");
  }

  int get fps => video.get(cv.CAP_PROP_FPS).toInt();
  Duration get duration =>
      Duration(milliseconds: ((endFrame - startFrame) / fps * 1000).round());

  /// Trim the video to match the duration of another video
  ///
  /// [fromStart] trims from the beginning
  /// [fromEnd] trims from the end
  void trim(Duration fromStart, Duration fromEnd) {
    final log = Logging();

    // Convert trim durations to frame numbers based on fps
    int trimStartFrames = fromStart.inSeconds * fps;
    int trimEndFrames = fromEnd.inSeconds * fps;
    int totalFrames = duration.inSeconds * fps;

    // Ensure trimming doesn't exceed bounds
    if (trimStartFrames + trimEndFrames > totalFrames) {
      throw ArgumentError('Trim range exceeds total video frames');
    }

    // Apply trimming from the start
    if (trimStartFrames > 0) {
      log.debug("Trimming $trimStartFrames frames from the start "
          "($startFrame => ${startFrame + trimStartFrames})");
      startFrame = startFrame + trimStartFrames;
    }

    // Apply trimming from the end
    if (trimEndFrames > 0) {
      log.debug("Trimming $trimEndFrames frames from the end "
          "($endFrame => ${endFrame - trimEndFrames})");
      endFrame = endFrame - trimEndFrames;
    }

    log.debug(
        "Final frame range after trimming: startFrame=$startFrame, endFrame=$endFrame");
  }

  /// Generate an [Image] from the video
  ///
  /// A thumbnail is generated from the frame at [frameIdx] of the video.
  ///
  Future<Image> thumbnail(String filename, [frameIdx = 0]) async {
    Uint8List frameFromIndex =
        await probeFrames(FrameIsolate([frameIdx], xfile.path)).then((frames) => frames.first);
    Uint8List resizedFrame = resize(frameFromIndex, ImageFormat.png, 500, 500);

    return Image.fromBytes(resizedFrame, created, xfile.path, filename);
  }
}

/// A card representing a video thumbnail
///
///
class Thumbnail {
  Video video;
  int frameIdx;
  bool isCached = false;
  String filename = "thumbnail.jpg";

  Thumbnail(this.video, this.frameIdx);

  Thumbnail.fromBytes(Uint8List bytes, this.video, this.frameIdx) {
    XFileStorage.fromBytes(video.pwd, filename, bytes);
    isCached = true;
  }

  Future<Image> get image => video.thumbnail(filename, frameIdx);

  Future<Uint8List> get cachedBytes async {
    final xfile = await manifest.read(video.pwd, filename);
    return await xfile.readAsBytes();
  }

  Future<void> cache() async {
    final bytes = await (await image).asBytes;
    await manifest.write(bytes.toList(), video.pwd, filename);
    isCached = true;
  }

  Future<mat.Widget> get widget async => mat.Image.memory(
      (isCached) ? await cachedBytes : await (await image).asBytes);
}
