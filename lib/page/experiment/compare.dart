import 'package:flutter/material.dart';
import 'package:flutter_fhe_video_similarity/media/trim.dart';
import 'package:flutter_fhe_video_similarity/media/video.dart';
import 'package:flutter_fhe_video_similarity/media/processor.dart';
import 'package:flutter_fhe_video_similarity/page/experiment/encrypt.dart';
import 'package:flutter_fhe_video_similarity/page/experiment/preprocess.dart';
import 'package:flutter_fhe_video_similarity/page/experiment/similarity.dart';

class ConfigureVideo extends StatefulWidget {
  final Thumbnail thumbnail;
  final Config defaultConfig;
  final Function() onRefreshValidation;
  final void Function(Config) onUpdatedTestConfig;
  final GlobalKey<PreprocessFormState> preprocessFormKey;

  const ConfigureVideo({
    super.key,
    required this.thumbnail,
    required this.onUpdatedTestConfig,
    required this.onRefreshValidation,
    required this.defaultConfig,
    required this.preprocessFormKey,
  });

  @override
  State<ConfigureVideo> createState() => ConfigureVideoState();
}

class ConfigureVideoState extends State<ConfigureVideo> {
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
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
        children: [
          ...videoInfo(widget.thumbnail.video),
          PreprocessForm(
            thumbnail: widget.thumbnail,
            config: widget.defaultConfig,
            onConfigChange: widget.onUpdatedTestConfig,
            onFormSubmit: refresh,
            onVideoTrim: refresh,
            key: widget.preprocessFormKey,
          )
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
      encryptionSettings: SessionChanges(),
    );
    _comparisonConfig = Config(
      PreprocessType.sso,
      FrameCount.firstLast,
      widget.comparison.video.startFrame,
      widget.comparison.video.endFrame,
      encryptionSettings: SessionChanges(),
    );
  }

  void disableOtherEncryption() {
    setState(() {
      _baselineConfig.isEncryptionDisabled = _comparisonConfig.isEncrypted;
      _comparisonConfig.isEncryptionDisabled = _baselineConfig.isEncrypted;
    });
  }

  void baselineConfig(Config config) {
    setState(() {
      _baselineConfig = config;
      disableOtherEncryption();
    });
  }

  void comparisonConfig(Config config) {
    setState(() {
      _comparisonConfig = config;
      disableOtherEncryption();
    });
  }

  void alignVideos() {
    setState(() {
      trimVideos(widget.baseline.video, widget.comparison.video);
    });
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<PreprocessFormState> baselineKey =
        GlobalKey<PreprocessFormState>();
    final GlobalKey<PreprocessFormState> comparisonKey =
        GlobalKey<PreprocessFormState>();
    final GlobalKey<SimilarityResultsState> similarityResultsKey =
        GlobalKey<SimilarityResultsState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Videos'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                    child: ConfigureVideo(
                        thumbnail: widget.baseline,
                        defaultConfig: _baselineConfig,
                        onUpdatedTestConfig: baselineConfig,
                        onRefreshValidation: () =>
                            similarityResultsKey.currentState?.setState(() {}),
                        preprocessFormKey: baselineKey)),
                Expanded(
                    child: ConfigureVideo(
                        thumbnail: widget.comparison,
                        defaultConfig: _comparisonConfig,
                        onUpdatedTestConfig: comparisonConfig,
                        onRefreshValidation: () =>
                            similarityResultsKey.currentState?.setState(() {}),
                        preprocessFormKey: comparisonKey)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SimilarityResults(
        key: similarityResultsKey,
        baseline: widget.baseline.video,
        comparison: widget.comparison.video,
        baselineConfig: _baselineConfig,
        comparisonConfig: _comparisonConfig,
        alignVideos: alignVideos,
        baselineKey: baselineKey,
        comparisonKey: comparisonKey,
      ),
    );
  }
}
