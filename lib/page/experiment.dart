import 'package:flutter/material.dart';
import 'package:flutter_fhe_video_similarity/media/video.dart';
import 'package:flutter_fhe_video_similarity/media/manager.dart' show Manager;
import 'package:flutter_fhe_video_similarity/media/processor.dart';
import 'package:flutter_fhe_video_similarity/media/similarity.dart';
import 'package:flutter_fhe_video_similarity/page/load_button.dart';

class Config {
  PreprocessType type;
  FrameCount frameCount;
  int startFrame;
  int endFrame;

  Config(this.type, this.frameCount, this.startFrame, this.endFrame);
}

enum PreprocessState { idle, readCache, writeCache }

// ignore: must_be_immutable
class PreprocessForm extends StatefulWidget {
  Thumbnail thumbnail;
  Config config;
  final Function(Config) onFormSubmit;
  final Function() onVideoTrim;

  PreprocessForm({
    super.key,
    required this.thumbnail,
    required this.onFormSubmit,
    required this.onVideoTrim,
    required this.config,
  });

  @override
  State<PreprocessForm> createState() => _PreprocessFormState();
}

class _PreprocessFormState extends State<PreprocessForm> {
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
          widget.thumbnail.video, widget.config.type, widget.config.frameCount);
      print("Is cached? $_isCached");
    });
  }

  void refreshSlider() {
    setState(() {
      print("Refreshing slider");
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

class Configure extends StatefulWidget {
  final Thumbnail thumbnail;
  final Config defaultConfig;
  final Function() onRefreshValidation;
  final void Function(Config)
      onUpdatedTestConfig; // Callback to update test config
  final GlobalKey<_PreprocessFormState> preprocessFormKey;

  const Configure({
    super.key,
    required this.thumbnail,
    required this.onUpdatedTestConfig,
    required this.onRefreshValidation,
    required this.defaultConfig,
    required this.preprocessFormKey,
  });

  @override
  State<Configure> createState() => _ConfigureState();
}

class _ConfigureState extends State<Configure> {
  void refresh() {
    widget.onRefreshValidation(); // Update validation checks
    setState(() {}); // Update Video stats
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          Text("sha256: ${widget.thumbnail.video.hash}"),
          Text("Created: ${widget.thumbnail.video.created}"),
          Text("Duration: ${widget.thumbnail.video.duration} seconds"),
          Text("Frame Range: "
              "${widget.thumbnail.video.startFrame} - "
              "${widget.thumbnail.video.endFrame} of "
              "${widget.thumbnail.video.totalFrames}"),

          Text("Encoding: ${widget.thumbnail.video.stats.codec}"),

          // Video player?
          PreprocessForm(
              thumbnail: widget.thumbnail,
              config: widget.defaultConfig,
              onFormSubmit: widget.onUpdatedTestConfig,
              onVideoTrim: refresh,
              key: widget.preprocessFormKey),
        ],
      ),
    );
  }
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

  print("[DEBUG] Trimming video by created timestamp.");

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

// Returns true if the two videos overlap in timeline
//
bool areVideosInSameTimeline(Video video, Video other) {
  Duration diff = video.created.difference(other.created);
  return diff.inSeconds.abs() < video.duration.inSeconds;
}

// Returns true if the two videos share the same duration
//
bool areVideosInSameDuration(Video video, Video other) {
  return video.duration == other.duration;
}

// Returns true if the two videos share the same frame range
//
bool areVideosInSameFrameRange(Video video, Video other) {
  return video.startFrame == other.startFrame &&
      video.endFrame == other.endFrame;
}

// Returns true if the two videos share the same frame count
//
bool areVideosInSameFrameCount(Video video, Video other) {
  return video.totalFrames == other.totalFrames;
}

// Returns true if the two videos share the same encoding
//
bool areVideosInSameEncoding(Video video, Video other) {
  return video.stats.codec == other.stats.codec;
}

Text successText(String text,
    {TextStyle style = const TextStyle(color: Colors.green)}) {
  return Text("✅ $text", style: style, textAlign: TextAlign.center);
}

Text failureText(String text,
    {TextStyle style = const TextStyle(color: Colors.red)}) {
  return Text("❌ $text", style: style, textAlign: TextAlign.center);
}

class Results extends StatefulWidget {
  final Video baseline;
  final Video comparison;
  final Config baselineConfig;
  final Config comparisonConfig;
  final GlobalKey<_PreprocessFormState> baselineKey;
  final GlobalKey<_PreprocessFormState> comparisonKey;
  final Function alignVideos;

  const Results({
    super.key,
    required this.baseline,
    required this.baselineKey,
    required this.baselineConfig,
    required this.comparison,
    required this.comparisonKey,
    required this.comparisonConfig,
    required this.alignVideos,
  });

  @override
  State<Results> createState() => _ResultsState();
}

class _ResultsState extends State<Results> {
  Widget? _comparison;
  final Manager _manager = Manager();

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        areVideosInSameTimeline(widget.baseline, widget.comparison)
            ? successText("Videos are in the same timeline")
            : failureText("Videos are not in the same timeline"),
        areVideosInSameDuration(widget.baseline, widget.comparison)
            ? successText("Videos share the same duration")
            : Column(children: [
                failureText("Videos do not share the same duration"),
                LoadButton(
                    onPressed: () async {
                      setState(() {
                        widget.alignVideos();
                        widget.baselineKey.currentState?.refreshSlider();
                        widget.comparisonKey.currentState?.refreshSlider();
                      });
                    },
                    text: "Align",
                    timer: false)
              ]),
        areVideosInSameFrameRange(widget.baseline, widget.comparison)
            ? successText("Videos share the same frame range")
            : failureText("Videos do not share the same frame range"),
        areVideosInSameFrameCount(widget.baseline, widget.comparison)
            ? successText("Videos share the same frame count")
            : failureText("Videos do not share the same frame count"),
        areVideosInSameEncoding(widget.baseline, widget.comparison)
            ? successText("Videos share the same encoding")
            : failureText("Videos do not share the same encoding"),
        ElevatedButton(
          onPressed: () async {
            // Fetch normalized data in parallel
            final baselineData = await _manager.getCachedNormalized(
                widget.baseline,
                widget.baselineConfig.type,
                widget.baselineConfig.frameCount);
            final comparisonData = await _manager.getCachedNormalized(
                widget.comparison,
                widget.comparisonConfig.type,
                widget.comparisonConfig.frameCount);

            // Calculate similarity scores in parallel
            final kldScore = Similarity(SimilarityType.kld)
                .score(baselineData, comparisonData)
                .toStringAsFixed(2);
            final kldPercentage = Similarity(SimilarityType.kld)
                .percentile(baselineData, comparisonData)
                .toStringAsFixed(2);

            final bhattacharyyaScore = Similarity(SimilarityType.bhattacharyya)
                .score(baselineData, comparisonData)
                .toStringAsFixed(2);
            final bhattacharyyaPercentage =
                Similarity(SimilarityType.bhattacharyya)
                    .percentile(baselineData, comparisonData)
                    .toStringAsFixed(2);

            final cramerScore = Similarity(SimilarityType.cramer)
                .score(baselineData, comparisonData)
                .toStringAsFixed(2);
            final cramerPercentage = Similarity(SimilarityType.cramer)
                .percentile(baselineData, comparisonData)
                .toStringAsFixed(2);

            // Update UI with results
            setState(() {
              _comparison = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "Kullback-Leibler Divergence: $kldScore vs. $kldPercentage% similarily",
                      style: const TextStyle(fontSize: 16)),
                  Text(
                      "Bhattacharyya Coefficent: $bhattacharyyaScore vs. $bhattacharyyaPercentage% similarity",
                      style: const TextStyle(fontSize: 16)),
                  Text(
                      "Cramer Distance: $cramerScore vs. $cramerPercentage% similarity",
                      style: const TextStyle(fontSize: 16)),
                ],
              );
            });
          },
          child: const Text("Compute Similarity Scores"),
        ),
        const SizedBox(height: 10),
        // Log messages
        _comparison ?? const Text("No comparison yet"),
      ],
    );
  }
}

class Experiment extends StatefulWidget {
  final Thumbnail baseline;
  final Thumbnail comparison;

  const Experiment({
    super.key,
    required this.baseline,
    required this.comparison,
  });

  @override
  State<Experiment> createState() => _ExperimentState();
}

class _ExperimentState extends State<Experiment> {
  late Config _baselineConfig;
  late Config _comparisonConfig;

  @override
  void initState() {
    super.initState();
    _baselineConfig = Config(
      PreprocessType.sso,
      FrameCount.firstLast,
      widget.baseline.video.startFrame,
      widget.baseline.video.endFrame,
    );
    _comparisonConfig = Config(
      PreprocessType.sso,
      FrameCount.firstLast,
      widget.comparison.video.startFrame,
      widget.comparison.video.endFrame,
    );
  }

  void baselineConfig(Config config) {
    print("Updating baseline config.");
    setState(() {
      _baselineConfig = config;
    });
  }

  void comparisonConfig(Config config) {
    setState(() {
      _comparisonConfig = config;
    });
  }

  void alignVideos() {
    setState(() {
      widget.baseline.video.duration >
              widget.comparison.video.duration
          ? trimVideoByCreatedTimestamp(
              widget.baseline.video, widget.comparison.video)
          : trimVideoByCreatedTimestamp(
              widget.comparison.video, widget.baseline.video);
    });
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<_PreprocessFormState> _baselineKey =
        GlobalKey<_PreprocessFormState>();
    final GlobalKey<_PreprocessFormState> _comparisonKey =
        GlobalKey<_PreprocessFormState>();
    final GlobalKey<_ResultsState> _resultsKey =
        GlobalKey<_ResultsState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Experiment'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                    child: Configure(
                        thumbnail: widget.baseline,
                        defaultConfig: _baselineConfig,
                        onUpdatedTestConfig: baselineConfig,
                        onRefreshValidation: () => _resultsKey.currentState?.setState(() {}),
                        preprocessFormKey: _baselineKey)),
                Expanded(
                    child: Configure(
                        thumbnail: widget.comparison,
                        defaultConfig: _comparisonConfig,
                        onUpdatedTestConfig: comparisonConfig,
                        onRefreshValidation: () => _resultsKey.currentState?.setState(() {}),
                        preprocessFormKey: _comparisonKey)),
              ],
            ),
          ),
          // Comparison controls, centered
        ],
      ),
      bottomNavigationBar: Results(
        key: _resultsKey,
        baseline: widget.baseline.video,
        comparison: widget.comparison.video,
        baselineConfig: _baselineConfig,
        comparisonConfig: _comparisonConfig,
        alignVideos: alignVideos,
        baselineKey: _baselineKey,
        comparisonKey: _comparisonKey,
      ),
    );
  }
}
