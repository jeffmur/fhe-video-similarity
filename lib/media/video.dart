import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart' as mat;
import 'package:flutter_fhe_video_similarity/logging.dart';
import 'package:flutter_fhe_video_similarity/media/cache.dart';
import 'package:flutter_fhe_video_similarity/media/storage.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:flutter/foundation.dart';

import 'processor.dart';
import 'primatives.dart';
import 'image.dart';

class VideoMeta extends Meta {
  String codec;
  int fps;
  Duration duration;
  String sha256;
  int startFrame;
  int endFrame;
  int totalFrames;
  String encryptionStatus;
  late String id; // Unique identifier of Video

  VideoMeta(
      {required this.codec,
      required this.fps,
      required this.totalFrames,
      required this.duration,
      required this.sha256,
      required this.startFrame,
      required this.endFrame,
      required this.encryptionStatus,
      required String name,
      required String extension,
      required DateTime created,
      required DateTime modified,
      required String path})
      : super(name, extension, created, modified, path) {
    id = '${sha256.substring(0, 8)}-${created.millisecondsSinceEpoch}';
  }

  @override
  Map toJson() => {
        ...super.toJson(),
        'codec': codec,
        'fps': fps,
        'totalFrames': totalFrames,
        'sha256': sha256,
        'durationSeconds': duration.inSeconds,
        'startFrame': startFrame,
        'endFrame': endFrame,
        'encryptionStatus': encryptionStatus,
      };

  VideoMeta.fromJson(Map<String, dynamic> json)
      : this(
            codec: json['codec'],
            fps: json['fps'],
            totalFrames: json['totalFrames'],
            duration: Duration(seconds: json['durationSeconds']),
            sha256: json['sha256'],
            startFrame: json['startFrame'],
            endFrame: json['endFrame'],
            name: json['name'],
            extension: json['extension'],
            created: DateTime.parse(json['created']),
            modified: DateTime.parse(json['modified']),
            encryptionStatus: json['encryptionStatus'],
            path: json['path']);

  VideoMeta.fromFile(File file)
      : this.fromJson(jsonDecode(file.readAsStringSync()));

  void pprint() {
    print('--- Video Information ---');
    print(' * Codec: $codec');
    print(' * Duration: $duration seconds');
    print(' * FPS: $fps');
    print(' * Frame Count: $totalFrames');
    print(' * Start Frame: $startFrame');
    print(' * End Frame: $endFrame');
    print(' * Path: $path');
    print('-------------------------');
  }

  @override
  String toString() => toJson().toString();
}

/// Get the OpenCV API preference based on the platform
///
int get cvApiPreference {
  if (Platform.isAndroid) {
    return cv.CAP_ANDROID;
  } else {
    return cv.CAP_FFMPEG;
  }
}

enum ImageFormat { jpg, png }

enum FrameCount { all, even, odd, firstLast, random5, randomHalf }

class FrameData {
  final int id;
  final Uint8List bytes;

  FrameData(this.id, this.bytes);
}

class FrameIsolate {
  final List<int> frameIds;
  final String videoPath;
  String frameFormat = 'png';

  FrameIsolate(this.frameIds, this.videoPath);
}

Future<List<Uint8List>> extractFrames(FrameIsolate args) async {
  final bytes = <Uint8List>[];

  // Open the video file in the isolate
  final copy = await cv.VideoCaptureAsync.fromFileAsync(args.videoPath,
      apiPreference: cvApiPreference);
  var success = await copy.grabAsync();
  if (!copy.isOpened || args.frameIds.isEmpty || !success) return [];

  var idx = 0;
  // Iterate through 0..N inclusively, assumes frameIds are sorted
  while (success && idx <= args.frameIds.last) {
    if (args.frameIds.contains(idx)) {
      var (exist, image) = await copy.readAsync();
      if (!image.isEmpty) {
        bytes.add((await cv.imencodeAsync(".${args.frameFormat}", image)).$2);
      }
    }
    success = await copy.grabAsync();
    idx += 1;
  }
  await copy.releaseAsync();

  return bytes;
}

/// Extract the frame sizes of the video
///
Future<List<int>> extractFrameSizes(FrameIsolate args) async {
  final sizes = <int>[];

  // Open the video file in the isolate
  final copy = await cv.VideoCaptureAsync.fromFileAsync(args.videoPath,
      apiPreference: cvApiPreference);
  var success = await copy.grabAsync();
  if (!copy.isOpened || args.frameIds.isEmpty || !success) return [];

  var idx = 0;
  // Iterate through 0..N inclusively, assumes frameIds are sorted
  while (success && idx <= args.frameIds.last) {
    if (args.frameIds.contains(idx)) {
      var (exist, image) = await copy.readAsync();
      if (!image.isEmpty) {
        var frameData =
            (await cv.imencodeAsync(".${args.frameFormat}", image)).$2;
        sizes.add(frameData.length);
      }
    }
    success = await copy.grabAsync();
    idx += 1;
  }
  await copy.releaseAsync();
  return sizes;
}

/// Step through the video frame by frame and count the number of frames
///
/// Exposing this method to the user is not recommended as it is slow and
/// inefficient. Use [frameCount] instead.
///
int countAllFrames(String videoPath) {
  // Create + Release video copy
  final copy = cv.VideoCapture.fromFile(videoPath);
  var frames = 0;
  var (success, _) = copy.read();
  while (success) {
    frames += 1;
    (success, _) = copy.read();
  }
  copy.release();
  return frames;
}

/// Estimate the timestamps at the start of each segment
///
List<DateTime> timestampsFromSegment(VideoMeta meta, Duration segmentDuration) {
  List<DateTime> segments = [];
  for (int i = meta.startFrame;
      i < meta.endFrame;
      i += segmentDuration.inSeconds * meta.fps) {
    segments.add(meta.created.add(Duration(seconds: i ~/ meta.fps)));
  }
  return segments;
}

/// Generate ranges of frame indices based on the [segmentDuration]
///
List<List<int>> frameIndexFromSegment(
    VideoMeta meta, Duration segmentDuration, FrameCount frameCount) {
  List<List<int>> segments = [];
  int segment = segmentDuration.inSeconds * meta.fps;

  for (int i = meta.startFrame; i < meta.endFrame; i += segment) {
    // Drop all values greater than the end frame
    var inc = List<int>.generate(segment, (inc) => i + inc);
    var all = inc.where((idx) => idx <= meta.endFrame).toList();

    switch (frameCount) {
      case FrameCount.firstLast:
        segments.add([all.first, all.last]);
        break;
      case FrameCount.even:
        segments.add(all.where((idx) => idx % 2 == 0).toList());
        break;
      case FrameCount.odd:
        segments.add(all.where((idx) => idx % 2 != 0).toList());
        break;
      case FrameCount.all:
        segments.add(all);
        break;
      case FrameCount.random5:
        final allRandom = all;
        allRandom.shuffle();
        segments.add(allRandom.take(5).toList());
        break;
      case FrameCount.randomHalf:
        final halfRandom = all;
        halfRandom.shuffle(Random());
        segments.add(halfRandom.take(all.length ~/ 2).toList());
        break;
    }
  }
  return segments;
}

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
    totalFrames = frameCount;

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
    final bytes = await asBytes; // TODO: trim?
    manifest.write(bytes.toList(), pwd, "video.mp4");

    stats.cache(pwd);
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

  /// Calculate the number of frames in the video
  ///
  /// The number of frames is calculated using the CAP_PROP_FRAME_COUNT property
  /// of the video. If the property is not supported by the codec, the number of
  /// frames is calculated manually.
  ///
  int get frameCount {
    final frames = video.get(cv.CAP_PROP_FRAME_COUNT).toInt();

    // CAP_PROP_FRAME_COUNT is not supported by all codecs
    if (frames == 0) {
      return countAllFrames(xfile.path);
    }
    return frames;
  }

  Future<List<int>> probeFrameSizes({List<int> frameIds = const [0]}) async {
    return await compute<FrameIsolate, List<int>>(
        extractFrameSizes, FrameIsolate(frameIds, xfile.path));
  }

  Future<List<Uint8List>> probeFrames({List<int> frameIds = const [0]}) async {
    return await compute<FrameIsolate, List<Uint8List>>(
        extractFrames, FrameIsolate(frameIds, xfile.path));
  }

  /// Generate an [Image] from the video
  ///
  /// A thumbnail is generated from the frame at [frameIdx] of the video.
  ///
  Future<Image> thumbnail(String filename, [frameIdx = 0]) async {
    Uint8List frameFromIndex =
        await probeFrames(frameIds: [frameIdx]).then((frames) => frames.first);
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
