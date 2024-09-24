import 'dart:typed_data';
import 'dart:collection';
import 'package:flutter/foundation.dart';
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
  Future<Map> preprocess(Video video, FrameCount frameCount, {Duration segment = const Duration(seconds: 1)}) async {
    switch (type) {
      case PreprocessType.sso:
        List<List<int>> bytes =
            await countBytesInVideoSegment(video, segment, frameCount);

        // For this algorithm, first calculate the sum of each segment
        List<int> sumOfFrameSegments =
            bytes.map((segment) => segment.reduce((a, b) => a + b)).toList();

        // Normalize each segment with the sum of ALL elements
        final normalized = normalizeSumOfElements(sumOfFrameSegments);

        // Align each segment with timestamp
        final timestamps = timestampsFromSegment(video.stats, segment);

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

/// Count the number of bytes within each video segment with limited concurrency
Future<List<List<int>>> countBytesInVideoSegment(
    Video video, Duration segment, FrameCount frameCount,
    {int maxConcurrency = 2}) async {
  var frameRangesFromSegment =
      frameIndexFromSegment(video.stats, segment, frameCount);

  // Create a list of futures to fetch frames and calculate byte lengths
  List<Future<List<int>>> byteLengthFutures = frameRangesFromSegment.map((range) async {
    // Fetch the frames for each segment
    final frames = await video.frames(frameIds: range);

    // Calculate byte lengths for each frame
    return frames.map((frame) => frame.length).toList();
  }).toList();

  // Wait for all futures to complete and return the results
  return await Future.wait(byteLengthFutures);
}
