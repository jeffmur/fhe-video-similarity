// Compare two Thumbnails (and videos) for similarity
// Experiment page for testing different similarity metrics

import 'package:flutter/material.dart';
import 'package:flutter_fhe_video_similarity/media/video.dart' show Thumbnail;


class ComputeSimilarity extends StatelessWidget {
  const ComputeSimilarity({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compute Similarity'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              // Navigator.of(context).push(MaterialPageRoute(
              //   builder: (context) => const ListDoubleAddition(),
              // ));
            },
            child: const Text('Compute Similarity'),
          ),
        ],
      ),
    );
  }
}