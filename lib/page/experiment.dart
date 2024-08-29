import 'package:flutter/material.dart';
import 'package:flutter_fhe_video_similarity/media/video.dart' show Thumbnail, FrameCount;
import 'package:flutter_fhe_video_similarity/media/manager.dart' show Manager;
import 'package:flutter_fhe_video_similarity/media/processor.dart';
import 'package:flutter_fhe_video_similarity/media/similarity.dart';

enum PreprocessState { idle, readCache, writeCache }

class PreprocessForm extends StatefulWidget {
  final Thumbnail thumbnail;

  const PreprocessForm({
    super.key,
    required this.thumbnail,
  });

  @override
  State<PreprocessForm> createState() => _PreprocessFormState();
}

class _PreprocessFormState extends State<PreprocessForm> {
  PreprocessType _type = PreprocessType.sso;
  FrameCount _frameCount = FrameCount.firstLast;
  PreprocessState _state = PreprocessState.readCache;
  final Manager _manager = Manager();
  bool _isCached = false;

  @override
  void initState() {
    super.initState();
    _reloadCache();
  }

  Widget preprocessTypeDropdown() {
    return DropdownButton<PreprocessType>(
      value: _type,
      onChanged: (PreprocessType? value) {
        setState(() {
          _type = value!;
          _state = PreprocessState.readCache;
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
      value: _frameCount,
      onChanged: (FrameCount? value) {
        setState(() {
          _frameCount = value!;
          _state = PreprocessState.readCache;
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
      _state = PreprocessState.idle;
      _isCached = _manager.isProcessed(widget.thumbnail.video, _type);
      print("Is cached? $_isCached");
    });
  }

  Future<void> _preprocess() async {
    setState(() {
      _state = PreprocessState.writeCache;
    });
    try {
      await _manager.storeProcessedVideoCSV(widget.thumbnail.video, _type, _frameCount);
    } on UnsupportedError catch (_) {
      print("Unsupported PreprocessType: ${_type.name}");
      // TODO: Show error message
    }
    setState(() {
      _reloadCache();
    });
  }

  Widget submit() {
    return Row(
      children: [
        (PreprocessState.idle == _state)
            ? ElevatedButton(
                onPressed: _preprocess,
                child: const Text("Preprocess"),
              )
            : const CircularProgressIndicator(),
      ],
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
          Row(children: [
            submit(),
            const SizedBox(width: 5),
            status(),
          ])
        ],
      ),
    );
  }
}

class Configure extends StatefulWidget {
  final Thumbnail thumbnail;

  const Configure({
    super.key,
    required this.thumbnail,
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
          PreprocessForm(thumbnail: widget.thumbnail),
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
  SimilarityType _similarityType = SimilarityType.kld;

  Widget similarityTypeDropdown() {
    return DropdownButton<SimilarityType>(
      value: _similarityType,
      onChanged: (SimilarityType? value) {
        setState(() {
          _similarityType = value!;
        });
      },
      items: SimilarityType.values
          .map((type) => DropdownMenuItem(
                value: type,
                child: Text(type.toString()),
              ))
          .toList(),
    );
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
                  child: Configure(thumbnail: widget.baseline),
                ),
                Expanded(
                  child: Configure(thumbnail: widget.comparison),
                ),
              ],
            ),
          ),
          // Comparison controls, centered
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Similarity Type: ", style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
              const SizedBox(width: 10),
              similarityTypeDropdown(),
            ]
          )
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 100,
        child: ListView(
          shrinkWrap: true,
          children: [
            ElevatedButton(
              onPressed: () async {
                final similarity = Similarity(SimilarityType.kld);
                int percentage = similarity.percentile(
                  await _manager.getCachedNormalized(
                      widget.baseline.video, PreprocessType.sso),
                  await _manager.getCachedNormalized(
                      widget.comparison.video, PreprocessType.sso),
                );
                setState(() {
                  _comparison = Text("${_similarityType.name.toUpperCase()}: $percentage% similar", style: const TextStyle(fontSize: 16));
                });
              },
              child: const Text("Compare"),
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
