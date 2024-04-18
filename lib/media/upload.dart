// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';

export 'package:image_picker/image_picker.dart' show ImageSource, XFile;

Future<XFile> selectImage(ImageSource source) async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: source);
  return image!;
}

Future<XFile> selectVideo(ImageSource source) async {
  final ImagePicker picker = ImagePicker();
  final XFile? video = await picker.pickVideo(source: source);
  return video!;
}

// Future<void> openImage(BuildContext context, Function parentCallback) async {
//   const XTypeGroup allTypeGroup = XTypeGroup(
//     label: 'Any',
//     extensions: supportedExtensions,
//   );
//   final List<XFile> files = await openFiles(
//     acceptedTypeGroups: <XTypeGroup>[
//       allTypeGroup
//     ]
//   );
//   // #enddocregion MultiOpen
//   if (files.isEmpty) {
//     // Operation was canceled by the user.
//     return;
//   }
//   if (context.mounted) {
//     for (final XFile file in files) {
//       // Generate thumbnail from video
      

//       // Save thumbnail to storage
//       XFileStorage.fromXFile(file)
//         .write().then((File file) {
//           print("Thumbnail saved to ${file.path}");
//           parentCallback();
//         });
//     }
//   }
// }

// /// Screen that shows an example of openFiles
// class OpenMultipleImagesPage extends StatelessWidget {
//   /// Default Constructor
//   const OpenMultipleImagesPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Open multiple images'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blue,
//                 foregroundColor: Colors.white,
//               ),
//               child: const Text('Press to open multiple images (png, jpg)'),
//               onPressed: () => openImage(context, ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// Widget that displays a text file in a dialog
// class MultipleImagesDisplay extends StatelessWidget {
//   /// Default Constructor
//   const MultipleImagesDisplay(this.files, {super.key});

//   /// The files containing the images
//   final List<XFile> files;

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('Gallery'),
//       // On web the filePath is a blob url
//       // while on other platforms it is a system path.
//       content: Center(
//         child: Row(
//           children: <Widget>[
//             ...files.map(
//               (XFile file) => Flexible(
//                   child: kIsWeb
//                       ? Image.network(file.path)
//                       : Image.file(File(file.path))),
//             )
//           ],
//         ),
//       ),
//       actions: <Widget>[
//         TextButton(
//           child: const Text('Close'),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//       ],
//     );
//   }
// }
