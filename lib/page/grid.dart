import 'dart:ffi';
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_fhe_video_similarity/media/share_encryption_archive.dart';
import 'package:flutter_fhe_video_similarity/media/similarity.dart';
import 'package:flutter_fhe_video_similarity/media/storage.dart';
import 'package:flutter_fhe_video_similarity/media/manager.dart';
import 'package:flutter_fhe_video_similarity/media/cache.dart' show manifest;
import 'package:flutter_fhe_video_similarity/media/video.dart';
import 'package:flutter_fhe_video_similarity/page/experiment/compare.dart';
import 'package:flutter_fhe_video_similarity/page/experiment/share.dart';
import 'package:flutter_fhe_video_similarity/page/thumbnail.dart';
import 'package:flutter_fhe_video_similarity/media/video_encryption.dart';
import 'package:flutter_fhe_video_similarity/logging.dart';
import 'package:flutter_fhe_video_similarity/page/logs.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';
import 'package:video_player/video_player.dart';
import 'package:mime/mime.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:flutter_fhe_video_similarity/page/progress_button.dart';

class SelectableGrid extends StatefulWidget {
  const SelectableGrid({super.key});

  @override
  State<SelectableGrid> createState() => _SelectableGridState();
}

class _SelectableGridState extends State<SelectableGrid> {
  bool _allowMultiSelect = false;
  List<bool> _selected = List.empty(growable: true);
  List<Thumbnail> render = List.empty(growable: true);

  void clearRender() {
    setState(() {
      render.clear();
    });
  }

  void deleteThumbnailFromRender() {
  setState(() {
    if (render.isNotEmpty) {
      render.removeLast(); // Remove the last element from the render list
      _selected.removeLast(); // Remove the corresponding selection state
    }
  });
}

  void addThumbnailToRender(Thumbnail thumbnail) {
    setState(() {
      render.add(thumbnail);
      _selected.add(false); // grow the selected list
    });
  }

  void deselectAll() {
    setState(() {
      for (var i = 0; i < _selected.length; i++) {
        _selected[i] = false;
      }
    });
  }

  Future<void> _mockTask() async {
    // This is where you would implement the actual task.
    // For now, it just simulates a delay.
    await Future.delayed(const Duration(seconds: 10));
  }

  @override //ORIGINAL
  Widget build(BuildContext context) {
    Manager m = Manager();
    manifest.init();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GhostPeerShare',
          style: TextStyle(
            fontFamily: 'sans-serif',
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          textAlign: TextAlign.center,
        ),
        centerTitle: true, // Centers the title in the AppBar
        backgroundColor: const Color.fromARGB(255, 0, 172, 252),
        toolbarHeight: 80, // Adjust height to accommodate the centered title
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 0, 11, 71),
              Color.fromARGB(255, 2, 15, 87),
              Color.fromARGB(255, 2, 22, 134),
              Color.fromARGB(255, 4, 140, 182),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 0, 6, 36),
                    ),
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoggingPage()));
                    },
                    child: const Text(
                      'View Logs',
                      style: TextStyle(
                          fontFamily: 'SourceCodePro',
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 9, 226, 255)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Load',
                      style: TextStyle(
                          fontFamily: 'SourceCodePro',
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.refresh,
                        color: Color.fromARGB(255, 0, 204, 255)),
                    onPressed: () async {
                      clearRender();

                      List<String> thumbnailPaths = manifest.paths
                          .where((path) => path.contains('thumbnail'))
                          .toList();

                      for (var path in thumbnailPaths) {
                        final thumbnail = await m.loadThumbnail(path);
                        addThumbnailToRender(thumbnail);
                      }
                      deselectAll(); // using new thumbnails
                    },
                  ),
                  const SizedBox(width: 10),
                  const Text('Select',
                      style: TextStyle(
                          fontFamily: 'SourceCodePro',
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Checkbox(
                    value: _allowMultiSelect,
                    onChanged: (val) =>
                        setState(() => _allowMultiSelect = val!),
                    activeColor: const Color.fromARGB(255, 0, 172, 252),
                    checkColor: const Color.fromARGB(255, 197, 187, 187),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(8.0),
                children: List.generate(render.length, (idx) {
                  return OverlayWidget(
                    onTap: () {
                      if (_allowMultiSelect) {
                        setState(() {
                          _selected[idx] = !_selected[idx];
                        });
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ShareArchive(
                                      thumbnail: render[idx],
                                    )));
                      }
                    },
                    enableOverlay: _allowMultiSelect,
                    overlay: Container(
                      color: Colors.black
                          .withOpacity(0.5), // Semi-transparent background
                      child: const Center(
                        child: Text(
                          'Selected',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    child: ThumbnailWidget(thumbnail: render[idx]),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ProgressButton(
            onPressed: _mockTask,
            text: 'Progress',
          ),
          const SizedBox(height: 10),
          ..._selected.where((isTrue) => isTrue).length >= 2
              ? [
                  compareSelectedThumbnails(_selected, render, context, m),
                  const SizedBox(height: 10),
                  uploadVideo(m, context, addThumbnailToRender, deleteThumbnailFromRender),
                  const SizedBox(height: 10),
                  uploadZip(m, context, addThumbnailToRender)
                ]
              : [
                  uploadVideo(m, context, addThumbnailToRender, deleteThumbnailFromRender),
                  const SizedBox(height: 10),
                  uploadZip(m, context, addThumbnailToRender)
                ],
        ],
      ),
    );
  }
}

Future<void> handleUploadedVideo(XFile xfile, DateTime timestamp, int trimStart,
    int trimEnd, void Function(Thumbnail) renderAdd, Function renderDelete, BuildContext context) async {
  Logging log = Logging();
  DateTime start = DateTime.now();

  
  // Cache the video + metadata
  // Targets: {sha256}/{start}-{end}-{timestamp}/raw.mp4
  //          {sha256}/{start}-{end}-{timestamp}/meta.json
  // Get video duration
  final VideoPlayerController controller = VideoPlayerController.file(File(xfile.path));
  await controller.initialize();
  final videoDuration = controller.value.duration.inSeconds;
  await controller.dispose();

  // Validate trim values
  if (trimStart > videoDuration) {
    log.error('Trim start exceeds video duration');
    // Handle error: Show a message to the user or take other actions
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Trim start exceeds video duration'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (trimEnd > videoDuration) {
    log.error('Trim end exceeds video duration');
    // Handle error: Show a message to the user or take other actions
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Trim end exceeds video duration'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  final video = Video(xfile, timestamp,
      start: Duration(seconds: trimStart), end: Duration(seconds: trimEnd));
    final skeleton = SkeletonThumbnail(video: video);
    await skeleton.cache().then((_) {
      renderAdd(skeleton);
    });
  Duration processed = DateTime.now().difference(start);
  log.info(
      'Loaded Video in ${nonZeroDuration(processed)} ${video.stats.toString()}',
      correlationId: video.stats.id);
  await video.cache().then((value) {
    // Store the thumbnail
    // Target: {sha256}/{start}-{end}-{timestamp}/thumbnail.png
    final frame0 = Thumbnail(video, video.startFrame);
    frame0.cache().then((_) {
      renderDelete();
      renderAdd(frame0);
      Duration cached = DateTime.now().difference(start) - processed;
      log.info('Cached Video in ${nonZeroDuration(cached)}',
          correlationId: video.stats.id);
       ScaffoldMessenger.of(context).showSnackBar( 
        SnackBar( content: Text('Video sucessfully uploaded'), 
        backgroundColor: Colors.green, 
        ), 
        );
    });
  });
}

Future<void> handleUploadedZip(BuildContext context, XFile xfile, Manager m,
    void Function(Thumbnail) renderAdd) async {
  // Parse the zip file
  // Targets: {sha256}/{start}-{end}-{timestamp}/{PreprocessType}-{frameCount}-{SimilarityType}
  //          {sha256}/{start}-{end}-{timestamp}/meta.json\
  Logging log = Logging();
  DateTime start = DateTime.now();
  List<File> files = await ImportCiphertextVideoZip(
          extractDir: await ApplicationStorage('tmp').path,
          archivePath: xfile.path,
          manifest: m.manifest)
      .extractFiles();

  File metaFile = getFileByBasename(files, 'meta.json')!;
  VideoMeta meta = VideoMeta.fromFile(metaFile);
  files.remove(metaFile); // Remove meta file from list\

  final video = CiphertextVideo.fromBinaryFiles(files, m.session, meta);
  Duration processed = DateTime.now().difference(start);
  log.info(
      'Loaded CiphertextVideo in ${nonZeroDuration(processed)} ${video.stats.toString()}',
      correlationId: video.stats.id);

  // Check if ciphertext video has been modified, if so, decrypt and show score
  if (video.pwd.contains('modified')) {
    start = DateTime.now();
    double kldScore = m.session.decryptedSumOfDoubles(video.kld).abs();
    String kldScoreDuration = nonZeroDuration(DateTime.now().difference(start));
    log.metric('🔓 KLD Decrypted Score $kldScore took $kldScoreDuration',
        correlationId: video.stats.id);
    double kldPercentile = normalizedPercentage(SimilarityType.kld, kldScore);

    start = DateTime.now();
    double bhattacharyyaScore =
        m.session.decryptedSumOfDoubles(video.bhattacharyya).abs();
    String bhattacharyyaScoreDuration =
        nonZeroDuration(DateTime.now().difference(start));
    log.metric(
        '🔓 Bhattacharyya Decrypted Score $bhattacharyyaScore took $bhattacharyyaScoreDuration',
        correlationId: video.stats.id);
    double bhattacharyyaPercentile =
        normalizedPercentage(SimilarityType.bhattacharyya, bhattacharyyaScore);

    start = DateTime.now();
    double cramerScore =
        sqrt(m.session.decryptedSumOfDoubles(video.cramer).abs());
    String cramerScoreDuration =
        nonZeroDuration(DateTime.now().difference(start));
    log.metric(
        '🔓 Cramer Decrypted Score $cramerScore took $cramerScoreDuration',
        correlationId: video.stats.id);

    double cramerPercentile =
        normalizedPercentage(SimilarityType.cramer, cramerScore);
    // Ensure context is still valid before using Navigator
    if (!context.mounted) return;
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Decryption Results'),
          content: Table(
            columnWidths: const {
              0: FixedColumnWidth(100),
            },
            children: [
              const TableRow(
                children: [
                  Text('Metric'),
                  Text('Score'),
                  Text('Percentile'),
                ],
              ),
              TableRow(
                children: [
                  const Text('KLD'),
                  Text(kldScore.toStringAsFixed(2)),
                  Text(kldPercentile.toStringAsFixed(2)),
                ],
              ),
              TableRow(
                children: [
                  const Text('Bhattacharyya'),
                  Text(bhattacharyyaScore.toStringAsFixed(2)),
                  Text(bhattacharyyaPercentile.toStringAsFixed(2)),
                ],
              ),
              TableRow(
                children: [
                  const Text('Cramer'),
                  Text(cramerScore.toStringAsFixed(2)),
                  Text(cramerPercentile.toStringAsFixed(2)),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  } else {
    // Make available for comparison
    final thumbnail = CiphertextThumbnail(video: video, meta: meta);
    await thumbnail.cache().then((_) {
      renderAdd(thumbnail);
    });
  }
}

Widget uploadZip(
    Manager m, BuildContext context, Function(Thumbnail) renderAdd) {
  return m.floatingSelectMediaFromGallery(
    MediaType.zip,
    context,
    onXFileSelected: (xfile) => handleUploadedZip(context, xfile, m, renderAdd),
  );
}

Widget uploadVideo(
    Manager m, BuildContext context, Function(Thumbnail) renderAdd,  Function() renderDelete) {
  return m.floatingSelectMediaFromGallery(
    MediaType.video,
    context,
    onMediaSelected: (xfile, timestamp, trimStart, trimEnd) =>
        handleUploadedVideo(xfile, timestamp, trimStart, trimEnd, renderAdd, renderDelete, context),
  );
}

Widget compareSelectedThumbnails(List<bool> selected,
    List<Thumbnail> thumbnails, BuildContext context, Manager m) {
  return SizedBox(
    width: 125,
    height: 56,
    child: FloatingActionButton.extended(
      heroTag: 'experiment',
      backgroundColor: const Color.fromARGB(255, 0, 172, 252),
      splashColor: const Color.fromARGB(255, 210, 211, 214),
      icon: const Icon(Icons.compare_arrows, color: Color.fromARGB(255, 8, 0, 44)),
      label: const Text(
        'Compare',
        style: TextStyle(
          color: Color.fromARGB(255, 8, 0, 44),
          fontSize: 12, // Adjust text size
        ),
      ),
      onPressed: () {
        // Implement your logic for handling selected items here
        int selectedCount = selected.where((element) => element).length;
        if (selectedCount > 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.red,
              content: Text('Please select at most two items'),
            ),
          );
        } else {
          List<Thumbnail> selectedItems = [];
          for (int i = 0; i < selected.length; i++) {
            if (selected[i]) {
              selectedItems.add(thumbnails[i]);
            }
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Experiment(
                baseline: selectedItems[0],
                comparison: selectedItems[1],
              ),
            ),
          );
        }
      },
    ),
  );
}



