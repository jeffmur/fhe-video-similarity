import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<String> get path async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$primaryKey';
  }
}

class XFileStorage extends ApplicationStorage {
  String parentDir;
  XFile xfile;

  XFileStorage(this.parentDir, this.xfile) : super(parentDir);

  @override
  Future<String> get path async {
    final path = await super.path;
    return '$path/${xfile.name}';
  }

  Future<File> get file async {
    return File(await path);
  }

  Future<File> write() async {
    Directory parent = await Directory(await super.path).create();
    print('Wrote parent directory: ${parent.path}');
    final file = await this.file;
    return file.writeAsBytes(await xfile.readAsBytes());
  }
}
