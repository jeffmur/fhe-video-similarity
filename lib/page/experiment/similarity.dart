import 'package:flutter/material.dart';
import 'package:flutter_fhe_video_similarity/media/video.dart';
import 'package:flutter_fhe_video_similarity/media/manager.dart' show Manager;
import 'package:flutter_fhe_video_similarity/page/experiment/validator.dart';
import 'package:flutter_fhe_video_similarity/media/similarity.dart';
import 'package:flutter_fhe_video_similarity/page/experiment/preprocess.dart';

class SimilarityResults extends StatefulWidget {
  final Video baseline;
  final Video comparison;
  final Config baselineConfig;
  final Config comparisonConfig;
  final GlobalKey<PreprocessFormState> baselineKey;
  final GlobalKey<PreprocessFormState> comparisonKey;
  final Function alignVideos;

  const SimilarityResults({
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
  State<SimilarityResults> createState() => SimilarityResultsState();
}

class PlaintextSimilarityScores {
  final List<double> baseline;
  final List<double> comparison;

  PlaintextSimilarityScores(this.baseline, this.comparison);

  String score(SimilarityType type) {
    return Similarity(type).score(baseline, comparison).toStringAsExponential();
  }

  String percentile(SimilarityType type) {
    return Similarity(type).percentile(baseline, comparison).toStringAsFixed(2);
  }
}

class SimilarityResultsState extends State<SimilarityResults> {
  final Manager _manager = Manager();
  Widget? _comparison;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        areVideosInSameDurationStatus(widget.baseline, widget.comparison,
            () async {
          setState(() {
            widget.alignVideos();
            widget.baselineKey.currentState?.refreshSlider();
            widget.comparisonKey.currentState?.refreshSlider();
          });
        }),
        areVideosInSameTimelineStatus(widget.baseline, widget.comparison),
        areVideosInSameFrameRangeStatus(widget.baseline, widget.comparison),
        areVideosInSameEncodingStatus(widget.baseline, widget.comparison),
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

            final plaintext = PlaintextSimilarityScores(
              baselineData,
              comparisonData,
            );

            // Update UI with results
            setState(() {
              _comparison = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      "Kullback-Leibler Divergence: ${plaintext.score(SimilarityType.kld)} vs. "
                      "${plaintext.percentile(SimilarityType.kld)}% similarily",
                      style: const TextStyle(fontSize: 16)),
                  Text(
                      "Bhattacharyya Coefficent: ${plaintext.score(SimilarityType.bhattacharyya)} vs. "
                      "${plaintext.percentile(SimilarityType.bhattacharyya)}% similarity",
                      style: const TextStyle(fontSize: 16)),
                  Text(
                      "Cramer Distance: ${plaintext.score(SimilarityType.cramer)} vs. "
                      "${plaintext.percentile(SimilarityType.cramer)}% similarity",
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
