import 'package:flutter/material.dart';
import 'package:fhe_similarity_score/probability.dart';
import 'package:flutter_fhe_video_similarity/media/video.dart';

enum SimilarityType { kld }

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
        return kld(v1, v2);
      default:
        return 0.0;
    }
  }

  int percentile(List<double> v1, List<double> v2) {
    double score = this.score(v1, v2).abs();
    switch (type) {
      case SimilarityType.kld:
        return 100 - (score * 100).toInt();
      default:
        return 0;
    }
  }
}
