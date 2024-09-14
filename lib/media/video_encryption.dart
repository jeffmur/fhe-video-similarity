import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart'; // For creating/extracting ZIP archives
import 'package:crypto/crypto.dart'; // For hashing/HMAC
import 'seal.dart';
import 'video.dart';
import 'manager.dart';

class ShareArchive {
  final String archivePath;

  ShareArchive({required this.archivePath});

  // Create an archive from files
  Future<void> create(Map<String, File> files) async {
    final archive = Archive();

    for (var entry in files.entries) {
      final file = entry.value;
      final fileBytes = await file.readAsBytes();
      final compressedData = _compressData(fileBytes);

      // Add encrypted file to the archive
      archive.addFile(
          ArchiveFile(entry.key, compressedData.length, compressedData));
    }

    // Write the archive to disk
    final zipData = ZipEncoder().encode(archive);
    final outputFile = File(archivePath);
    await outputFile.writeAsBytes(zipData!);
  }

  // Extract files from the archive
  Future extract() async {
    final zipFile = File(archivePath);
    final archiveData = zipFile.readAsBytesSync();
    final archive = ZipDecoder().decodeBytes(archiveData);

    final extractedFiles = <String, List<int>>{};
    for (var file in archive.files) {
      if (!file.isFile) continue;

      // Decompress file data
      final decompressedData = _decompressData(file.content);

      extractedFiles[file.name] = decompressedData;
    }
    return extractedFiles;
  }

  // Private method to compress data
  List<int> _compressData(List<int> data) {
    return GZipEncoder().encode(data)!;
  }

  // Private method to decompress data
  List<int> _decompressData(List<int> data) {
    return GZipDecoder().decodeBytes(data);
  }
}

class CiphertextVideo {
  final Video video;
  final DateTime startTime;
  final DateTime endTime;
  final String hash;

  CiphertextVideo({
    required this.video,
    required this.startTime,
    required this.endTime,
    required this.hash,
  });

  Future<File> serializeVideoFile(String filename, Session session,
      List<double> frames) async {
    List<Ciphertext> ciphertext = session.encryptVecDouble(frames);
    // Create video.enc
    final videoEnc = File(filename);
    // Encode each Ciphertext as base64 string
    final videoData =
        ciphertext.map((c) => base64Encode(c.toBytes())).join('\n');
    return await videoEnc.writeAsBytes(utf8.encode(videoData));
  }

  Future<File> metadataFile(String filename) async {
    final metadata = {
      'start': startTime.toIso8601String(),
      'end': endTime.toIso8601String(),
      'hash': hash,
    };
    final metadataFile = File(filename);
    return await metadataFile.writeAsString(jsonEncode(metadata));
  }
}

class ShareCiphertextVideoArchive extends ShareArchive {
  final List<double> frames;
  final CiphertextVideo ctVideo;
  final Session session;
  final String videoFilename = 'video.enc';
  final String metadataFilename = 'meta.json';

  ShareCiphertextVideoArchive({
    required this.frames,
    required this.ctVideo,
    required super.archivePath,
    required this.session,
  });

  @override
  Future<void> create(Map<String, File> files) async {
    // Add video file to the archive
    files[videoFilename] =
        await ctVideo.serializeVideoFile(videoFilename, session, frames);
    // Add metadata file to the archive
    files[metadataFilename] = await ctVideo.metadataFile(metadataFilename);
    await super.create(files);
  }

  @override
  Future extract() async {
    final extractedFiles = await super.extract();
    final videoData = extractedFiles[videoFilename]!;
    final metadataData = extractedFiles[metadataFilename]!;
    final metadata = jsonDecode(utf8.decode(metadataData));
    return {videoFilename: videoData, metadataFilename: metadata};
  }
}