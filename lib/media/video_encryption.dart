import 'dart:io';
import 'dart:convert';
import 'seal.dart';
import 'video.dart';
import 'share_archive.dart';

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
      ShareArchive(tempDir: '$path/bin', basename: '$path/$filename');
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

class ShareCiphertextVideoArchive extends ShareArchive {
  final List<double> frames;
  final CiphertextVideo ctVideo;
  final Session session;
  final String videoFilename = 'video.enc';
  final String metadataFilename = 'meta.json';

  ShareCiphertextVideoArchive({
    required super.tempDir,
    required super.basename,
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
