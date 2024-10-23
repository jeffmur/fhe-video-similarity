import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:opencv_dart/opencv_dart.dart' as cv;

/// Get the OpenCV API preference based on the platform
///
int get cvApiPreference {
  if (Platform.isAndroid) {
    return cv.CAP_ANDROID;
  }
  else {
    return cv.CAP_FFMPEG;
  }
}

/// Step through the video frame by frame and count the number of frames
///
/// Exposing this method to the user is not recommended as it is slow and
/// inefficient. Use [frameCount] instead.
///
int countAllFrames(String videoPath) {
  // Create + Release video copy
  final copy = cv.VideoCapture.fromFile(videoPath);
  var frames = 0;
  var (success, _) = copy.read();
  while (success) {
    frames += 1;
    (success, _) = copy.read();
  }
  copy.release();
  return frames;
}

/// Calculate the number of frames in the video
///
/// The number of frames is calculated using the CAP_PROP_FRAME_COUNT property
/// of the video. If the property is not supported by the codec, the number of
/// frames is calculated manually.
///
int frameCount(String videoPath) {
  // Create + Release video copy
  final copy = cv.VideoCapture.fromFile(videoPath);
  final frames = copy.get(cv.CAP_PROP_FRAME_COUNT).toInt();
  copy.release();

  // CAP_PROP_FRAME_COUNT is not supported by all codecs
  if (frames == 0) {
    return countAllFrames(videoPath);
  }
  return frames;
}

class FrameIsolate {
  final List<int> frameIds;
  final String videoPath;
  String frameFormat = 'png';

  FrameIsolate(this.frameIds, this.videoPath);
}

Future<List<Uint8List>> extractFrames(FrameIsolate args) async {
  final bytes = <Uint8List>[];

  // Open the video file in the isolate
  final copy = await cv.VideoCaptureAsync.fromFileAsync(args.videoPath,
      apiPreference: cvApiPreference);
  var success = await copy.grabAsync();
  if (!copy.isOpened || args.frameIds.isEmpty || !success) return [];

  var idx = 0;
  // Iterate through 0..N inclusively, assumes frameIds are sorted
  while (success && idx <= args.frameIds.last) {
    if (args.frameIds.contains(idx)) {
      var (exist, image) = await copy.readAsync();
      if (!image.isEmpty) {
        bytes.add((await cv.imencodeAsync(".${args.frameFormat}", image)).$2);
      }
    }
    success = await copy.grabAsync();
    idx += 1;
  }
  await copy.releaseAsync();

  return bytes;
}

/// Extract the frame sizes of the video
///
Future<List<int>> extractFrameSizes(FrameIsolate args) async {
  final sizes = <int>[];

  // Open the video file in the isolate
  final copy = await cv.VideoCaptureAsync.fromFileAsync(args.videoPath,
      apiPreference: cvApiPreference);
  var success = await copy.grabAsync();
  if (!copy.isOpened || args.frameIds.isEmpty || !success) return [];

  var idx = 0;
  // Iterate through 0..N inclusively, assumes frameIds are sorted
  while (success && idx <= args.frameIds.last) {
    if (args.frameIds.contains(idx)) {
      var (exist, image) = await copy.readAsync();
      if (!image.isEmpty) {
        var frameData =
            (await cv.imencodeAsync(".${args.frameFormat}", image)).$2;
        sizes.add(frameData.length);
      }
    }
    success = await copy.grabAsync();
    idx += 1;
  }
  await copy.releaseAsync();
  return sizes;
}


Future<List<int>> probeFrameSizes(FrameIsolate args) async {
  return await Isolate.run(() => extractFrameSizes(args));
}

Future<List<Uint8List>> probeFrames(FrameIsolate args) async {
  return await Isolate.run(() => extractFrames(args));
}
