import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_fhe_video_similarity/logging.dart';
import 'package:flutter_fhe_video_similarity/media/seal.dart';
import 'package:flutter_fhe_video_similarity/media/share_encryption_archive.dart';
import 'package:flutter_fhe_video_similarity/media/storage.dart';
import 'package:flutter_fhe_video_similarity/media/video.dart';
import 'package:flutter_fhe_video_similarity/media/manager.dart' show Manager;
import 'package:flutter_fhe_video_similarity/media/video_encryption.dart';
import 'package:flutter_fhe_video_similarity/page/experiment/validator.dart';
import 'package:flutter_fhe_video_similarity/media/similarity.dart';
import 'package:flutter_fhe_video_similarity/page/experiment/preprocess.dart';
import 'package:flutter_fhe_video_similarity/page/share_button.dart';

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
  List<double> baseline;
  List<double> comparison;
  final bool flip;

  /// [flip] is used to evaluate symmetry of similarity scores
  ///
  PlaintextSimilarityScores(this.baseline, this.comparison,
      {this.flip = false}) {
    if (flip) {
      List<double> temp = baseline;
      baseline = comparison;
      comparison = temp;
    }
  }

  String score(SimilarityType type) {
    return Similarity(type).score(baseline, comparison).toStringAsExponential();
  }

  String percentile(SimilarityType type) {
    return Similarity(type).percentile(baseline, comparison).toStringAsFixed(2);
  }
}

class CiphertextSimilarityScores {
  Session ciphertextHandler; // Mock untrusted 3rd party
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

class ImportCiphertextSimilarityScores {
  Session ciphertextHandler; // Untrusted 3rd party
  CiphertextVideo importCiphertext;
  Session plaintextEncoder; // Client
  List<double> toPlaintext;

  ImportCiphertextSimilarityScores(this.ciphertextHandler,
      this.importCiphertext, this.plaintextEncoder, this.toPlaintext);

  List<Ciphertext> score(SimilarityType type) {
    List<Ciphertext> result = [];
    DateTime start = DateTime.now();
    String typeName = '';
    switch (type) {
      case SimilarityType.kld:
        typeName = 'KLD';
        CiphertextKLD kld = CiphertextKLD(ciphertextHandler, plaintextEncoder);
        result = kld.homomorphicScore(
            importCiphertext.kld, importCiphertext.kldLog, toPlaintext);

      case SimilarityType.bhattacharyya:
        typeName = 'Bhattacharyya';
        CiphertextBhattacharyya bhattacharyya =
            CiphertextBhattacharyya(ciphertextHandler, plaintextEncoder);
        result = bhattacharyya.homomorphicScore(
            importCiphertext.bhattacharyya, bhattacharyya.sqrt(toPlaintext));

      case SimilarityType.cramer:
        typeName = 'Cramer';
        CiphertextCramer cramer =
            CiphertextCramer(ciphertextHandler, plaintextEncoder);
        result = cramer.homomorphicScore(importCiphertext.cramer, toPlaintext);

      default:
        throw ArgumentError('Unsupported similarity type');
    }
    Duration took = DateTime.now().difference(start);
    Logging().metric(
        '📊 $typeName Computed Homomorphic Score in ${took.inMilliseconds}ms',
        correlationId: importCiphertext.stats.id);
    return result;
  }

  Map<String, List<Ciphertext>> scoreAll() {
    // TODO: Support some?
    return {
      'kld': score(SimilarityType.kld),
      'bhattacharyya': score(SimilarityType.bhattacharyya),
      'cramer': score(SimilarityType.cramer),
    };
  }
}

class SimilarityResultsState extends State<SimilarityResults> {
  final Manager _manager = Manager();
  Widget? _comparison;
  Widget? _ciphertextComparison;

  Future<XFile> computeImportCiphertextSimilarityScore() async {
    var isBaselineImportedCiphertext = widget.baseline is CiphertextVideo;

    // Setup vars
    var (ciphertextHandler, plaintextEncoder) = isBaselineImportedCiphertext
        ? (widget.baselineConfig, widget.comparisonConfig)
        : (widget.comparisonConfig, widget.baselineConfig);
    var (importCiphertext as CiphertextVideo, plaintextComparator) =
        isBaselineImportedCiphertext
            ? (widget.baseline, widget.comparison)
            : (widget.comparison, widget.baseline);

    // Fetch data to compare
    List<double> plaintextData = await _manager.getCachedNormalized(
        plaintextComparator,
        plaintextEncoder.type,
        plaintextEncoder.frameCount);

    Map<String, List<Ciphertext>> scores = ImportCiphertextSimilarityScores(
            ciphertextHandler.encryptionSettings.session,
            importCiphertext,
            plaintextEncoder.encryptionSettings.session,
            plaintextData)
        .scoreAll();

    // Apply plaintext to ciphertext data via homomorphic score
    return ExportModifiedCiphertextVideoZip(
      tempDir: await ApplicationStorage('tmp').path,
      archivePath:
          await ApplicationStorage('${importCiphertext.meta.path}/scores.zip').path,
      scores: scores,
      meta: importCiphertext.meta,
    ).create().then((File out) async {
      // Delete tmp directory
      await Directory(await ApplicationStorage('tmp').path)
          .delete(recursive: true);
      return XFile(out.path);
    });
  }

  bool isImportedCiphertextComparison() {
    return widget.baseline is CiphertextVideo ||
        widget.comparison is CiphertextVideo;
  }

  bool isCiphertextComparison() {
    return widget.baselineConfig.isEncrypted ||
        widget.comparisonConfig.isEncrypted;
  }

  Widget computeCiphertextComparison() {
    return ElevatedButton(
        child: const Text('Compute Encrypted Similarity Scores'),
        onPressed: () async {
          // Fetch encrypted data in parallel
          var baselineData = await _manager.getCachedNormalized(widget.baseline,
              widget.baselineConfig.type, widget.baselineConfig.frameCount);

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
                  ? (
                      widget.baselineConfig.encryptionSettings,
                      widget.comparisonConfig.encryptionSettings
                    )
                  : (
                      widget.comparisonConfig.encryptionSettings,
                      widget.baselineConfig.encryptionSettings
                    );

              var (toCiphertext, toPlaintext) = isBaselineEncrypted
                  ? (baselineData, comparisonData)
                  : (comparisonData, baselineData);

              // Pass them to CiphertextSimilarityScores
              var ciphertext = CiphertextSimilarityScores(
                  ciphertextHandler.session,
                  toCiphertext,
                  plaintextEncoder.session,
                  toPlaintext);

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
        });
  }

  Widget computePlaintextComparison() {
    return ElevatedButton(
      child: const Text('Compute Plaintext Similarity Scores'),
      onPressed: () async {
        // Fetch normalized data in parallel
        var baselineData = await _manager.getCachedNormalized(widget.baseline,
            widget.baselineConfig.type, widget.baselineConfig.frameCount);
        var comparisonData = await _manager.getCachedNormalized(
            widget.comparison,
            widget.comparisonConfig.type,
            widget.comparisonConfig.frameCount);

        var plaintext = PlaintextSimilarityScores(
          baselineData,
          comparisonData,
          flip: widget.comparisonConfig.isEncrypted,
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
    );
  }

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
        !isImportedCiphertextComparison()
            ? computePlaintextComparison()
            : const SizedBox(),
        const SizedBox(height: 10),
        _comparison ?? const SizedBox(),
        const SizedBox(height: 10),
        isCiphertextComparison()
            ? computeCiphertextComparison()
            : const SizedBox(),
        _ciphertextComparison ?? const SizedBox(),
        isImportedCiphertextComparison()
            ? ShareFileElevatedButton(
                file: computeImportCiphertextSimilarityScore(),
                child: const Text('Export Homomorphic Similarity Scores'))
            : const SizedBox(),
      ],
    );
  }
}
