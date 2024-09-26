import 'dart:io';
import 'dart:math' as math;

import 'dart:convert';
import 'package:flutter_fhe_video_similarity/logging.dart';
import 'package:flutter_fhe_video_similarity/media/cache.dart';

import 'seal.dart';
import 'video.dart';
import 'share_archive.dart';

export 'dart:io' show File;

/// Retrieve file by name from List of files
///
File? getFileByBasename(List<File> files, String basename) {
  try {
    return files
        .singleWhere((element) => element.path.split('/').last == basename);
  } catch (e) {
    return null;
  }
}

/// Generate an archive containing the encrypted frames (i.bin)
///
Future<File> serializeEncryptedFrames(
    List<Ciphertext> x, String path, String filename,
    {String outDir = 'bin'}) async {
  // Create Ciphertext Archieve (video.enc) containing each enc segment
  final ctArchive =
      ExportArchive(tempDir: '$path/$outDir', archivePath: '$path/$filename');
  for (var i = 0; i < x.length; i++) {
    final ct = x[i];
    File ctFile = File('$path/$outDir/$i.bin');
    await ctFile.writeAsBytes(ct.toBytes());
    ctArchive.addFile(ctFile);
  }
  return ctArchive.create();
}

/// Write the video metadata to a json file
///
Future<File> serializeVideoMeta(
    VideoMeta meta, String parentDir, String filename) async {
  final outFile = File('$parentDir/$filename');
  await outFile.writeAsString(jsonEncode(meta.toJson()));
  return outFile;
}

/// Step 1: Export the ciphertext video archive
///
class ExportCiphertextVideoZip extends ExportArchive {
  final List<double> frames;
  final Video ctVideo;
  final Session session;
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
    Logging log = Logging();
    DateTime start = DateTime.now();
    final cipherX = session.encryptVecDouble(frames);
    Duration encryptTime = DateTime.now().difference(start);
    log.metric(
        '🔒 Encrypted ${frames.length} frames in ${nonZeroDuration(encryptTime)}',
        correlationId: ctVideo.stats.id);

    start = DateTime.now();
    // Kullback-Leibler Divergence (kld.enc, kld_log.enc)
    await serializeEncryptedFrames(cipherX, tempDir, 'kld.enc').then((file) {
      super.addFile(file);
      Duration kldTime = DateTime.now().difference(start);
      Duration kldTotal = kldTime + encryptTime;
      log.metric(
          '📄 Added kld.enc in ${nonZeroDuration(kldTotal)} '
          '(${nonZeroDuration(kldTime)} + ${nonZeroDuration(encryptTime)})',
          correlationId: ctVideo.stats.id);
    });
    start = DateTime.now();
    final cipherLogX = session.encryptVecDouble(frames.map(math.log).toList());
    Duration encryptLogTime = DateTime.now().difference(start);
    log.metric(
        '🔒 Encrypted ${frames.length} log frames in ${nonZeroDuration(encryptLogTime)}',
        correlationId: ctVideo.stats.id);

    start = DateTime.now();
    await serializeEncryptedFrames(cipherLogX, tempDir, 'kld_log.enc')
        .then((file) {
      super.addFile(file);
      Duration kldLogTime = DateTime.now().difference(start);
      Duration kldLogTotal = kldLogTime + encryptLogTime;
      log.metric(
          '📄 Added kld_log.enc in ${nonZeroDuration(kldLogTotal)} '
          '(${nonZeroDuration(kldLogTime)} + ${nonZeroDuration(encryptLogTime)})',
          correlationId: ctVideo.stats.id);
    });

    start = DateTime.now();
    final cipherSqrtX =
        session.encryptVecDouble(frames.map(math.sqrt).toList());
    Duration encryptSqrtTime = DateTime.now().difference(start);
    log.metric(
        '🔒 Encrypted ${frames.length} sqrt frames in ${nonZeroDuration(encryptSqrtTime)}',
        correlationId: ctVideo.stats.id);

    // Bhattacharyya Distance (bhattacharyya_sqrt.enc)
    start = DateTime.now();
    await serializeEncryptedFrames(
            cipherSqrtX, tempDir, 'bhattacharyya_sqrt.enc')
        .then((file) {
      super.addFile(file);
      Duration bhattacharyyaTime = DateTime.now().difference(start);
      Duration bhattacharyyaTotal = bhattacharyyaTime + encryptSqrtTime;
      log.metric(
          '📄 Added bhattacharyya_sqrt.enc in ${nonZeroDuration(bhattacharyyaTotal)} '
          '(${nonZeroDuration(bhattacharyyaTime)} + ${nonZeroDuration(encryptSqrtTime)})',
          correlationId: ctVideo.stats.id);
    });

    // Cramer's Distance (cramer.enc)
    start = DateTime.now();
    await serializeEncryptedFrames(cipherX, tempDir, 'cramer.enc').then((file) {
      super.addFile(file);
      Duration cramerTime = DateTime.now().difference(start);
      Duration cramerTotal = cramerTime + encryptTime;
      log.metric(
          '📄 Added cramer.enc in ${nonZeroDuration(cramerTotal)} '
          '(${nonZeroDuration(cramerTime)} + ${nonZeroDuration(encryptTime)})',
          correlationId: ctVideo.stats.id);
    });

    // Metadata
    start = DateTime.now();
    VideoMeta meta = ctVideo.stats;
    meta.encryptionStatus = 'ciphertext';
    super.addFile(await serializeVideoMeta(meta, tempDir, metadataFilename));
    Duration metaTime = DateTime.now().difference(start);
    log.info('📄 Added meta.json in ${nonZeroDuration(metaTime)}',
        correlationId: ctVideo.stats.id);
    return super.create();
  }
}

/// Step 2: Import the ciphertext video archive
///
class ImportCiphertextVideoZip extends ImportArchive {
  ImportCiphertextVideoZip({
    required super.archivePath,
    required super.extractDir,
    required Manifest manifest,
  });

  Future<VideoMeta> parseMetaData(File metaJson) async {
    return VideoMeta.fromFile(metaJson);
  }

  Future<List<File>> extractCiphertextVideo(File videoEnc,
      {String extractSubDir = 'bin'}) async {
    final vidArchive = ImportArchive(
        archivePath: videoEnc.path, extractDir: '$extractDir/$extractSubDir');
    return vidArchive.extractFiles();
  }

  Future<List<File>> addFilesToManifest(
      List<File> files, String cachePath) async {
    List<File> inManifest = [];
    for (var f in files) {
      List<int> bytes = await f.readAsBytes();
      var out = await manifest.write(bytes, cachePath, f.path.split('/').last);
      inManifest.add(await out.file);
    }
    return inManifest;
  }

  @override
  Future<List<File>> extractFiles() async {
    List<File> files = await super.extractFiles();
    File metaFile = getFileByBasename(files, 'meta.json')!;

    VideoMeta meta = await parseMetaData(metaFile);
    files.remove(metaFile); // Remove meta.json from files

    String cachePath = '${meta.sha256}/'
        '${meta.startFrame}-'
        '${meta.endFrame}-'
        '${meta.created.millisecondsSinceEpoch}-'
        '${meta.encryptionStatus}';

    // Write updated meta.json to manifest (cache)
    meta.path = cachePath;
    final List<int> metaBytes = utf8.encode(jsonEncode(meta.toJson())).toList();
    final metaCached = await manifest.write(metaBytes, cachePath, "meta.json");

    // KLD, KLD_LOG
    final kld_enc = getFileByBasename(files, 'kld.enc');
    final kld = await addFilesToManifest(
        await extractCiphertextVideo(kld_enc!, extractSubDir: 'kld'),
        '$cachePath/kld');
    final kld_log_enc = getFileByBasename(files, 'kld_log.enc');
    List<File>? kld_log;
    if (kld_log_enc != null) {
      kld_log = await addFilesToManifest(
          await extractCiphertextVideo(kld_log_enc, extractSubDir: 'kld_log'),
          '$cachePath/kld_log');
    }

    final bhattacharyya_sqrt_enc =
        getFileByBasename(files, 'bhattacharyya_sqrt.enc');
    final bhattacharyya = await addFilesToManifest(
        await extractCiphertextVideo(bhattacharyya_sqrt_enc!,
            extractSubDir: 'bhattacharyya'),
        '$cachePath/bhattacharyya');

    final cramer_enc = getFileByBasename(files, 'cramer.enc');
    final cramer = await addFilesToManifest(
        await extractCiphertextVideo(cramer_enc!, extractSubDir: 'cramer'),
        '$cachePath/cramer');

    // Delete tmp directory
    await Directory(extractDir).delete(recursive: true);

    return [
      await metaCached.file,
      ...kld,
      ...?kld_log,
      ...bhattacharyya,
      ...cramer
    ];
  }
}

/// Step 3: Export the modified ciphertexts video archive
///
class ExportModifiedCiphertextVideoZip extends ExportArchive {
  final Map<String, List<Ciphertext>> scores;
  final VideoMeta meta;

  ExportModifiedCiphertextVideoZip({
    required super.tempDir,
    required super.archivePath,
    required this.scores,
    required this.meta,
  });

  @override
  Future<File> create() async {
    VideoMeta metaModified = meta;
    print('Exporting modified ciphertext video archive');
    metaModified.encryptionStatus = 'modified';
    super.addFile(await serializeVideoMeta(metaModified, tempDir, 'meta.json'));

    // KLD (kld.enc)
    if (scores.containsKey('kld')) {
      super.addFile(
          await serializeEncryptedFrames(scores['kld']!, tempDir, 'kld.enc'));
    }
    // Bhattacharyya Distance (bhattacharyya_sqrt.enc)
    if (scores.containsKey('bhattacharyya')) {
      super.addFile(await serializeEncryptedFrames(
          scores['bhattacharyya']!, tempDir, 'bhattacharyya_sqrt.enc'));
    }
    // Cramer's Distance (cramer.enc)
    if (scores.containsKey('cramer')) {
      super.addFile(await serializeEncryptedFrames(
          scores['cramer']!, tempDir, 'cramer.enc'));
    }

    return super.create();
  }
}
