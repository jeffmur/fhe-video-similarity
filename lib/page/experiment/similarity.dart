import 'package:flutter/material.dart';
import 'package:flutter_fhe_video_similarity/media/seal.dart';
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

class CiphertextSimilarityScores {
  Session ciphertextHandler; // Untrusted 3rd party
  List<double> toCiphertext;
  Session plaintextEncoder; // Client
  List<double> toPlaintext;

  CiphertextSimilarityScores(this.ciphertextHandler, this.toCiphertext,
      this.plaintextEncoder, this.toPlaintext);

  double compute(SimilarityType type) {
    List<Ciphertext> x = ciphertextHandler.encryptVecDouble(toCiphertext);

    switch (type) {
      case SimilarityType.kld:
        CiphertextKLD kld = CiphertextKLD(ciphertextHandler, plaintextEncoder);
        List<Ciphertext> logX =
            ciphertextHandler.encryptVecDouble(kld.log(toCiphertext));
        return kld.score(x, logX, toPlaintext);

      case SimilarityType.bhattacharyya:
        CiphertextBhattacharyya bhattacharyya =
            CiphertextBhattacharyya(ciphertextHandler, plaintextEncoder);
        List<Ciphertext> sqrtX = ciphertextHandler
            .encryptVecDouble(bhattacharyya.sqrt(toCiphertext));
        return bhattacharyya.score(sqrtX, bhattacharyya.sqrt(toPlaintext));

      case SimilarityType.cramer:
        CiphertextCramer cramer =
            CiphertextCramer(ciphertextHandler, plaintextEncoder);
        return cramer.score(x, toPlaintext);

      default:
        throw ArgumentError('Unsupported similarity type');
    }
  }

  String score(SimilarityType type) {
    return compute(type).toStringAsExponential();
  }

  String percentile(SimilarityType type) {
    return Similarity(type)
        .percentile(toCiphertext, toPlaintext)
        .toStringAsFixed(2);
  }
}

class SimilarityResultsState extends State<SimilarityResults> {
  final Manager _manager = Manager();
  Widget? _comparison;
  Widget? _ciphertextComparison;

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
        const SizedBox(height: 10),
        ElevatedButton(
          child: const Text('Compute Plaintext Similarity Scores'),
          onPressed: () async {
            // Fetch normalized data in parallel
            var baselineData = await _manager.getCachedNormalized(
                widget.baseline,
                widget.baselineConfig.type,
                widget.baselineConfig.frameCount);
            var comparisonData = await _manager.getCachedNormalized(
                widget.comparison,
                widget.comparisonConfig.type,
                widget.comparisonConfig.frameCount);

            var plaintext = PlaintextSimilarityScores(
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
        ),
        const SizedBox(height: 10),
        _comparison ?? const Text("No comparison yet"),
        ElevatedButton(
            child: const Text('Compute Encrypted Similarity Scores'),
            onPressed: () async {
              // Fetch encrypted data in parallel
              var baselineData = await _manager.getCachedNormalized(
                  widget.baseline,
                  widget.baselineConfig.type,
                  widget.baselineConfig.frameCount);

              var comparisonData = await _manager.getCachedNormalized(
                  widget.comparison,
                  widget.comparisonConfig.type,
                  widget.comparisonConfig.frameCount);

              var isBaselineEncrypted = widget.baselineConfig.isEncrypted;
              var isComparisonEncrypted = widget.comparisonConfig.isEncrypted;

              // Update UI with results
              setState(() {
                // Only one video must be encrypted, otherwise the comparison is not possible
                if (isBaselineEncrypted == isComparisonEncrypted) {
                  _ciphertextComparison = const Text(
                      "One video must be encrypted for comparison",
                      style: TextStyle(color: Colors.red));
                } else {
                  // Determine settings and data based on whether the baseline is encrypted
                  var (ciphertextHandler, plaintextEncoder) = isBaselineEncrypted
                      ? (widget.baselineConfig.encryptionSettings, widget.comparisonConfig.encryptionSettings)
                      : (widget.comparisonConfig.encryptionSettings, widget.baselineConfig.encryptionSettings);

                  var (toCiphertext, toPlaintext) = isBaselineEncrypted
                      ? (baselineData, comparisonData)
                      : (comparisonData, baselineData);

                  // Pass them to CiphertextSimilarityScores
                  var ciphertext = CiphertextSimilarityScores(
                      ciphertextHandler.session, toCiphertext,
                      plaintextEncoder.session, toPlaintext);

                  _ciphertextComparison = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Kullback-Leibler Divergence: ${ciphertext.score(SimilarityType.kld)}"
                        " vs. ${ciphertext.percentile(SimilarityType.kld)}% similarity",
                        style: const TextStyle(fontSize: 16),
                      ),
                      Text(
                          "Bhattacharyya Coefficent: ${ciphertext.score(SimilarityType.bhattacharyya)}"
                          " vs. ${ciphertext.percentile(SimilarityType.bhattacharyya)}% similarity",
                          style: const TextStyle(fontSize: 16)),
                      Text(
                          "Cramer Distance: ${ciphertext.score(SimilarityType.cramer)}"
                          " vs. ${ciphertext.percentile(SimilarityType.cramer)}% similarity",
                          style: const TextStyle(fontSize: 16)),
                    ],
                  );
                }
              });
            }),
        const SizedBox(height: 10),
        _ciphertextComparison ?? const Text("No comparison yet"),
      ],
    );
  }
}
