
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

  OriginalData(String csv) {
    final lines = csv.split('\n');
    for (var line in lines) {
      final parts = line.split(',');
      final frames = parts.sublist(1).map(int.parse).toList();
      final obj = OneMinuteVideo(parts.first, frames);
      parts.first == 'Video' ? videos.add(obj) : pcaps.add(obj);
    }
  }
}
