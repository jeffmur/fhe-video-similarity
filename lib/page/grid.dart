import 'package:flutter/material.dart';
import 'package:flutter_fhe_video_similarity/media/manager.dart';
import 'package:flutter_fhe_video_similarity/media/cache.dart' show manifest;
import 'package:flutter_fhe_video_similarity/page/experiment.dart'
    show Experiment;
import 'package:flutter_fhe_video_similarity/page/thumbnail.dart'
    show ThumbnailWidget, OverlayWidget;

class SelectableGrid extends StatefulWidget {
  SelectableGrid({Key? key}) : super(key: key);

  @override
  State<SelectableGrid> createState() => _SelectableGridState();
}

class _SelectableGridState extends State<SelectableGrid> {
  List<bool> _selected = [];
  List<Thumbnail> render = [];

  @override
  void initState() {
    super.initState();
    _selected = List.filled(render.length, false);
  }

  void refreshState() {
    print("Refreshing state");
    setState(() {});
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
                const Text('Load'),
                OverflowBar(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        // Removal of all thumbnails
                        render.clear();
                        refreshState();

                        List<String> thumbnailPaths = manifest.paths
                            .where((path) => path.contains('thumbnail'))
                            .toList();

                        thumbnailPaths.forEach((path) async {
                          final thumbnail = await m.loadThumbnail(path);
                          render.add(thumbnail);
                          _selected = List.filled(render.length, false);
                          refreshState();
                        });
                      },
                    ),
                  ],
                ),
                // const SizedBox(width: 10),
                // const Text('Select'),
                // Checkbox(
                //   value: _allowMultiSelect,
                //   onChanged: (val) => setState(() => _allowMultiSelect = val!),
                // )
              ],
            ),
          ],
        ),
        body: GridView.count(
          crossAxisCount: 2,
          children: List.generate(render.length, (idx) {
            return OverlayWidget(
                onTap: () {
                  setState(() {
                    _selected[idx] = !_selected[idx];
                  });
                },
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
                    _selectImages(_selected, render, context, m),
                    const SizedBox(height: 10),
                    _upload(m, context, render, refreshState),
                  ]
                : [_upload(m, context, render, refreshState)]));
  }
}

Widget _upload(Manager m, BuildContext context, List<Thumbnail> render,
    Function setParentState) {
  return m.floatingSelectMediaFromGallery(MediaType.video, context,
      (xfile, timestamp, trimStart, trimEnd) async {
    // Cache the video + metadata
    // Targets: {sha256}/{start}-{end}-{timestamp}/raw.mp4
    //          {sha256}/{start}-{end}-{timestamp}/meta.json
    final video = Video(xfile, timestamp,
        start: Duration(seconds: trimStart), end: Duration(seconds: trimEnd));

    video.cache().then((value) {
      // Store the thumbnail
      // Target: {sha256}/{start}-{end}-{timestamp}/thumbnail.png
      final frame0 = Thumbnail(video, video.startFrame);
      frame0.cache().then((value) {
        render.add(frame0);
        setParentState();
      });
    });
  });
}

Widget _selectImages(List<bool> selected, List<Thumbnail> thumbnails,
    BuildContext context, Manager m) {
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
