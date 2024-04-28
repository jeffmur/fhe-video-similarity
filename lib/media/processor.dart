import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'primatives.dart';

Future<Digest> sha256ofFile(String path) =>
    File(path).openRead().transform(sha256).first;

Future<String> sha256ofFileAsString(String path, int chars) async {
  final hash = await sha256ofFile(path);
  return hash.toString().substring(0, chars);
}

enum PreprocessType { size, motion }

class NormalizedByteArray {
  PreprocessType type;
  NormalizedByteArray(this.type);

  List<double> preprocess(Video video) {
    switch (type) {
      case PreprocessType.size:
        return countBytesInVideoSegment(video, const Duration(seconds: 1));
      case PreprocessType.motion:
        // preprocessMotion(video);
        throw UnimplementedError('Motion preprocessing not implemented');
    }
  }
}

/// Normalize the byte lengths of each frame
/// 
/// The [values] are normalized by dividing each byte length by the maximum byte length.
///
List<double> normalizeZeroToOne(List<int> values) {
  // Find the maximum value
  final max = values.reduce((value, element) => value > element ? value : element);
  // Normalize the values
  return values.map((e) => e / max).toList();
}

/// Count the number of bytes in each frame of segment
///
List<double> countBytesInVideoSegment(Video video, Duration segment) {
  // Get the frames
  final frameRanges = video.getVideoSegments(segment);
  List<int> byteLengths = [];

  for (var range in frameRanges) {
    print('Target Frame Range (${range.first} - ${range.last})');
    print('[DEBUG] Range: $range');
    final frames = video.frames(frameIds: [range.first]);
    var frameIdx = 0;
    for (var frame in frames) {
      print('[DEBUG] Frame: $frameIdx of ${frames.length}');
      print('[DEBUG] Frame Length: ${frame.length}');
      frameIdx = frameIdx + 1;
      byteLengths.add(frame.length);
    }
    print('[DEBUG] Byte Lengths: $byteLengths');
  }
  final normalized = normalizeZeroToOne(byteLengths);
  print('[DEBUG] Normalized: $normalized');
  return normalized;
}
