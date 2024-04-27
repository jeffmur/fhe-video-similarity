import 'package:flutter/material.dart';
import 'package:flutter_fhe_video_similarity/media/manager.dart';

void main() {
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var images = <Thumbnail>[];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Manager m = Manager();
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Packages'),
        ),
        floatingActionButton: m.floatingSelectMediaFromGallery(
          MediaType.video, context, (vid, timestamp, trimStart, trimEnd) async {
            final stored = await m.storeVideo(vid);
            final video = Video(stored.xfile, timestamp,
              start: Duration(seconds: trimStart),
              end: Duration(seconds: trimEnd));

            final meta = await m.storeVideoMetadata(video, timestamp);
            print("Wrote metafile: ${meta.name}");
            
            Thumbnail frame0 = Thumbnail(video, 0);
            images.add(frame0);
            // Thumbnail frame1 = Thumbnail(video, 1);
            // images.add(frame1);
            setState(() { }); // Rebuild the widget
          }
        ),
        body: Container(
          alignment: Alignment.center,
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: images.length,
                        itemBuilder: (ctx, idx) => Card(child:
                          Column(children: [
                            images[idx].widget,
                            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text("Duration: ${images[idx].video.duration.inSeconds} seconds"),
                              Text("Created: ${images[idx].video.created.toLocal()}")                              
                            ]),
                          ],
                        )),
                      ),
                    ),

                    // m.backendInfoWidget,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
