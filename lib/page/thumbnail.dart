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
  // final Function(Thumbnail) onTap;
  // final Function(Thumbnail) onLongPress;
  // final Function(Thumbnail) onDoubleTap;

  const ThumbnailWidget({
    super.key,
    required this.thumbnail,
    // required this.onTap,
    // required this.onLongPress,
    // required this.onDoubleTap,
  });

  @override
  State<ThumbnailWidget> createState() => _ThumbnailWidgetState();
}

class _ThumbnailWidgetState extends State<ThumbnailWidget> {
  final textStyle = const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: Colors.white,
      backgroundColor: Colors.grey);
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // onTap: () => widget.onTap(widget.thumbnail),
      child: GridTile(
          header: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            Text("Duration: ${widget.thumbnail.video.duration}",
                style: textStyle),
            Text("Created: ${widget.thumbnail.video.created.toLocal()}",
                style: textStyle)
          ]),
          child: Wrap(spacing: 8.0, children: [
            FutureBuilder<Widget>(
                future: widget.thumbnail.widget,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return snapshot.data!;
                  } else if (snapshot.hasError) {
                    return Text('Error loading image: ${snapshot.error}');
                  } else {
                    return const CircularProgressIndicator();
                  }
                }),
          ])),
    );
  }
}

// Overlay Widget on top of thumbnail
class OverlayWidget extends StatefulWidget {
  final Widget child;
  final Widget overlay;
  final Function onTap;

  const OverlayWidget({
    super.key,
    required this.child,
    required this.overlay,
    required this.onTap,
  });

  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> {
  bool showBanner = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onTap();
        setState(() {
          showBanner = !showBanner; // Toggle banner visibility on tap
        });
      },
      child: Stack(
        children: [
          Container(
            color: Colors
                .transparent, // Optional background color for the container

            child: Center(
              child: widget.child,
            ),
          ),
          if (showBanner)
            Center(
              child: widget.overlay,
            ),
        ],
      ),
    );
  }
}
