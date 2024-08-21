import 'package:flutter/material.dart';
import 'package:flutter_fhe_video_similarity/media/video.dart' show Thumbnail;
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
  PreprocessType _selected = PreprocessType.sso;
  PreprocessState _state = PreprocessState.readCache;
  final Manager _manager = Manager();
  bool _isCached = false;

  @override
  void initState() {
    super.initState();
    _reloadCache();
  }

  Widget _buildDropdown() {
    return DropdownButton<PreprocessType>(
      value: _selected,
      onChanged: (PreprocessType? value) {
        setState(() {
          _selected = value!;
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

  void _reloadCache() {
    setState(() {
      _state = PreprocessState.idle;
      _isCached = _manager.isProcessed(widget.thumbnail.video, _selected);
      print("Is cached? $_isCached");
    });
  }

  Future<void> _preprocess() async {
    setState(() {
      _state = PreprocessState.writeCache;
    });
    try {
      await _manager.storeProcessedVideoCSV(widget.thumbnail.video, _selected);
    } on UnsupportedError catch (_) {
      print("Unsupported PreprocessType: ${_selected.name}");
      // TODO: Show error message
    }
    setState(() {
      _reloadCache();
    });
  }

  Widget _buildButton() {
    return Row(
      children: [
        if ([PreprocessState.readCache, PreprocessState.writeCache]
            .contains(_state))
          const CircularProgressIndicator(),

        if (!_isCached && PreprocessState.idle == _state)
          ElevatedButton(
            onPressed: _preprocess,
            child: const Text("Preprocess"),
          ),

        if (_isCached && PreprocessState.idle == _state) // Processed
          const Icon(Icons.check, color: Colors.green), // Green checkmark
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          const Text("Algorithm: ",
              style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic)),
          const SizedBox(width: 10),
          _buildDropdown(),
          const SizedBox(width: 10),
          _buildButton(),
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
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Text("${widget.thumbnail.video.stats.toJson()}"),
                // Video player?
                PreprocessForm(thumbnail: widget.thumbnail),
              ],
            ),
          ),
          // Preprocessing controls
          // Close button
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
          // Comparison controls
          ElevatedButton(
            onPressed: () async {
              final similarity = Similarity(SimilarityType.kld);
              int percentage = similarity.percentile(
                await _manager.getCachedNormalized(widget.baseline.video, PreprocessType.sso),
                await _manager.getCachedNormalized(widget.comparison.video, PreprocessType.sso),
              );
              setState(() {
                _comparison = Text("$percentage% similar");
              });
            },
            child: const Text("Compare"),
          ),
          const SizedBox(height: 10),
          // Log output
          Expanded(
            child: ListView(
              children: [
                // Log messages
                _comparison ?? const Text("No comparison yet"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
