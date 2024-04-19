// import 'dart:isolate';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart' show XFile;
import 'package:opencv_dart/opencv_dart.dart' as cv;

class Media {
  XFile file;
  Media(this.file);

  String get path => file.path;

  Future<Uint8List> get buffer async => await file.readAsBytes();
}

class Thumbnail extends Media {

  Thumbnail(super.file);

  // TODO: preview image as pop up?
  
}

class Video extends Media {
  late cv.VideoCapture video;
  late Thumbnail thumbnail;
  
  Video(super.file) {
    video = cv.VideoCapture.fromFile(file.path);
    thumbnail = Thumbnail(XFile.fromData(
      thumbnailFromFrame(
        videoFrames().first)
    ));
  }

  /// Step through the video frame by frame and count the number of frames
  ///
  /// Exposing this method to the user is not recommended as it is slow and
  /// inefficient. Use [frameCount] instead.
  ///
  int _frameCountManual() {
    // Create + Release video copy
    final copy = cv.VideoCapture.fromFile(file.path);
    var frames = 0;
    var (success, _) = copy.read();
    while (success) {
      frames += 1;
      (success, _) = copy.read();
    }
    print("Manual Frame count: $frames");
    copy.release();
    return frames;
  }

  /// Calculate the number of frames in the video
  /// 
  /// The number of frames is calculated using the CAP_PROP_FRAME_COUNT property
  /// of the video. If the property is not supported by the codec, the number of
  /// frames is calculated manually.
  ///
  int frameCount() {
    final frames = video.get(cv.CAP_PROP_FRAME_COUNT).toInt();

    // CAP_PROP_FRAME_COUNT is not supported by all codecs
    if (frames == 0) {
      return _frameCountManual();
    }
    print("Frame count: $frames");
    return frames;
  }

  /// Generate a thumbnail from the video
  /// 
  /// The thumbnail is generated from a frame [buffer] of the video
  ///
  Uint8List thumbnailFromFrame(Uint8List buffer, {(int, int) size = (500, 500)}) {
    // final ret = Isolate.run(() {
    //   final im = cv.imdecode(buffer, cv.IMREAD_COLOR);
    //   final thumb = cv.resize(im, size, interpolation: cv.INTER_AREA);
    //   return cv.imencode(cv.ImageFormat.png.ext, thumb);
    // });
    // return ret;
    // thumbnail = Image(XFile.fromData(await ret));
    final im = cv.imdecode(buffer, cv.IMREAD_COLOR);
    final thumb = cv.resize(im, size, interpolation: cv.INTER_AREA);
    return cv.imencode(cv.ImageFormat.png.ext, thumb);
  }

  /// Extract frames from the video
  ///
  /// Encode frames at the specified [frameIds], by default, extract 
  /// the first frame, the frame at 1/4, 1/2, and 3/4 of the video length.
  ///
  List<Uint8List> videoFrames(
    {List<int> frameIds = const [0],
     cv.ImageFormat frameFormat = cv.ImageFormat.png}) {

    var frames = <Uint8List>[];
    int length = frameIds.length; // Length of the video

    if (length <= 1) {

      frameIds = [0, length ~/ 4, length ~/ 2, 3 * length ~/ 4];
    }

    if (video.isOpened & (length > 0)) {
      var count = 0;
      var (success, image) = video.read();
      while (success) {
        if (frameIds.contains(count)) {
          print("[videoFrames] Reading Frame $count");
          frames.add(
            cv.imencode(frameFormat.ext, image), // Mat -> Uint8List
          );
        }
        (success, image) = video.read();
        count += 1;
      }
    }
    // Clear the video buffer
    video.release();
    return frames;
  }
}
