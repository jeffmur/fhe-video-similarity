import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    Manager m = Manager();
    manifest.init();
    return Scaffold(
        appBar: AppBar(
          title: const Text('GhostPeerShare'),
          actions: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => LoggingPage()));
                  },
                  child: const Text('View Logs'),
                ),
                const SizedBox(width: 10),
                const Text('Load'),
                OverflowBar(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
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
                  ],
                ),
                const SizedBox(width: 10),
                const Text('Select'),
                Checkbox(
                  value: _allowMultiSelect,
                  onChanged: (val) => setState(() => _allowMultiSelect = val!),
                )
              ],
            ),
          ],
        ),
        body: GridView.count(
          crossAxisCount: 2,
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
                child: ThumbnailWidget(thumbnail: render[idx]));
          }),
        ),
        floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: _selected.where((isTrue) => isTrue).length >= 2
                ? [
                    compareSelectedThumbnails(_selected, render, context, m),
                    const SizedBox(height: 10),
                    uploadVideo(m, context, addThumbnailToRender),
                    const SizedBox(height: 10),
                    uploadZip(m, context, addThumbnailToRender)
                  ]
                : [
                    uploadVideo(m, context, addThumbnailToRender),
                    const SizedBox(height: 10),
                    uploadZip(m, context, addThumbnailToRender)
                  ]));
  }
}

Future<void> handleUploadedVideo(XFile xfile, DateTime timestamp, int trimStart,
    int trimEnd, void Function(Thumbnail) renderAdd) async {
  // Cache the video + metadata
  // Targets: {sha256}/{start}-{end}-{timestamp}/raw.mp4
  //          {sha256}/{start}-{end}-{timestamp}/meta.json
  final video = Video(xfile, timestamp,
      start: Duration(seconds: trimStart), end: Duration(seconds: trimEnd));

  video.cache().then((value) {
    // Store the thumbnail
    // Target: {sha256}/{start}-{end}-{timestamp}/thumbnail.png
    final frame0 = Thumbnail(video, video.startFrame);
    frame0.cache().then((_) {
      renderAdd(frame0);
    });
  });
}

Future<void> handleUploadedZip(BuildContext context, XFile xfile, Manager m,
    void Function(Thumbnail) renderAdd) async {
  // Parse the zip file
  // Targets: {sha256}/{start}-{end}-{timestamp}/{PreprocessType}-{frameCount}-{SimilarityType}
  //          {sha256}/{start}-{end}-{timestamp}/meta.json
  List<File> files = await ImportCiphertextVideoZip(
          extractDir: await ApplicationStorage('tmp').path,
          archivePath: xfile.path,
          manifest: m.manifest)
      .extractFiles();

  File metaFile = getFileByBasename(files, 'meta.json')!;
  VideoMeta meta = VideoMeta.fromFile(metaFile);
  files.remove(metaFile); // Remove meta file from list\

  final video = CiphertextVideo.fromBinaryFiles(files, m.session, meta);

  // Check if ciphertext video has been modified, if so, decrypt and show score
  if (video.pwd.contains('modified')) {
    double kldScore = m.session.decryptedSumOfDoubles(video.kld).abs();
    double kldPercentile = normalizedPercentage(SimilarityType.kld, kldScore);

    double bhattacharyyaScore =
        m.session.decryptedSumOfDoubles(video.bhattacharyya).abs();
    double bhattacharyyaPercentile =
        normalizedPercentage(SimilarityType.bhattacharyya, bhattacharyyaScore);

    double cramerScore = m.session.decryptedSumOfDoubles(video.cramer).abs();
    double cramerPercentile =
        normalizedPercentage(SimilarityType.cramer, cramerScore);
    // Ensure context is still valid before using Navigator
    if (!context.mounted) return;
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Decryption Results'),
          content: Column(
            children: [
              Text('KLD Score: $kldScore'),
              Text('KLD Percentile: $kldPercentile'),
              Text('Bhattacharyya Score: $bhattacharyyaScore'),
              Text('Bhattacharyya Percentile: $bhattacharyyaPercentile'),
              Text('Cramer Score: $cramerScore'),
              Text('Cramer Percentile: $cramerPercentile'),
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
    thumbnail.cache().then((_) {
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
    Manager m, BuildContext context, Function(Thumbnail) renderAdd) {
  return m.floatingSelectMediaFromGallery(
    MediaType.video,
    context,
    onMediaSelected: (xfile, timestamp, trimStart, trimEnd) =>
        handleUploadedVideo(xfile, timestamp, trimStart, trimEnd, renderAdd),
  );
}

Widget compareSelectedThumbnails(List<bool> selected,
    List<Thumbnail> thumbnails, BuildContext context, Manager m) {
  return FloatingActionButton(
    heroTag: 'experiment',
    child: const Icon(Icons.compare_arrows),
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
  );
}
