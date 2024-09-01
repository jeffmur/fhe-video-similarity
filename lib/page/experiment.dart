import 'package:flutter/material.dart';
import 'package:flutter_fhe_video_similarity/media/video.dart'
    show Thumbnail, FrameCount;
import 'package:flutter_fhe_video_similarity/media/manager.dart' show Manager;
import 'package:flutter_fhe_video_similarity/media/processor.dart';
import 'package:flutter_fhe_video_similarity/media/similarity.dart';

class Config {
  PreprocessType type;
  FrameCount frameCount;

  Config(this.type, this.frameCount);
}

enum PreprocessState { idle, readCache, writeCache }

// ignore: must_be_immutable
class PreprocessForm extends StatefulWidget {
  final Thumbnail thumbnail;
  final Function(Config) onFormSubmit;
  Config config;

  PreprocessForm({
    super.key,
    required this.thumbnail,
    required this.onFormSubmit,
    required this.config,
  });

  @override
  State<PreprocessForm> createState() => _PreprocessFormState();
}

class _PreprocessFormState extends State<PreprocessForm> {
  final Manager _manager = Manager();
  bool _isCached = false;

  @override
  void initState() {
    super.initState();
    _reloadCache();
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

  void _reloadCache() {
    setState(() {
      _isCached =
          _manager.isProcessed(widget.thumbnail.video, widget.config.type, widget.config.frameCount);
      print("Is cached? $_isCached");
    });
  }

  Future<void> _preprocess() async {
    try {
      await _manager.storeProcessedVideoCSV(
          widget.thumbnail.video, widget.config.type, widget.config.frameCount);
    } on UnsupportedError catch (_) {
      print("Unsupported PreprocessType: ${widget.config.type.name}");
      // TODO: Show error message
    }
    setState(() {
      _reloadCache();
    });
  }

  Widget submit() {
    return ElevatedButton(
      onPressed: _preprocess,
      child: const Text("Preprocess"),
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
  final void Function(Config) onConfigChange;
  final Config defaultConfig;

  const Configure({
    super.key,
    required this.thumbnail,
    required this.onConfigChange,
    required this.defaultConfig,
  });

  @override
  State<Configure> createState() => _ConfigureState();
}

class _ConfigureState extends State<Configure> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          Text("${widget.thumbnail.video.stats.toJson()}"),
          // Video player?
          PreprocessForm(
              thumbnail: widget.thumbnail,
              onFormSubmit: widget.onConfigChange,
              config: widget.defaultConfig),
        ],
      ),
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
  Widget? _comparison;
  final Manager _manager = Manager();
  Config _baselineConfig = Config(PreprocessType.sso, FrameCount.firstLast);
  Config _comparisonConfig = Config(PreprocessType.sso, FrameCount.firstLast);

  void baselineConfig(Config config) {
    setState(() {
      _baselineConfig = config;
    });
  }

  void comparisonConfig(Config config) {
    setState(() {
      _comparisonConfig = config;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                      onConfigChange: baselineConfig,
                      defaultConfig: _baselineConfig),
                ),
                Expanded(
                  child: Configure(
                      thumbnail: widget.comparison,
                      onConfigChange: comparisonConfig,
                      defaultConfig: _comparisonConfig),
                ),
              ],
            ),
          ),
          // Comparison controls, centered
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 150,
        child: ListView(
          shrinkWrap: true,
          children: [
            ElevatedButton(
              onPressed: () async {
                // Fetch normalized data in parallel
                final baselineData = await _manager.getCachedNormalized(
                    widget.baseline.video,
                    _baselineConfig.type,
                    _baselineConfig.frameCount);
                final comparisonData = await _manager.getCachedNormalized(
                    widget.comparison.video,
                    _comparisonConfig.type,
                    _comparisonConfig.frameCount);

                // Calculate similarity scores in parallel
                final kldPercentage = Similarity(SimilarityType.kld)
                    .percentile(baselineData, comparisonData)
                    .toStringAsFixed(2);
                final bhattacharyyaPercentage =
                    Similarity(SimilarityType.bhattacharyya)
                        .percentile(baselineData, comparisonData)
                        .toStringAsFixed(2);
                final cramerPercentage = Similarity(SimilarityType.cramer)
                    .percentile(baselineData, comparisonData)
                    .toStringAsFixed(2);

                // Update UI with results
                setState(() {
                  _comparison = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("KLD: $kldPercentage% similar",
                          style: const TextStyle(fontSize: 16)),
                      Text("Bhattacharyya: $bhattacharyyaPercentage% similar",
                          style: const TextStyle(fontSize: 16)),
                      Text("Cramér's: $cramerPercentage% similar",
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
        ),
      ),
    );
  }
}
