// import 'dart:isolate';
import 'dart:io';
import 'dart:typed_data';
// import 'package:logging/logging.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:opencv_dart/opencv_dart.dart' as cv;

import 'processor.dart';

String get opencvInfo => cv.getBuildInformation();

class ExistingMedia {
  XFile file;
  ExistingMedia(this.file);
  
  DateTime get modified => FileStat.statSync(file.path).modified;
  // DateTime get accessed => FileStat.statSync(file.path).accessed;

  // DateTime get created => PROMPT USER

  String get path => file.path;

  Future<Uint8List> get buffer async => await file.readAsBytes();
}

class Video extends ExistingMedia {
  // Logger log = Logger('Video');
  int startFrame = 0;
  DateTime created = DateTime.now();

  late int endFrame;
  late cv.VideoCapture video;
  late int totalFrames;
  
  Video(XFile file, DateTime timestamp, {Duration start = Duration.zero, Duration end = Duration.zero}) : super(file) {

    video = cv.VideoCapture.fromFile(file.path, apiPreference: _cvApiPreference);
    created = timestamp;

    // Get frame count
    totalFrames = frameCount();

    // Set the end frame (used for trimming)
    endFrame = totalFrames - 1;
  
    // Set the start and end positions
    trim(start, end);

    printStats(); // TODO: Remove
  }

  Map get stats => {
    'codec': video.codec,
    'fps': video.get(cv.CAP_PROP_FPS),
    'frameCount': totalFrames,
    'duration': duration,
    'startFrame': startFrame,
    'endFrame': endFrame,
  };

  void printStats() {
    print('--- Video Information ---');
    print(' * Codec: ${stats['codec']}');
    print(' * Duration: ${stats['duration']}');
    print(' * FPS: ${stats['fps']}');
    print(' * Frame Count: ${stats['frameCount']}');
    // print(' * Last Modified: ${modified.toLocal()}');
    // print(' * Last Accessed: ${accessed.toLocal()}');
  }

  Future<String> sha256({chars=16}) async => await sha256ofFileAsString(file.path, 8);

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
    final copy = cv.VideoCapture.fromFile(file.path);
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

    print("$frameIds of $endFrame frames");

    // Create a copy of the video to not interfere with the original
    final copy = cv.VideoCapture.fromFile(file.path);

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
}

enum FrameCount {
  all,
  even,
  odd,
  firstLast
}

class Thumbnail {
  Video video;
  int frameIdx;
  (int, int) dimensions = (500, 500);

  Thumbnail(this.video, this.frameIdx);

  /// The thumbnail is generated from a frame [buffer] of the video
  ///
  Uint8List thumbnailFromFrame(Uint8List buffer) {
    // final ret = Isolate.run(() {
    //   final im = cv.imdecode(buffer, cv.IMREAD_COLOR);
    //   final thumb = cv.resize(im, size, interpolation: cv.INTER_AREA);
    //   return cv.imencode(cv.ImageFormat.png.ext, thumb);
    // });
    // return ret;
    // thumbnail = Image(XFile.fromData(await ret));
    final im = cv.imdecode(buffer, cv.IMREAD_COLOR);
    final thumb = cv.resize(im, dimensions, interpolation: cv.INTER_AREA);
    return cv.imencode(cv.ImageFormat.png.ext, thumb);
  }

  /// Generate the thumbnail from the [Video]
  /// 
  /// The thumbnail is generated from the frame at [frameIdx] of the video.
  ///
  XFile get thumbnail => XFile.fromData(buffer);

  /// Get the frame buffer from the video
  ///
  Uint8List get buffer =>
    thumbnailFromFrame(
      video.frames(frameIds: [frameIdx]).first);

  /// Get the thumbnail as a widget
  Widget get widget => Image.memory(buffer);
}
