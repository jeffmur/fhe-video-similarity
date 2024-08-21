// import 'dart:isolate';
import 'dart:typed_data';
// import 'package:logging/logging.dart';

import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'primatives.dart';
import 'video.dart';

Uint8List resize(Uint8List bytes, ImageFormat format, int length, int width) {
  final im = cv.imdecode(bytes, cv.IMREAD_COLOR);
  final thumb = cv.resize(im, (length, width), interpolation: cv.INTER_AREA);

  // Replace the image with the new thumbnail
  return cv.imencode(".${format.name}", thumb).$2;
}

class Image extends UploadedMedia {
  ImageFormat format = ImageFormat.png;

  Image(super.file, super.timestamp);

  void printStats() {
    print('--- Image Information ---');
    print(' * Name: ${xfile.name}');
    print(' * Created: ${created.toLocal()}');
    print(' * Last Modified: ${lastModified.toLocal()}');
  }

  Image.fromBytes(super.bytes, super.timestamp, super.pwd, super.name)
      : super.fromBytes();
}
