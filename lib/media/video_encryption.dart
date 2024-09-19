import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_fhe_video_similarity/media/primatives.dart';
import 'package:flutter_fhe_video_similarity/media/storage.dart';
import 'package:opencv_dart/opencv_dart.dart';

import 'image.dart';
import 'dart:convert';
import 'package:flutter/material.dart' as mat;
import 'package:flutter_fhe_video_similarity/media/cache.dart';

import 'seal.dart';
import 'video.dart';
import 'share_archive.dart';

export 'dart:io' show File;

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

class ExportModifiedCiphertextVideoZip extends ExportArchive {
  final List<Ciphertext> modifiedCiphertext;
  final VideoMeta meta;
  final String videoFilename = 'video.enc';
  final String metadataFilename = 'meta.json';

  ExportModifiedCiphertextVideoZip({
    required super.tempDir,
    required super.archivePath,
    required this.modifiedCiphertext,
    required this.meta,
  });

  @override
  Future<File> create() async {
    super.addFile(await serializeEncryptedFrames(
        modifiedCiphertext, tempDir, videoFilename));
    VideoMeta metaModified = meta;
    metaModified.encryptionStatus = 'modified';
    super.addFile(
        await serializeVideoMeta(metaModified, tempDir, metadataFilename));
    return super.create();
  }
}

class ExportCiphertextVideoZip extends ExportArchive {
  final List<double> frames;
  final Video ctVideo;
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
    VideoMeta meta = ctVideo.stats;
    meta.encryptionStatus = 'ciphertext';
    super.addFile(
        await serializeVideoMeta(meta, tempDir, metadataFilename));
    return super.create();
  }
}

class ImportCiphertextVideoZip extends ImportArchive {
  ImportCiphertextVideoZip({
    required super.archivePath,
    required super.extractDir,
    required Manifest manifest,
  });

  Future<VideoMeta> parseMetaData(File metaJson) async {
    return VideoMeta.fromFile(metaJson);
  }

  Future<List<File>> extractCiphertextVideo(File videoEnc) async {
    final vidArchive = ImportArchive(
        archivePath: videoEnc.path, extractDir: '$extractDir/bin');
    return vidArchive.extractFiles();
  }

  @override
  Future<List<File>> extractFiles() async {
    List<File> files = await super.extractFiles();
    VideoMeta meta = await parseMetaData(files
        .singleWhere((element) => element.path.split('/').last == 'meta.json'));

    String cachePath =
        '${meta.sha256}/${meta.startFrame}-${meta.endFrame}-${meta.created.millisecondsSinceEpoch}-${meta.encryptionStatus}';
    meta.path = cachePath;
    final List<int> metaBytes = utf8.encode(jsonEncode(meta.toJson())).toList();
    final metaCached = await manifest.write(metaBytes, cachePath, "meta.json");

    final List<File> bin = await extractCiphertextVideo(files
        .singleWhere((element) => element.path.split('/').last == 'video.enc'));

    final archiveName = archivePath.split('/').last.split('.').first;

    List<File> outBin = [];
    for (var f in bin) {
      List<int> bytes = await f.readAsBytes();
      var out = await manifest.write(
          bytes, '$cachePath/$archiveName', f.path.split('/').last);
      outBin.add(await out.file);
    }

    // Delete tmp directory
    await Directory(extractDir).delete(recursive: true);

    return [await metaCached.file, ...outBin];
  }
}

class CiphertextVideo extends UploadedMedia implements Video {
  List<Ciphertext> ctFrames;
  @override
  final VideoMeta meta;

  @override
  late VideoCapture video;

  @override
  late int startFrame;

  @override
  late int endFrame;

  @override
  late int totalFrames;

  @override
  late String hash;

  void init() {
    video = VideoCapture.empty();
    startFrame = 0;
    endFrame = frameCount;
    totalFrames = frameCount;
    hash = meta.sha256;
  }

  CiphertextVideo({required this.ctFrames, required this.meta})
      : super(XFile('${meta.path}/meta.json'), meta.created) {
    init();
  }

  /// We require a library pointer to import the [Ciphertext], I plan to update this later, as it is confusing
  /// to require the object rather than the library selection (seal)
  CiphertextVideo.fromBinaryFiles(
      List<File> binFiles, Session session, this.meta)
      : ctFrames = binFiles
            .map((f) => Ciphertext.fromBytes(session.seal, f.readAsBytesSync()))
            .toList(growable: false),
        super(XFile('${meta.path}/meta.json'), meta.created) {
    init();
  }

  @override
  get stats => meta;

  @override
  get duration => meta.duration;

  @override
  get fps => meta.fps;

  @override
  Future<void> cache() async {} // [ctFrames] are already cached

  @override
  int get frameCount => ctFrames.length;

  @override
  String get pwd => meta.path;

  @override
  void trim(Duration start, Duration end) {
    throw UnsupportedError('CiphertextVideo does not support trimming');
    // TODO: meta.segmentDuration, we can trim the video as the List<Ciphertext> is delimited by segmentDuration
  }

  @override
  Future<Image> thumbnail(String filename, [frameIdx = 0]) async {
    return Image.fromBytes(Uint8List(0), DateTime.now(), meta.path, filename);
  }

  @override
  Future<List<Uint8List>> frames(
      {List<int> frameIds = const [0], String frameFormat = 'png'}) async {
    return ctFrames.map((f) => f.toBytes()).toList();
  }

  @override
  Future<Uint8List> get asBytes async => Uint8List.fromList(
      ctFrames.map((f) => f.toBytes()).expand((e) => e).toList());
}

class CiphertextThumbnail implements Thumbnail {
  @override
  bool isCached = false;
  @override
  int frameIdx = 0;
  @override
  String filename = 'thumbnail.jpg';
  @override
  Video video;

  final VideoMeta meta;

  CiphertextThumbnail({required this.video, required this.meta});

  Uint8List get bytes => Uint8List(1);

  @override
  // Generate a black thumbnail, as tmp
  Future<Image> get image => Future.value(video.thumbnail(filename));

  @override
  Future<Uint8List> get cachedBytes => Future.value(bytes);

  @override
  Future<void> cache() async {
    await manifest.write(bytes, meta.path, filename);
    isCached = true;
  }

  @override
  Future<mat.Widget> get widget async => mat.Image.memory(bytes);
}
