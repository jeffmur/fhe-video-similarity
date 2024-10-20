import 'dart:math' as math;
import 'package:fhe_similarity_score/kld.dart' as kld;
import 'package:fhe_similarity_score/bhattacharyya.dart' as bhattacharyya;
import 'package:fhe_similarity_score/cramer.dart' as cramer;
import '../media/seal.dart';

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

enum SimilarityType { kld, bhattacharyya, cramer }

String similarityTypeToString(SimilarityType type) {
  return switch (type) {
    SimilarityType.kld => 'KLD',
    SimilarityType.bhattacharyya => 'Bhattacharyya',
    SimilarityType.cramer => 'Cramer',
  };
}

double normalizedPercentage(SimilarityType type, double score) {
  return switch (type) {
        SimilarityType.kld => 1 / (1 + score),
        SimilarityType.cramer => 1 - score,
        _ => score
      } *
      100;
}

class Similarity {
  final SimilarityType type;

  Similarity(this.type);

  double score(List<double> v1, List<double> v2) {
    switch (type) {
      case SimilarityType.kld:
        return kld.divergence(v1, v2);
      case SimilarityType.bhattacharyya:
        return bhattacharyya.coefficient(v1, v2);
      case SimilarityType.cramer:
        return cramer.distance(v1, v2);
    }
  }

  double percentile(List<double> v1, List<double> v2) {
    return normalizedPercentage(type, score(v1, v2).abs());
  }
}

// Ciphertext Similarity Scores
// ----------------------------
// ciphertextHandler: Session that encrypts and decrypts Ciphertexts (untrusted 3rd party)
// plaintextEncoder: Session that encodes and decodes plaintexts (current user)

class CiphertextKLD {
  final Session ciphertextHandler;
  final Session plaintextEncoder;
  CiphertextKLD(this.ciphertextHandler, this.plaintextEncoder);

  List<double> log(List<double> v) {
    return v.map((e) => math.log(e)).toList();
  }

  double score(List<Ciphertext> x, List<Ciphertext> logX, List<double> y) {
    return ciphertextHandler
        .decryptedSumOfDoubles(kld.divergenceOfCiphertextVecDouble(
            plaintextEncoder.seal, x, logX, y));
  }

  List<Ciphertext> homomorphicScore(
      List<Ciphertext> x, List<Ciphertext> logX, List<double> y) {
    return kld.divergenceOfCiphertextVecDouble(
        plaintextEncoder.seal, x, logX, y);
  }

  double percentile(List<Ciphertext> x, List<Ciphertext> logX, List<double> y) {
    return normalizedPercentage(SimilarityType.kld, score(x, logX, y));
  }
}

class CiphertextBhattacharyya {
  final Session ciphertextHandler;
  final Session plaintextEncoder;
  CiphertextBhattacharyya(this.ciphertextHandler, this.plaintextEncoder);

  List<double> sqrt(List<double> v) {
    return v.map((e) => math.sqrt(e)).toList();
  }

  double score(List<Ciphertext> sqrtX, List<double> sqrtY) {
    return ciphertextHandler
        .decryptedSumOfDoubles(bhattacharyya.coefficientOfCiphertextVecDouble(
            plaintextEncoder.seal, sqrtX, sqrtY));
  }

  List<Ciphertext> homomorphicScore(
      List<Ciphertext> sqrtX, List<double> sqrtY) {
    return bhattacharyya.coefficientOfCiphertextVecDouble(
        plaintextEncoder.seal, sqrtX, sqrtY);
  }

  double percentile(List<Ciphertext> sqrtX, List<double> sqrtY) {
    return normalizedPercentage(
        SimilarityType.bhattacharyya, score(sqrtX, sqrtY));
  }
}

class CiphertextCramer {
  final Session ciphertextHandler;
  final Session plaintextEncoder;
  CiphertextCramer(this.ciphertextHandler, this.plaintextEncoder);

  double score(List<Ciphertext> cumulativeSumX, List<double> cumulativeSumY) {
    return math.sqrt(ciphertextHandler
        .decryptedSumOfDoubles(cramer.distanceOfCiphertextVecDouble(
            plaintextEncoder.seal, cumulativeSumX, cumulativeSumY)));
  }

  List<Ciphertext> homomorphicScore(List<Ciphertext> x, List<double> y) {
    return cramer.distanceOfCiphertextVecDouble(plaintextEncoder.seal, x, y);
  }

  double percentile(List<Ciphertext> x, List<double> y) {
    return normalizedPercentage(SimilarityType.cramer, score(x, y));
  }
}
