import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'video.dart';

String sha256ofBytes(Uint8List bytes, int chars) =>
    sha256.convert(bytes).toString().substring(0, chars);

enum PreprocessType {
  sso, // https://faculty.washington.edu/lagesse/publications/SSO.pdf
  motion // https://docs.opencv.org/4.x/d4/dee/tutorial_optical_flow.html
}

class NormalizedByteArray {
  PreprocessType type;
  NormalizedByteArray(this.type);

  /// Convert the video into a normalized byte array
  ///
  /// Returns a map of startFrame to normalized byte arrays
  ///
  Map preprocess(Video video, FrameCount frameCount) {
    switch (type) {
      case PreprocessType.sso:
        const segment = Duration(seconds: 1);
        final bytes = countBytesInVideoSegment(video, segment, frameCount);

        // Normalize each segment with the sum of ALL elements
        final flatNormalized = normalizeSumOfElements(flatten(bytes).toList());
        List<List<double>> normalized = [];

        // Divide the normalized array into segments
        for (var i = 0; i < bytes.length; i++) {
          var segmentSize = bytes[i].length;
          final start = i * segmentSize;
          final end = (i + 1) * segmentSize;
          normalized.add(flatNormalized.sublist(start, end));
        }
        print('[DEBUG] Normalized: $normalized');

        final timestamps = video.timestampsFromSegment(video, segment);
        print('[DEBUG] Timestamps: $timestamps');

        return {
          'bytes': bytes,
          'normalized': normalized,
          'timestamps': timestamps,
        };
      case PreprocessType.motion:
        // preprocessMotion(video);
        throw UnsupportedError('Motion preprocessing not implemented');
    }
  }
}

/// Flatten an iterable of iterables
///
Iterable<T> flatten<T>(Iterable<Iterable<T>> items) sync* {
  for (var i in items) {
    yield* i;
  }
}

/// Normalize the array by the sum of the elements by element
///
/// Returns a list of normalized values, whose sum equals 1
///
List<double> normalizeSumOfElements(List<int> values) {
  // Find the sum of the values
  final sum = values.reduce((value, element) => value + element);
  // Normalize the values
  return values.map((e) => e / sum).toList();
}

/// Count the number of bytes within each video segment
///
List<List<int>> countBytesInVideoSegment(
    Video video, Duration segment, FrameCount frameCount) {
  List<List<int>> byteLengths = [];
  final frameRanges = video.frameIndexFromSegment(segment, frameCount);

  for (var range in frameRanges) {
    print('[DEBUG] Range: $range');
    final frames = video.frames(frameIds: range);

    List<int> frameByteLengths = [];
    for (var frame in frames) {
      frameByteLengths.add(frame.length);
    }

    byteLengths.add(frameByteLengths);
  }
  return byteLengths;
}
