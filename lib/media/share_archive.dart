import 'dart:io';
import 'package:archive/archive_io.dart';

class ShareArchive {
  final String tempDir;
  final String basename;
  List<File> files = [];

  ShareArchive({
    this.tempDir = 'tmp',
    this.basename = 'archive.zip',
  }) {
    Directory(tempDir).createSync();
  }

  void addFile(File file) => files.add(file);

  Future<File> create() async {
    final archive = ZipFileEncoder();
    archive.create(basename);

    for (var file in files) {
      archive.addFile(file);
    }
    await archive.close();
    return File(basename);
  }
}
