import 'package:flutter/material.dart';
import 'package:flutter_fhe_video_similarity/media/manager.dart';

void main() {
  runApp(const MyApp());
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
          MediaType.video, context, (vid) async {
            final stored = await m.storeVideo(vid);

            final video = Video(stored.xfile, const Duration(seconds: 2));
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
                        itemBuilder: (ctx, idx) => Card(
                          child: images[idx].widget,
                        ),
                      ),
                    ),
                    m.backendInfoWidget,
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
