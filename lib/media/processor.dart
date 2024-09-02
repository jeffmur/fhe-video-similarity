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
        List<List<int>> bytes =
            countBytesInVideoSegment(video, segment, frameCount);

        // For this algorithm, first calculate the sum of each segment
        List<int> sumOfFrameSegments =
            bytes.map((segment) => segment.reduce((a, b) => a + b)).toList();

        print('[DEBUG] Length: ${sumOfFrameSegments.length}');

        // Normalize each segment with the sum of ALL elements
        final normalized = normalizeSumOfElements(sumOfFrameSegments);

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
  // Normalize the values between 0 and 1
  return values.map((e) => e / sum).toList();
}

/// Count the number of bytes within each video segment
///
List<List<int>> countBytesInVideoSegment(
    Video video, Duration segment, FrameCount frameCount) {
  List<List<int>> byteLengths = [];
  var frameRangesFromSegment = video.frameIndexFromSegment(segment, frameCount);

  for (var range in frameRangesFromSegment) {
    print('[DEBUG] Frame Range: $range');
    final frames = video.frames(frameIds: range);

    List<int> frameByteLengths = [];
    for (var frame in frames) {
      frameByteLengths.add(frame.length);
    }
    byteLengths.add(frameByteLengths);
  }
  return byteLengths;
}
