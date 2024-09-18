import 'dart:io';
import 'dart:convert';
import 'package:flutter_fhe_video_similarity/media/cache.dart';

import 'seal.dart';
import 'video.dart';
import 'share_archive.dart';

export 'dart:io' show File;

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
}

List<Ciphertext> encryptVideoFrames(Session session, List<double> frames) {
  return session.encryptVecDouble(frames);
}

Future<File> serializeEncryptedFrames(
    List<Ciphertext> ciphertext, String path, String filename) async {
  // Create Ciphertext Archieve (video.enc) containing each enc segment
  final ctArchive =
      ExportArchive(tempDir: '$path/bin', archivePath: '$path/$filename');
  for (var i = 0; i < ciphertext.length; i++) {
    final ct = ciphertext[i];
    File ctFile = File('$path/bin/$i.bin');
    await ctFile.writeAsBytes(ct.toBytes());
    ctArchive.addFile(ctFile);
  }
  return ctArchive.create();
}

Future<File> serializeVideoMeta(
    VideoMeta meta, String parentDir, String filename) async {
  final outFile = File('$parentDir/$filename');
  await outFile.writeAsString(jsonEncode(meta.toJson()));
  return outFile;
}

class ExportCiphertextVideoZip extends ExportArchive {
  final List<double> frames;
  final CiphertextVideo ctVideo;
  final Session session;
  final String videoFilename = 'video.enc';
  final String metadataFilename = 'meta.json';

  ExportCiphertextVideoZip({
    required super.tempDir,
    required super.archivePath,
    required this.frames,
    required this.ctVideo,
    required this.session,
  });

  @override
  Future<File> create() async {
    super.addFile(await serializeEncryptedFrames(
        encryptVideoFrames(session, frames), tempDir, videoFilename));
    super.addFile(await serializeVideoMeta(
        ctVideo.video.stats, tempDir, metadataFilename));
    return super.create();
  }
}

class ImportCiphertextVideoZip extends ImportArchive {
  ImportCiphertextVideoZip({
    required super.archivePath,
    required super.extractDir,
    required Manifest manifest,
  });

  Future<VideoMeta> parseMetaData() async {
    final tmpMetaFile = File('$extractDir/meta.json');
    return VideoMeta.fromJson(jsonDecode(await tmpMetaFile.readAsString()));
  }

  Future<List<File>> extractCiphertextVideo() async {
    final vidArchive = ImportArchive(
        archivePath: '$extractDir/video.enc', extractDir: '$extractDir/bin');
    return vidArchive.extractFiles();
  }

  @override
  Future<List<File>> extractFiles() async {
    super.extract();
    VideoMeta meta = await parseMetaData();

    String cachePath =
        '${meta.sha256}/${meta.startFrame}-${meta.endFrame}-${meta.created.millisecondsSinceEpoch}-enc';

    final List<int> metaBytes = utf8.encode(jsonEncode(meta.toJson())).toList();
    await manifest.write(metaBytes, cachePath, "meta.json");

    final List<File> bin = await extractCiphertextVideo();

    List<File> outBin = [];
    for (var f in bin) {
      List<int> bytes = await f.readAsBytes();
      var out = await manifest.write(bytes, '$cachePath/bin', f.path.split('/').last);
      outBin.add(await out.file);
    }

    // Delete tmp directory
    await Directory(extractDir).delete(recursive: true);

    return [File('$cachePath/meta.json'),...outBin];
  }
}
