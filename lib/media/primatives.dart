// import 'dart:isolate';
import 'dart:typed_data';
// import 'package:logging/logging.dart';

import 'storage.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

String get opencvInfo => cv.getBuildInformation();

/// Metadata for [UploadedMedia] to be used in the cache
///
class Meta {

  final String name;
  final String extension;
  final DateTime created;
  final DateTime modified;
  final String path;

  Meta(this.name, this.extension, this.created, this.modified, this.path);

  Map<String, dynamic> get map => {
    'name': name,
    'extension': extension,
    'created': created.toString(),
    'modified': modified.toString(),
    'path': path
  };

  @override
  String toString() => map.toString();

}

/// Media uploaded by the user
///
class UploadedMedia {
  late XFile xfile;
  DateTime created;
  DateTime lastModified = DateTime.now();

  UploadedMedia(this.xfile, this.created);

  UploadedMedia.fromBytes(Uint8List bytes, this.created, String pwd, String name) {
    xfile = XFileStorage.fromBytes(pwd, name, bytes).xfile;
  }

  Future<Uint8List> get asBytes async => await xfile.readAsBytes();

  String get path => xfile.path;

  Meta get meta => Meta(
    xfile.name,
    xfile.path.split('.').last,
    created,
    lastModified,
    xfile.path);

}
