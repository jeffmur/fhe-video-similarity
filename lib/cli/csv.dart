import 'dart:io';

class Row {
  final String dtype;
  final List<num> frames;
  Row(this.dtype, this.frames);
}

class OneMinuteVideo extends Row {
  OneMinuteVideo(super.label, super.frames);

  /// Sum of 1 second segments' frames
  /// Normalize each segment by the sum of all frames (between 0 and 1)
  ///
  List<double> normalize({int fps=10}) {

    // Sum of each segment (groups of fps)
    final sumOfFrameSegments = List<num>.generate(frames.length ~/ fps, (i) {
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
  List<OneMinuteVideo> normalized = [];

  OriginalData(String filename) {
    final lines = File(filename).readAsLinesSync();
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i];
      final parts = line.split(',');
      parts.removeWhere((element) => element.isEmpty);

      // Attempt to parse values as integers, then fall back to doubles if necessary
      final frames = parts.sublist(1).map((value) {
        if (value.contains('.')) {
          return double.parse(value);
        } else {
          return int.parse(value);
        }
      }).toList();

      final obj = OneMinuteVideo(parts.first, frames);
      if (parts.first.startsWith('Video')) {
        videos.add(obj);
      }
      else if (parts.first.startsWith('Pcap')) {
        pcaps.add(obj);
      }
      else if (parts.first.startsWith('Normalized')) {
        normalized.add(obj);
      }
      else {
        throw UnsupportedError('Unknown dtype: ${parts.first}');
      }
    }
  }
}
