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
                ButtonBar(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () {
                        // Removal of all thumbnails
                        render.clear();

                        List<String> thumbnailPaths = manifest.paths.where((path) 
                          => path.contains('thumbnail')).toList();

                        thumbnailPaths.forEach((path) async {
                          final thumbnail = await m.loadThumbnail(path);
                          render.add(thumbnail);
                          refreshState();
                          _selected = List.filled(render.length, false);
                        });
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
            return GridTile(
                child: Column(children: [
              FutureBuilder<Widget>(
                  future: render[idx].widget,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return snapshot.data!;
                    }
                    else if (snapshot.hasError) {
                      return Text('Error loading image: ${snapshot.error}');
                    } else {
                      return const CircularProgressIndicator();
                    }
              }),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                Text("Duration: ${render[idx].video.duration}"),
                Text("Created: ${render[idx].video.created.toLocal()}"),
                // Create a checkbox, visible only if multi-select is enabled
                if (_allowMultiSelect)
                  Checkbox(
                    value: _selected[idx],
                    onChanged: (val) {
                      setState(() {
                        _selected[idx] = val!;
                      });
                    },
                  )
              ])
            ]));
          }),
        ),
        floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: _allowMultiSelect
                ? [
                    _upload(m, context, render, refreshState),
                    const SizedBox(height: 10),
                    _selectImages(_selected, render, context, m),
                  ]
                : [
                    _upload(m, context, render, refreshState)
                  ]
        )
    );
  }
}

Widget _upload(Manager m, BuildContext context, List<Thumbnail> render, Function setParentState) {
  return m.floatingSelectMediaFromGallery(MediaType.video, context,
    (xfile, timestamp, trimStart, trimEnd) async {

    // Cache the video + metadata
    // Targets: {sha256}/{start}-{end}-{timestamp}/raw.mp4
    //          {sha256}/{start}-{end}-{timestamp}/meta.json
    final video = Video(
      xfile, timestamp,
      start: Duration(seconds: trimStart),
      end: Duration(seconds: trimEnd));

    video.cache();

    // Store the thumbnail
    // Target: {sha256}/{start}-{end}-{timestamp}/thumbnail.png
    final frame0 = Thumbnail(video, 0);
    frame0.cache();

    // Add the thumbnail to the render list
    render.add(frame0);
    setParentState();
  });
}

Widget _selectImages(
    List<bool> selected, List<Thumbnail> thumbnails, BuildContext context, Manager m,
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
