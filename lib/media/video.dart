import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart' as mat;
import 'package:flutter_fhe_video_similarity/media/cache.dart';
import 'package:flutter_fhe_video_similarity/media/storage.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

import 'processor.dart';
import 'primatives.dart';
import 'image.dart';

class VideoMeta extends Meta {
  final String codec;
  final int fps;
  final Duration duration;
  final String sha256;
  final int startFrame;
  final int endFrame;
  final int totalFrames;

  VideoMeta({
    required this.codec,
    required this.fps,
    required this.totalFrames,
    required this.duration,
    required this.sha256,
    required this.startFrame,
    required this.endFrame,
    required String name,
    required String extension,
    required DateTime created,
    required DateTime modified,
    required String path
  }) : super(name, extension, created, modified, path);

  @override
  Map toJson() => {
    ...super.toJson(),
    'codec': codec,
    'fps': fps,
    'totalFrames': totalFrames,
    'sha256': sha256,
    'duration': duration.inSeconds,
    'startFrame': startFrame,
    'endFrame': endFrame
  };

  VideoMeta.fromJSON(Map<String, dynamic> json) : this(
    codec: json['codec'],
    fps: json['fps'],
    totalFrames: json['totalFrames'],
    duration: Duration(seconds: json['duration']),
    sha256: json['sha256'],
    startFrame: json['startFrame'],
    endFrame: json['endFrame'],
    name: json['name'],
    extension: json['extension'],
    created: DateTime.parse(json['created']),
    modified: DateTime.parse(json['modified']),
    path: json['path']
  );

  void pprint() {
    print('--- Video Information ---');
    print(' * Codec: $codec');
    print(' * Duration: $duration');
    print(' * FPS: $fps');
    print(' * Frame Count: $totalFrames');
    print(' * Start Frame: $startFrame');
    print(' * End Frame: $endFrame');
    print(' * Path: $path');
    print('-------------------------');
  }
}

enum FrameCount {
  all,
  even,
  odd,
  firstLast
}

class Video extends UploadedMedia {
  // Logger log = Logger('Video');
  int startFrame = 0;

  late int endFrame;
  late int totalFrames;
  late cv.VideoCapture video;
  late String hash;
  
  Video(XFile file, DateTime timestamp, {Duration start = Duration.zero, Duration end = Duration.zero}) : super(file, timestamp) {

    video = cv.VideoCapture.fromFile(file.path, apiPreference: _cvApiPreference);
    created = timestamp;

    // Get frame count
    totalFrames = frameCount();

    // Set the end frame (used for trimming)
    endFrame = totalFrames - 1;
  
    // Set the start and end positions
    trim(start, end);

    // Calculate the hash
    hash = sha256ofBytes(video.read().$2.data, 8);

    printStats(); // TODO: Remove
  }
  
  Video.fromeCache(XFile file, DateTime timestamp, this.hash, this.startFrame, this.endFrame, this.totalFrames) : super(file, timestamp) {
    video = cv.VideoCapture.fromFile(file.path, apiPreference: _cvApiPreference);
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
    path: xfile.path
  );

  void printStats() {
    stats.pprint();
  }

  // Future<String> sha256({chars=8}) async => await sha256ofFileAsString(xfile.path, chars);

  String get pwd =>
    '$hash/$startFrame-$endFrame-${created.millisecondsSinceEpoch}';

  void cache() async {
    final bytes = await asBytes; // TODO: trim?
    manifest.write(bytes.toList(), pwd, "video.mp4");

    stats.cache(pwd);
  }

  int get fps => video.get(cv.CAP_PROP_FPS).toInt();
  Duration get duration => Duration(seconds: (endFrame - startFrame) ~/ fps);

  /// Get the OpenCV API preference based on the platform
  ///
  int get _cvApiPreference {
    switch (Platform.operatingSystem) {
      case 'android':
        return cv.CAP_ANDROID;
      default:
        return cv.CAP_ANY;
    }
  }

  /// Seek to a specific position in the video
  ///
  void trim(Duration start, Duration end) {
    final fps = video.get(cv.CAP_PROP_FPS);
    int trimStart = (start.inSeconds * fps).toInt();
    int trimLast = (end.inSeconds * fps).toInt();

    if (startFrame > endFrame || startFrame < 0
        || trimStart > totalFrames || trimLast > totalFrames
        || (trimStart + trimLast) > totalFrames) {
      throw ArgumentError('Invalid trim range');
    }

    // Check if the target frame is within the video frame range
    if (trimStart >= 0) {
      print("[trim] Seeking $trimStart frames from the start");
      startFrame = trimStart;
    }

    if (trimLast > 0 && trimLast < endFrame) {
      print("[trim] Cutting $trimLast frames from the end");
      endFrame = (endFrame - trimLast);
    }
  }

  /// Step through the video frame by frame and count the number of frames
  ///
  /// Exposing this method to the user is not recommended as it is slow and
  /// inefficient. Use [frameCount] instead.
  ///
  int _frameCountManual() {
    // Create + Release video copy
    final copy = cv.VideoCapture.fromFile(xfile.path);
    var frames = 0;
    var (success, _) = copy.read();
    while (success) {
      frames += 1;
      (success, _) = copy.read();
    }
    print("Manual Frame count: $frames");
    copy.release();
    return frames;
  }

  /// Calculate the number of frames in the video
  /// 
  /// The number of frames is calculated using the CAP_PROP_FRAME_COUNT property
  /// of the video. If the property is not supported by the codec, the number of
  /// frames is calculated manually.
  ///
  int frameCount() {
    final frames = video.get(cv.CAP_PROP_FRAME_COUNT).toInt();

    // CAP_PROP_FRAME_COUNT is not supported by all codecs
    if (frames == 0) {
      return _frameCountManual();
    }
    print("Frame count: $frames");
    return frames;
  }

  /// Extract frames from the video
  ///
  /// Encode frames at the specified [frameIds], by default, extract 
  /// the first frame, the frame at 1/4, 1/2, and 3/4 of the video length.
  ///
  List<Uint8List> frames(
    {List<int> frameIds = const [0],
     cv.ImageFormat frameFormat = cv.ImageFormat.png}
  ) {
    var frames = <Uint8List>[];
    int length = frameIds.length; // Number of frames to extract

    // Create a copy of the video to not interfere with the original
    final copy = cv.VideoCapture.fromFile(xfile.path);

    // Iterate through the video and extract the frames
    if (copy.isOpened & (length > 0)) {
      var idx = 0;
      var (success, image) = copy.read();
      while (success && idx <= endFrame) {
        // Read when the frame is selected
        if (frameIds.contains(idx)) {
          print("[videoFrames] Reading Frame $idx");
          frames.add(
            cv.imencode(frameFormat.ext, image), // Mat -> Uint8List
          );
        }
        (success, image) = copy.read();
        idx += 1;
      }
      print('[videoFrames] end of video: $idx');
    }
    // Clear the video buffer
    copy.release();
    print("[frames] Extracted ${frames.length} frames");
    return frames;
  }

  /// Extract frames from the video within a range
  ///
  List<Uint8List> framesFromRange(int start, int end) {
    return frames(frameIds: List<int>.generate(end - start, (i) => i + start));
  }

  /// Estimate the timestamps at the start of each segment
  ///
  List<DateTime> timestampsFromSegment(Video video, Duration segmentDuration) {
    List<DateTime> segments = [];
    for (int i = startFrame; i < endFrame; i += segmentDuration.inSeconds * fps) {
      segments.add(created.add(Duration(seconds: i ~/ fps)));
    }
    return segments;
  }

  /// Generate ranges of frame indices based on the [segmentDuration]
  /// 
  List<List<int>> frameIndexFromSegment(Duration segmentDuration, {FrameCount frameCount = FrameCount.firstLast}) {
    List<List<int>> segments = [];
    int segment = segmentDuration.inSeconds * fps;

    for (int i = startFrame; i < endFrame; i += segment) {
      // Drop all values greater than the end frame
      var inc = List<int>.generate(segment, (inc) => i + inc);
      var all = inc.where((idx) => idx <= endFrame).toList();

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
      }
    }
    return segments;
  }

  /// Generate an [Image] from the video
  ///
  /// A thumbnail is generated from the frame at [frameIdx] of the video.
  ///
  Image thumbnail(String filename, [frameIdx = 0]) {

    Uint8List frameFromIndex = frames(frameIds: [frameIdx]).first;
    Uint8List resizedFrame = resize(frameFromIndex, cv.ImageFormat.jpg, 500, 500);

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
    final xfile = XFileStorage.fromBytes(video.pwd, filename, bytes);
    isCached = true;
  }

  Image get image => video.thumbnail(filename, frameIdx);

  Future<Uint8List> get cachedBytes async {
    final xfile = await manifest.read(video.pwd, filename);
    return await xfile.readAsBytes();
  }

  void cache() async {
    final bytes = await image.asBytes;
    manifest.write(bytes.toList(), video.pwd, filename);
    isCached = true;
  }

  Future<mat.Widget> get widget async => mat.Image.memory(
    (isCached) ? await cachedBytes : await image.asBytes
  );

}
