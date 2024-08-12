import 'package:flutter/material.dart';
import 'package:flutter_fhe_video_similarity/media/video.dart' show Thumbnail;

// Widget for displaying / interacting with a thumbnail
// Ideally, this widget would be used in a grid view, and reusable based
/* HomePage workflow ideas:
 ** - Tap to select
 ** - Long press to prompt options
 ** - Double tap to open video (with native player)
*/

class ThumbnailWidget extends StatefulWidget {
  final Thumbnail thumbnail;
  final Function(Thumbnail) onTap;
  final Function(Thumbnail) onLongPress;
  final Function(Thumbnail) onDoubleTap;
  final Function(Thumbnail) onPreprocess;

  ThumbnailWidget({
    Key? key,
    required this.thumbnail,
    required this.onTap,
    required this.onLongPress,
    required this.onDoubleTap,
    required this.onPreprocess,
  }) : super(key: key);

  @override
  State<ThumbnailWidget> createState() => _ThumbnailWidgetState();
}

class _ThumbnailWidgetState extends State<ThumbnailWidget> {
  void refreshState() {
    print("Refreshing state");
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onTap(widget.thumbnail),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () => widget.onPreprocess(widget.thumbnail),
            child: const Text('Preprocess'),
          ),
        ],
      ),
    );
  }
}

// Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => ThumbnailWidget(
//               thumbnail: selectedItems[0],
//               onTap: (x) => {},
//               onPreprocess: (x) => m.storeProcessedVideoCSV(selectedItems[0].video, PreprocessType.sso),
//             ),
//           ),
//         );