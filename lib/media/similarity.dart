import 'package:fhe_similarity_score/kld.dart' as kld;
import 'package:fhe_similarity_score/bhattacharyya.dart' as bhattacharyya;
import 'package:fhe_similarity_score/cramer.dart' as cramer;

enum SimilarityType { kld, bhattacharyya, cramer }

class Similarity {
  final SimilarityType type;

  Similarity(this.type);

  double score(List<double> v1, List<double> v2) {
    // Truncate the longer vector
    int count = v1.length < v2.length ? v1.length : v2.length;
    v1 = v1.sublist(0, count);
    v2 = v2.sublist(0, count);

    switch (type) {
      case SimilarityType.kld:
        return kld.divergence(v1, v2);
      case SimilarityType.bhattacharyya:
        return bhattacharyya.coefficient(v1, v2);
      case SimilarityType.cramer:
        return cramer.distance(v1, v2);
      default:
        return 0.0;
    }
  }

  double percentile(List<double> v1, List<double> v2) {
    double score = this.score(v1, v2).abs();
    return switch (type) {
          SimilarityType.kld => 1 - (score / (1 + score)), // normalize to 0..1 (identical)
          SimilarityType.cramer => 1 - score,
          _ => score
        } *
        100;
  }
}
