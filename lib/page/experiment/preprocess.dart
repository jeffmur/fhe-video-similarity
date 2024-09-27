import 'package:flutter/material.dart';
import 'package:flutter_fhe_video_similarity/logging.dart';
import 'package:provider/provider.dart';
import 'package:flutter_fhe_video_similarity/media/video.dart';
import 'package:flutter_fhe_video_similarity/media/manager.dart' show Manager;
import 'package:flutter_fhe_video_similarity/media/processor.dart';
import 'package:flutter_fhe_video_similarity/media/video_encryption.dart';
import 'package:flutter_fhe_video_similarity/page/load_button.dart';
import 'package:flutter_fhe_video_similarity/page/experiment/encrypt.dart';

/// Used for preprocessing byte array for Cramer
///
List<double> cumulativeSum(List<double> list) {
  List<double> result = [];
  double sum = 0;
  for (var i = 0; i < list.length; i++) {
    sum += list[i];
    result.add(sum);
  }
  return result;
}

class Config {
  PreprocessType type;
  FrameCount frameCount;
  int startFrame;
  int endFrame;
  bool isEncrypted;
  bool isEncryptionDisabled;
  SessionChanges encryptionSettings;

  Config(this.type, this.frameCount, this.startFrame, this.endFrame,
      {this.isEncrypted = false,
      this.isEncryptionDisabled = false,
      required this.encryptionSettings});
}

List<Widget> videoInfo(Video video) {
  return [
    Text("sha256: ${video.hash}"),
    Text("Created: ${video.created}"),
    Text("Duration: ${video.duration} seconds"),
    Text("Frame Range: "
        "${video.startFrame} - "
        "${video.endFrame} of "
        "${video.totalFrames}"),
    Text("Encoding: ${video.stats.codec}"),
  ];
}

class PreprocessForm extends StatefulWidget {
  final Thumbnail thumbnail;
  final Config config;
  final Function() onFormSubmit;
  final Function(Config) onConfigChange;
  final Function() onVideoTrim;

  const PreprocessForm({
    super.key,
    required this.thumbnail,
    required this.onFormSubmit,
    required this.onVideoTrim,
    required this.onConfigChange,
    required this.config,
  });

  @override
  State<PreprocessForm> createState() => PreprocessFormState();
}

class PreprocessFormState extends State<PreprocessForm> {
  final Manager _manager = Manager();
  bool isCached = false;
  late RangeValues frameRange;
  late double lowerLimit;
  late double upperLimit;

  @override
  void initState() {
    super.initState();
    _reloadCache();
    refreshSlider();
    upperLimit = widget.config.endFrame.toDouble();
    lowerLimit = widget.config.startFrame.toDouble();
  }

  void _reloadCache() {
    setState(() {
      isCached = _manager.isProcessed(
          widget.thumbnail.video, widget.config.type, widget.config.frameCount);
    });
  }

  void refreshSlider() {
    setState(() {
      frameRange = RangeValues(
        widget.thumbnail.video.startFrame.toDouble(),
        widget.thumbnail.video.endFrame.toDouble(),
      );
    });
  }

  bool isImportedCiphertextComparison() {
    return widget.thumbnail.video is CiphertextVideo;
  }

  Widget preprocessTypeDropdown() {
    return DropdownButton<PreprocessType>(
      value: widget.config.type,
      onChanged: (PreprocessType? value) {
        setState(() {
          widget.config.type = value!;
          widget.onConfigChange(widget.config);
          _reloadCache();
        });
      },
      items: PreprocessType.values
          .map((type) => DropdownMenuItem(
                value: type,
                child: Text(type.toString()),
              ))
          .toList(),
    );
  }

  Widget frameSlider() {
    // Calculate the total number of seconds in the video based on FPS
    int fps = widget.thumbnail.video.fps;

    return RangeSlider(
      values: RangeValues(
        frameRange.start / fps,  // Convert frames to seconds
        frameRange.end / fps,    // Convert frames to seconds
      ),
      min: lowerLimit / fps,     // Convert frames to seconds
      max: upperLimit / fps,     // Convert frames to seconds
      divisions: (upperLimit - lowerLimit).toInt() ~/ fps,  // Use second-based divisions
      labels: RangeLabels(
        '${(frameRange.start / fps).round()}s',  // Display seconds
        '${(frameRange.end / fps).round()}s',    // Display seconds
      ),
      onChanged: (RangeValues values) {
        setState(() {
          // Convert the seconds back to frames, ensuring whole-second adjustments
          frameRange = RangeValues(
            (values.start * fps).round().toDouble(),
            (values.end * fps).round().toDouble(),
          );
        });
      },
      onChangeEnd: (RangeValues values) {
        setState(() {
          // Convert seconds back to frames and update start/end frames
          widget.thumbnail.video.startFrame = (values.start * fps).round().toInt();
          widget.thumbnail.video.endFrame = (values.end * fps).round().toInt();
          widget.onVideoTrim();
          _reloadCache();
        });
      },
      onChangeStart: (RangeValues values) {
        setState(() {
          widget.thumbnail.video.startFrame = (values.start * fps).round().toInt();
          widget.thumbnail.video.endFrame = (values.end * fps).round().toInt();
          widget.onVideoTrim();
          _reloadCache();
        });
      },
    );
  }

  Widget frameCountDropdown() {
    return DropdownButton<FrameCount>(
      value: widget.config.frameCount,
      onChanged: (FrameCount? value) {
        setState(() {
          widget.config.frameCount = value!;
          widget.onConfigChange(widget.config);
          _reloadCache();
        });
      },
      items: FrameCount.values
          .map((frameCount) => DropdownMenuItem(
                value: frameCount,
                child: Text(frameCount.toString()),
              ))
          .toList(),
    );
  }

  Future<void> process() async {
    DateTime start = DateTime.now();
    try {
      await _manager.storeProcessedVideoCSV(
        widget.thumbnail.video,
        widget.config.type,
        widget.config.frameCount,
      );
    } on UnsupportedError catch (_) {
      // TODO: Show error message?
      Logging().error("Unsupported PreprocessType: ${widget.config.type.name}");
    } finally {
      setState(() {
        _reloadCache();
        widget.onFormSubmit();
        String took = nonZeroDuration(DateTime.now().difference(start));
        Logging().metric(
            "⚙️ Processed in $took {"
            "type: ${widget.config.type.name}, "
            "frameCount: ${widget.config.frameCount.name}, "
            "durationSeconds: ${widget.thumbnail.video.duration.inSeconds}, "
            "frameRange: ${widget.thumbnail.video.startFrame} - ${widget.thumbnail.video.endFrame} "
            "}",
            correlationId: widget.thumbnail.video.stats.id);
      });
    }
  }

  Widget submit() {
    return LoadButton(
      onPressed: process,
      text: "Preprocess",
    );
  }

  Widget status() {
    return Row(
      children: [
        isCached
            ? const Icon(Icons.check, color: Colors.green) // Green checkmark
            : const Icon(Icons.close, color: Colors.red) // Red X
      ],
    );
  }

  Widget encryptionPage(SessionChanges session) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Checkbox(
          value: widget.config.isEncrypted,
          onChanged: widget.config.isEncryptionDisabled
              ? null
              : (bool? value) {
                  setState(() {
                    widget.config.isEncrypted = value!;
                    widget.onConfigChange(widget.config);
                  });
                },
        ),
        Expanded(
          child: ListTile(
            leading: const Icon(Icons.lock),
            title: Text('Encrypt? ${widget.config.isEncrypted}'),
            subtitle: const Text('Tap to configure encryption settings'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => EncryptionSettings(session: session)),
              );
            },
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SessionChanges(),
      child: Form(
        child: Column(
          children: isImportedCiphertextComparison()
              ? [
                  frameSlider(),
                ]
              : [
                  encryptionPage(widget.config.encryptionSettings),
                  frameSlider(),
                  preprocessTypeDropdown(),
                  frameCountDropdown(),
                  const SizedBox(height: 5),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [submit(), const SizedBox(width: 5), status()])
                ],
        ),
      ),
    );
  }
}
