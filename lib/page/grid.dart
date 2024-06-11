import 'package:flutter/material.dart';
import 'package:flutter_fhe_video_similarity/media/manager.dart';
import 'package:flutter_fhe_video_similarity/media/cache.dart' show manifest;

class SelectableGrid extends StatefulWidget {

  SelectableGrid({Key? key}) : super(key: key);

  @override
  State<SelectableGrid> createState() => _SelectableGridState();
}

class _SelectableGridState extends State<SelectableGrid> {
  List<bool> _selected = [];
  bool _allowMultiSelect = false;
  List<Thumbnail> items = [];

  @override
  void initState() {
    super.initState();
    _selected = List.filled(items.length, false);
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
                ButtonBar(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        // items = m.loadThumbnails();
                        print(manifest.map.keys.toList());
                        refreshState();
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
          children: List.generate(items.length, (idx) {
            return GridTile(
                child: Column(children: [
              items[idx].widget,
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                Text("Duration: ${items[idx].video.duration}"),
                Text("Created: ${items[idx].video.created.toLocal()}"),
                ButtonBar(children: [
                  IconButton(
                    icon: const Icon(Icons.compare_outlined),
                    onPressed: () {
                      m.storeProcessedVideoCSV(items[idx].video, PreprocessType.sso);
                    }
                  ),
                ]
            ),
              ])
            ]));
          }),
        ),
        floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: _allowMultiSelect
                ? [
                    _upload(m, context, items, refreshState),
                    const SizedBox(height: 10),
                    _selectImages(_selected, items, context),
                  ]
                : [
                    _upload(m, context, items, refreshState)
                  ]
        )
    );
  }
}

Widget _upload(Manager m, BuildContext context, List<Thumbnail> images,
    Function setParentState) {
  return m.floatingSelectMediaFromGallery(MediaType.video, context,
      (vid, timestamp, trimStart, trimEnd) async {
    final raw = await m.storeRawVideo(vid, timestamp);
    print("Wrote video: ${raw.name}");
    final video = Video(
      raw.xfile, timestamp,
      start: Duration(seconds: trimStart),
      end: Duration(seconds: trimEnd));

    final meta = await m.storeVideoMetadata(video);
    print("Wrote metafile: ${meta.name}");
    
    final frame0 = Thumbnail(video, 0);
    final thumbnail = await m.storeThumbnail(frame0);
    print("Wrote thumbnail: ${thumbnail.name}");
    images.add(frame0);

    setParentState();
  });
}

Widget _selectImages(
    List<bool> selected, List<Thumbnail> thumbnails, BuildContext context,
    {int amount = 2}) {
  return FloatingActionButton(
    child: const Icon(Icons.check),
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
        // Do something with the selected items (e.g., print them)
        List<Thumbnail> selectedItems = [];
        for (int i = 0; i < selected.length; i++) {
          if (selected[i]) {
            selectedItems.add(thumbnails[i]);
          }
        }
        print('Selected Items: $selectedItems');
      }
    },
  );
}
