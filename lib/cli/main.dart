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
import 'package:args/args.dart';
import 'csv.dart';
import 'similarity.dart';

double average(List<double> list) {
  return list.reduce((a, b) => a + b) / list.length;
}


/* Supported Use Cases:
  1. In-place comparison of each Video to complementary Pcap (same csv)
    * Compare distance measure implementation vs. SSO
    * KLD, Bhattacharyya, Cramer

  2. Exhaustive comparison of each row to every other row in another csv (used for ANN training)

*/
void main(List<String> args) {
  final parser = ArgParser()
    ..addOption('csv', abbr: 'f', help: 'CSV File to compare')
    ..addOption('versus', abbr: 'v', help: 'Compare against another CSV file')
    ..addOption('output', abbr: 'o', help: 'Output file for results')
    ..addFlag('pcap', abbr: 'p', help: 'Compare Video to Pcap', negatable: false)
    ..addFlag('exhaustive', abbr: 'e', help: 'Exhaustive comparison of each row to every other row', negatable: false)
    ..addFlag('help', abbr: 'h', help: 'Show help', negatable: false);

  final results = parser.parse(args);

  if (results['help']) {
    print(parser.usage);
    exit(0);
  }

  /*
    Exhausitve one-file distance measure of each row to every other row.

    SSO vs. Dart implementation of KLD, Cramer
  */
  if(results['versus'] == null && results['pcap']) {
    final data = OriginalData(File(results['csv']).readAsStringSync());
    List<double> kld = [];
    List<double> cramer = [];

    for (var i = 0; i < data.videos.length; i++) {
      final v = data.videos[i].normalize();
      final p = data.pcaps[i].normalize();
      kld.add(Similarity(SimilarityType.kld).score(v, p));
      cramer.add(Similarity(SimilarityType.cramer).score(v, p));
    }

    // Check if output file is specified
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
  
}
