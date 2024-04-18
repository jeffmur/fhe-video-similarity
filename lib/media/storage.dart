import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

/// A class that uses the application file system to store data.
/// 
/// Provide a shared template to interface with asynchronous file operations.
abstract class ApplicationStorage {

  ApplicationStorage();

  Future<File> get file;

  Future<String> get path async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
}

class XFileStorage extends ApplicationStorage {
  late XFile xfile;
  // List<String> get supportedFormats => supportedExtensions;

  XFileStorage.fromXFile(this.xfile) {
    // if (!supportedFormats.contains(xfile.path.split('.').last)) {
    //   throw UnsupportedError('Unsupported file format');
    // }
    // write().then((value) => print('File written to: ${value.path}'));
  }

  @override
  Future<String> get path async {
    final path = await super.path;
    return '$path/${xfile.name}';
  }

  @override
  Future<File> get file async {
    return File(await path);
  }

  Future<File> write() async {
    final file = await this.file;
    return file.writeAsBytes(await xfile.readAsBytes());
  }
}
