import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

import 'primatives.dart';

export 'package:image_picker/image_picker.dart' show XFile;

/// A class that provides a template to store data.
///
/// Provide a shared template to interface with asynchronous file operations.
///
abstract class Storage {
  String primaryKey;
  Storage(this.primaryKey);

  Future<String> get path;
}

/// A class that provides a template to store data in the application directory.
///
/// Provide a shared template to interface with asynchronous file operations in the application directory.
/// Stored in OS-specific application directory.
class ApplicationStorage extends Storage {
  ApplicationStorage(super.primaryKey);

  @override
  Future<String> get path async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$primaryKey';
  }
}

class XFileStorage extends ApplicationStorage {
  String parentDir; // parent directory
  String name; // name of the file
  late XFile xfile; // the file content to store

  XFileStorage(this.parentDir, this.name, this.xfile) : super(parentDir);

  XFileStorage.fromBytes(this.parentDir, this.name, List<int> bytes)
      : super(parentDir) {
    xfile = XFile.fromData(Uint8List.fromList(bytes), name: name);
  }

  @override
  Future<String> get path async {
    final path = await super.path;
    return '$path/$name';
  }

  Future<File> get file async {
    return File(await path);
  }

  Future<Uint8List> readAsBytes() async {
    return await xfile.readAsBytes();
  }

  Future<File> write() async {
    await Directory(await super.path).create(recursive: true); // If needed
    final file = await this.file;
    return file.writeAsBytes(await xfile.readAsBytes());
  }

  Future<bool> exists() async {
    return (await file).exists();
  }
}

/// Media uploaded by the user
///
class UploadedMedia {
  late XFile xfile;
  DateTime created;
  DateTime lastModified = DateTime.now();

  UploadedMedia(this.xfile, this.created);

  UploadedMedia.fromBytes(
      Uint8List bytes, this.created, String pwd, String name) {
    xfile = XFileStorage.fromBytes(pwd, name, bytes).xfile;
  }

  Future<Uint8List> get asBytes async => await xfile.readAsBytes();

  String get path => xfile.path;

  Meta get meta => Meta(xfile.name, xfile.path.split('.').last, created,
      lastModified, xfile.path);
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
