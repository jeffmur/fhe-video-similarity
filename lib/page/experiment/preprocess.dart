import 'package:flutter/material.dart';
import 'package:flutter_fhe_video_similarity/media/video.dart';
import 'package:flutter_fhe_video_similarity/media/manager.dart' show Manager;
import 'package:flutter_fhe_video_similarity/media/processor.dart';
import 'package:flutter_fhe_video_similarity/page/load_button.dart';
import 'package:flutter_fhe_video_similarity/page/experiment/validator.dart';

class Config {
  PreprocessType type;
  FrameCount frameCount;
  int startFrame;
  int endFrame;

  Config(this.type, this.frameCount, this.startFrame, this.endFrame);
}

void trimVideoByCreatedTimestamp(Video video, Video other) {
  const Duration noChange = Duration.zero;
  final Duration videoDuration = video.duration;
  final DateTime videoStart = video.created;
  final DateTime videoEnd = videoStart.add(video.duration);

  final DateTime otherStart = other.created;
  final DateTime otherEnd = otherStart.add(other.duration);
  final Duration otherDuration = other.duration;
  final Duration absoluteDiff = (videoDuration - otherDuration).abs();

  if (!areVideosInSameDuration(video, other) &&
      !videoStart.isAtSameMomentAs(otherStart) &&
      videoStart.isBefore(otherStart)) {
    video.trim(absoluteDiff, noChange);
  }

  // By default, the video will be trimmed from the end
  if (!areVideosInSameDuration(video, other) &&
      !videoEnd.isAtSameMomentAs(otherEnd)) {
    video.trim(noChange, absoluteDiff);
  }
}

class PreprocessForm extends StatefulWidget {
  final Thumbnail thumbnail;
  final Config config;
  final Function(Config) onFormSubmit;
  final Function() onVideoTrim;

  const PreprocessForm({
    super.key,
    required this.thumbnail,
    required this.onFormSubmit,
    required this.onVideoTrim,
    required this.config,
  });

  @override
  State<PreprocessForm> createState() => PreprocessFormState();
}

class PreprocessFormState extends State<PreprocessForm> {
  final Manager _manager = Manager();
  bool _isCached = false;
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
      _isCached = _manager.isProcessed(
          widget.thumbnail.video,
          widget.config.type,
          widget.config.frameCount
        );
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

  Widget preprocessTypeDropdown() {
    return DropdownButton<PreprocessType>(
      value: widget.config.type,
      onChanged: (PreprocessType? value) {
        setState(() {
          widget.config.type = value!;
          widget.onFormSubmit(widget.config);
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
    return RangeSlider(
      values: frameRange,
      min: lowerLimit,
      max: upperLimit,
      divisions: (upperLimit - lowerLimit).toInt(),
      labels: RangeLabels(
        frameRange.start.round().toString(),
        frameRange.end.round().toString(),
      ),
      onChanged: (RangeValues values) {
        setState(() {
          frameRange = values;
        });
      },
      onChangeEnd: (RangeValues values) {
        setState(() {
          widget.thumbnail.video.startFrame = values.start.toInt();
          widget.thumbnail.video.endFrame = values.end.toInt();
          widget.onVideoTrim();
          _reloadCache();
        });
      },
      onChangeStart: (RangeValues values) {
        setState(() {
          widget.thumbnail.video.startFrame = values.start.toInt();
          widget.thumbnail.video.endFrame = values.end.toInt();
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
          widget.onFormSubmit(widget.config);
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

  Future<void> _preprocess() async {
    try {
      await _manager.storeProcessedVideoCSV(
        widget.thumbnail.video,
        widget.config.type,
        widget.config.frameCount,
      );
    } on UnsupportedError catch (_) {
      print("Unsupported PreprocessType: ${widget.config.type.name}");
      // TODO: Show error message
    }
    setState(() {
      _reloadCache();
    });
  }

  Widget submit() {
    return LoadButton(
      onPressed: _preprocess,
      text: "Preprocess",
    );
  }

  Widget status() {
    return Row(
      children: [
        _isCached
            ? const Icon(Icons.check, color: Colors.green) // Green checkmark
            : const Icon(Icons.close, color: Colors.red) // Red X
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Wrap(
        children: [
          frameSlider(),
          preprocessTypeDropdown(),
          frameCountDropdown(),
          Row(children: [submit(), const SizedBox(width: 5), status()])
        ],
      ),
    );
  }
}
