import 'dart:io';
import 'dart:typed_data';
import 'package:pool/pool.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'video.dart';

String sha256ofBytes(Uint8List bytes, int chars) =>
    sha256.convert(bytes).toString().substring(0, chars);

enum PreprocessType {
  sso, // https://faculty.washington.edu/lagesse/publications/SSO.pdf
  // motion // https://docs.opencv.org/4.x/d4/dee/tutorial_optical_flow.html
}

class NormalizedByteArray {
  PreprocessType type;
  NormalizedByteArray(this.type);

  /// Convert the video into a normalized byte array
  ///
  /// Returns a map of startFrame to normalized byte arrays
  ///
  Future<Map> preprocess(Video video, FrameCount frameCount,
      {Duration segment = const Duration(seconds: 1)}) async {
    // Tradeoff: Higher concurrency leads to more memory usage
    // Findings: Multi-threading unstable on mobile, high failure rate
    final maxConcurrency = (Platform.isAndroid || Platform.isIOS) ? 1 : 3;
    switch (type) {
      case PreprocessType.sso:
        List<List<int>> bytes = await countBytesInVideoSegment(
            video, segment, frameCount,
            maxConcurrency: maxConcurrency);

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
      // case PreprocessType.motion:
      //   // preprocessMotion(video);
      //   throw UnsupportedError('Motion preprocessing not implemented');
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

///
/// Tradeoffs:
/// - Higher concurrency (using futures) leads to more memory usage, causing the main thread to slow
/// - Lower concurrency (using for loop / stream) leads to less memory usage, but slower processing time
///

/// Count the number of bytes within each video segment with limited concurrency
///
Future<List<List<int>>> countBytesInVideoSegment(
    Video video, Duration segment, FrameCount frameCount,
    {int maxConcurrency = 2}) async {
  var frameRangesFromSegment =
      frameIndexFromSegment(video.stats, segment, frameCount);

  // Create a pool to limit concurrency
  final pool = Pool(maxConcurrency);

  // Create a list of futures, limiting concurrency using pool.withResource
  List<Future<List<int>>> byteLengthFutures =
      frameRangesFromSegment.map((range) async {
    return await pool.withResource(() async {
      return await video.probeFrameSizes(frameIds: range);
    });
  }).toList();

  // Wait for all futures to complete and return the results
  final results = await Future.wait(byteLengthFutures);

  // Close the pool when you're done to clean up resources
  await pool.close();
  return results;
}
