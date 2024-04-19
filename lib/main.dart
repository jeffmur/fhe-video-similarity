// ignore_for_file: avoid_print

import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:flutter_fhe_video_similarity/media/primatives.dart' show Video;

import 'package:flutter_fhe_video_similarity/media/storage.dart';
import 'package:flutter_fhe_video_similarity/media/uploader.dart';


// def frame_count(video_path, manual=False):
//     def manual_count(handler):
//         frames = 0
//         while True:
//             status, frame = handler.read()
//             if not status:
//                 break
//             frames += 1
//         return frames 

//     cap = cv2.VideoCapture(video_path)
//     # Slow, inefficient but 100% accurate method 
//     if manual:
//         frames = manual_count(cap)
//     # Fast, efficient but inaccurate method
//     else:
//         try:
//             frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
//         except:
//             frames = manual_count(cap)
//     cap.release()
//     return frames

Future<int> frameCountManual(cv.VideoCapture video) async {
  var frames = 0;
  var (success, _) = video.read();
  while (success) {
    frames += 1;
    (success, _) = video.read();
  }
  print("Manual Frame count: $frames");
  return frames;
}

Future<int> frameCount(cv.VideoCapture video) async {
  final frames = video.get(cv.CAP_PROP_FRAME_COUNT).toInt();

  // CAP_PROP_FRAME_COUNT is not supported by all codecs
  if (frames == 0) {
    return frameCountManual(video);
  }
  print("Frame count: $frames");
  return frames;
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var images = <Uint8List>[];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  // native resources are unsendable for isolate, so use raw data or encoded Uint8List and convert back
  Future<(Uint8List, Uint8List)> heavyTask(Uint8List buffer) async {
    final ret = Isolate.run(() {
      final im = cv.imdecode(Uint8List.fromList(buffer), cv.IMREAD_COLOR);
      late cv.Mat gray, blur;
      for (var i = 0; i < 1000; i++) {
        gray = cv.cvtColor(im, cv.COLOR_BGR2GRAY);
        blur = cv.gaussianBlur(im, (7, 7), 2, sigmaY: 2);
      }
      return (cv.imencode(cv.ImageFormat.png.ext, gray), cv.imencode(cv.ImageFormat.png.ext, blur));
    });
    return ret;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Packages'),
        ),
        floatingActionButton: selectVideoFromGallery(context, (vid) async {
          final storedVideo = XFileStorage.fromXFile(vid);
          await storedVideo.write();

          final video = Video(storedVideo.xfile);
          setState(() async {
            images.add(await video.thumbnail.buffer);
          }); // Rebuild the widget
        }),
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
                          child: Image.memory(images[idx]),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(cv.getBuildInformation()),
                      ),
                    ),
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
