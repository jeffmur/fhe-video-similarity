// import 'dart:isolate';
import 'dart:typed_data';
import 'dart:convert';
import 'cache.dart' show manifest;
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

  Map toJson() => {
    'name': name,
    'extension': extension,
    'created': created.toIso8601String(),
    'modified': modified.toIso8601String(),
    'path': path
  };

  Meta.fromJSON(Map<String, dynamic> json) : this(
    json['name'],
    json['extension'],
    DateTime.parse(json['created']),
    DateTime.parse(json['modified']),
    json['path']
  );

  void cache(String pwd) {
    // Store the metadata as UTF-8 encoded JSON
    final List<int> bytes = utf8.encode(jsonEncode(toJson())).toList();
    manifest.write(bytes, pwd, "meta.json");
  }

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

dynamic resolveNestedValue(Map<String, dynamic> json, List<String> keyPath) {
  dynamic current = json;

  for (String key in keyPath) {
    if (current is Map && current.containsKey(key)) {
      current = current[key];
    } else {
      return null; // Key not found at some level
    }
  }

  return current;
}
