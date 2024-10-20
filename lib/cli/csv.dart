import 'dart:io';
import 'dart:math';

class Row {
  final String dtype;
  final List<int> frames;
  Row(this.dtype, this.frames);
}

class OneMinuteVideo extends Row {
  OneMinuteVideo(super.label, super.frames);

  /// Sum of 1 second segments' frames
  /// Normalize each segment by the sum of all frames (between 0 and 1)
  ///
  List<double> normalize({int fps=10}) {

    // Sum of each segment (groups of fps)
    final sumOfFrameSegments = List<int>.generate(frames.length ~/ fps, (i) {
      final start = i * fps;
      final end = start + fps;
      return frames.sublist(start, end).reduce((a, b) => a + b);
    });

    // Normalize each segment with the sum of ALL elements
    final sum = sumOfFrameSegments.reduce((value, element) => value + element);
    // Normalize the values between 0 and 1
    return sumOfFrameSegments.map((e) => e / sum).toList();
  }
}

class OriginalData {
  List<OneMinuteVideo> videos = [];
  List<OneMinuteVideo> pcaps = [];

  OriginalData(String filename) {
    final lines = File(filename).readAsLinesSync();
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];
      final parts = line.split(',');
      final frames = parts.sublist(1).map(int.parse).toList();
      final obj = OneMinuteVideo(parts.first, frames);
      parts.first == 'Video' ? videos.add(obj) : pcaps.add(obj);
    }
  }
}

class ScoreData {
  List<double> kldDart = [];
  List<double> kldSSO = [];
  List<double> cramerDart = [];
  List<double> cramerSSO = [];

  ScoreData(String filename) {
    final lines = File(filename).readAsLinesSync();
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];
      final parts = line.split(',');
      kldDart.add(double.parse(parts[0]));
      cramerDart.add(double.parse(parts[1]));
      kldSSO.add(double.parse(parts[2]));
      cramerSSO.add(double.parse(parts[3]));
    }
  }

  Map<String, List<double>> get scores => {
    'kldDart': kldDart,
    'kldSSO': kldSSO,
    'cramerDart': cramerDart,
    'cramerSSO': cramerSSO,
  };

  double standardDeviation(List<double> list) {
    final mean = list.reduce((a, b) => a + b) / list.length;
    final variance = list.map((e) => (e - mean) * (e - mean)).reduce((a, b) => a + b) / list.length;
    return variance;
  }

  /// Similarity between two sets, between 0 and 1
  ///
  double jaccord(Set dart, Set sso) {
    final intersection = dart.intersection(sso).length;
    final union = dart.union(sso).length;

    return intersection / union; // Similarity score between 0 and 1
  }

  /// Similarity between two lists, between 0 and 1
  ///
  double cosine(List<double> v1, List<double> v2) {
    double dotProduct = 0.0;
    double magnitudeA = 0.0;
    double magnitudeB = 0.0;

    for (int i = 0; i < v1.length; i++) {
      dotProduct += v1[i] * v2[i];
      magnitudeA += pow(v1[i], 2);
      magnitudeB += pow(v2[i], 2);
    }

    if (magnitudeA == 0 || magnitudeB == 0) {
      return 0.0; // Cannot compute similarity with zero magnitude
    }

    return dotProduct / (sqrt(magnitudeA) * sqrt(magnitudeB));
  }
}