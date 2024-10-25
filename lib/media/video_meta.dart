import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'primatives.dart';

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

enum ImageFormat { jpg, png }

enum FrameCount { all, even, odd, firstLast, random5, randomHalf }

class FrameData {
  final int id;
  final Uint8List bytes;

  FrameData(this.id, this.bytes);
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
