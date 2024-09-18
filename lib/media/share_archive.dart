import 'dart:io';
import 'package:archive/archive_io.dart';

class ExportArchive {
  final String tempDir;
  final String archivePath;
  List<File> files = [];

  ExportArchive({
    this.tempDir = 'tmp',
    this.archivePath = 'archive.zip',
  }) {
    Directory(tempDir).createSync();
  }

  void addFile(File file) => files.add(file);

  Future<File> create() async {
    final archive = ZipFileEncoder();
    archive.create(archivePath);

    for (var file in files) {
      archive.addFile(file);
    }
    await archive.close();
    return File(archivePath);
  }
}

class ImportArchive {
  final String extractDir;
  final String archivePath;

  ImportArchive({
    required this.archivePath,
    this.extractDir = 'tmp'
  });

  Future<void> extract() async {
    final inputStream = InputFileStream(archivePath);
    final archive = ZipDecoder().decodeBuffer(inputStream);
    for (var file in archive.files) {
      final outputStream = OutputFileStream('$extractDir/${file.name}');
      file.writeContent(outputStream);
      outputStream.close();
    }
  }

  Future<List<File>> extractFiles() async {
    extract();
    return Directory(extractDir).list().map((e) => File(e.path)).toList();
  }
}
