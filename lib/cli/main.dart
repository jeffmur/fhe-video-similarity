/* cli/baseline.dart

Evaluate baseline data from Kevin Wu's research

Usage: dart baseline.dart [options] <input.csv>

Expected CSV shape:
  dtype, frame1 size, frame2 size, ..., frameN size
  Video, 1, 2, ..., N
  Pcap,
  ...

Attributes:
  - Each row is one minute of video, with 10 frames per second (600 columns)
  - Analysis is exhaustive, comparing each row to every other row (same or different csvs)
*/

import 'dart:io';
import 'dart:math';
import 'package:args/args.dart';
import 'csv.dart';
import '../similarity.dart';
import '../media/processor.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

/* Supported Use Cases:
  1. In-place (--pcap) comparison of each Video to complementary Pcap (same csv)
    * Compare distance measure implementation vs. SSO
    * KLD, Cramer

  2. Summarize (--scores) dart vs. SSO
    * Calculate standard deviation of each row pair
    * KLD, Cramer

  3. Pre-process (--video) into 1 minute segments
    * Normalize each segment

  4. Compare (--versus) two CSV files

*/
void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('video', help: 'Video file to process')
    ..addOption('csv', help: 'CSV File to compare')
    ..addOption('dir', help: 'Directory of CSV files') // Cannot be used with csv
    ..addOption('versus', help: 'Compare against another CSV file')
    ..addOption('output', abbr: 'o', help: 'Output file for results')
    ..addFlag('pcap', help: 'Compare Video to Pcap', negatable: false)
    ..addFlag('normalized', help: 'Extract "Normalized" rows from csv', negatable: false)
    ..addFlag('scores', help: 'Calculate variance of scores', negatable: false)
    ..addFlag('help', abbr: 'h', help: 'Show help', negatable: false);

  final results = parser.parse(args);

  if (results['help']) {
    print(parser.usage);
    exit(0);
  }

  /*
    Distance measure of each Video vs. Pcap row pair
    SSO vs. Dart implementation of KLD, Cramer

    Usage: dart run lib/cli/main.dart --csv results/1_baseline/raw_data/1080p-original_data.csv
           --pcap --output results/1_baseline/raw_data/1080p-0_degree.csv
  */
  if(results['versus'] == null && results['pcap']) {
    final data = OriginalData(results['csv']);
    List<double> kld = [];
    List<double> cramer = [];

    for (var i = 0; i < data.videos.length; i++) {
      final v = data.videos[i].normalize();
      final p = data.pcaps[i].normalize();
      kld.add(Similarity(SimilarityType.kld).score(v, p));
      cramer.add(Similarity(SimilarityType.cramer).score(v, p));
    }

    // Check if output file is specified,
    // requires copy-paste of sso values for comparison
    if (results['output'] != null) {
      final output = File(results['output']);
      output.createSync(recursive: true); // if it doesn't exist

      // Create a list of CSV rows to write
      List<String> writeRows = ['KLD-dart, Cramer-dart'];
      for (var i = 0; i < kld.length; i++) {
        writeRows.add("${kld[i]}, ${cramer[i]}");
      }
      output.writeAsStringSync(writeRows.join("\n"));
    }
    // Print out the average of each similarity measure, in-order
    else {
      print('KLD, Cramer');
      for (var i = 0; i < kld.length; i++) {
        print("${kld[i]}, ${cramer[i]}");
      }
    }
  }

  /*
    Slice each Video into 1 minute segments, extract byte counts, normalize each segment

    Usage: dart run lib/cli/main.dart --video results/2_fov/raw/1080p-original.mp4

    Requires: export OPENCV_DART_LIB_PATH="/path/to/libopencv_dart.so"
  */
  else if(results['video'] != null) {
    String videoPath = results['video'];
    if (!File(videoPath).existsSync()) {
      print('FATAL: Cannot find --video $videoPath');
      exit(1);
    }
    print('Processing video: $videoPath');
    final video = cv.VideoCapture.fromFile(videoPath, apiPreference: cvApiPreference);
    final totalFrames = frameCount(videoPath);
    final fps = video.get(cv.CAP_PROP_FPS).toInt();
    final codec = video.codec;
    final duration = Duration(seconds: totalFrames ~/ fps);

    final meta = VideoMeta(
      name: videoPath.split('/').last,
      path: videoPath,
      extension: videoPath.split('.').last,
      codec: codec,
      fps: fps,
      totalFrames: totalFrames,
      duration: duration,
      sha256: sha256ofBytes(video.read().$2.data, 8),
      startFrame: 0,
      endFrame: totalFrames,
      encryptionStatus: 'plain',
      created: DateTime.now(),
      modified: DateTime.now()
    );

    // Normalize every frame within each 1 second segment of the video
    final perSecond = await NormalizedByteArray(PreprocessType.sso)
      .preprocess(meta, FrameCount.all, segment: const Duration(seconds: 1), maxConcurrency: 2);

    // Write / Append to a CSV file
    if(results['output'] != null) {
      final output = File(results['output']);
      output.createSync(recursive: true); // if it doesn't exist
      final rows = [];

      // Write two rows for 'Video' (bytes) and 'Normalized' (sum of segments)
      //
      rows.add("Video ($fps fps - $codec - ${duration.inSeconds}s),${perSecond['bytes'].map((e) => e.join(',')).join(',')}");
      rows.add("Normalized,${perSecond['normalized'].join(',')}");
      output.writeAsStringSync("${rows.join("\n")}\n", mode: FileMode.append);
    }
    else {
      print('Duration (seconds): ${perSecond['bytes'].length}');
      print('FPS: ${perSecond['bytes'][0].length}');
      print('Normalized: ${perSecond['normalized']}');
    }
  }

  /*
    Extract "Normalized" rows from a CSV file to generate supervised training data

    Note: To accommodate varying sizes of each row, we will pad with 0s smaller than the largest row

    Supports --versus for comparison of two CSV files

    Usage: dart run lib/cli/main.dart --normalized --csv results/1_baseline/raw_data/1080p-original_data.csv
        --output results/1_baseline/raw_data/1080p-similarity.csv

    Same?, KLD, Cramer, Bhattacharyya
    1, 0.1, 0.2, 0.3
    0, 0.4, 0.5, 0.6
    ...
  */
  else if(results['csv'] != null && results['normalized']) {
    final data = OriginalData(results['csv']);

    // Support comparison of one or two CSV files
    final versus = results['versus'] != null ? OriginalData(results['versus']) : data;
    final isSameCSV = results['versus'] == null;

    // Find the largest row, pad other
    final maxFrameSize = data.normalized.fold(0, (prev, e) => e.frames.length > prev ? e.frames.length : prev);

    // Find the minimum number of rows to compare (used for exhaustive comparison)
    final minRows = data.normalized.length < versus.normalized.length ? data.normalized.length : versus.normalized.length;

    // Similarity Scores are generated between two rows
    // When comparing one CSV file, when i == j is an exact match (1)
    print('Same?, KLD, Cramer, Bhattacharyya');
    for (var i = 0; i < minRows; i++) {
      for (var j = 0; j < minRows; j++) {
        List<double> p = sanitize(data.normalized[i].frames, maxFrameSize);
        List<double> q = sanitize(versus.normalized[j].frames, maxFrameSize);
        double kld = Similarity(SimilarityType.kld).score(p, q);
        double cramer = Similarity(SimilarityType.cramer).score(p, q);
        double bhattacharyya = Similarity(SimilarityType.bhattacharyya).score(p, q);
        String scoreVector = "$kld, $cramer, $bhattacharyya";
        if (isSameCSV && i == j) {
          print('1, $scoreVector');
        }
        else {
          print('0, $scoreVector');
        }
      }
    }
  }
}

/// Cast List<num> to List<double> pad with 0s, if necessary
///
List<double> sanitize(List<num> frames, int maxFrameSize) {
  final sanitized = frames.map((e) => e.toDouble()).toList();
  if (frames.length < maxFrameSize) {
    sanitized.addAll(List.filled(maxFrameSize - frames.length, 0.0));
  }
  return sanitized;
}
