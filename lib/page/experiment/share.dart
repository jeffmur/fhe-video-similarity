// Preprocess, Encrypt, & Share a Video
import 'package:flutter/material.dart';
import 'package:flutter_fhe_video_similarity/media/manager.dart';
import 'package:flutter_fhe_video_similarity/media/video.dart';
import 'package:flutter_fhe_video_similarity/media/processor.dart';
import 'package:flutter_fhe_video_similarity/page/experiment/encrypt.dart';
import 'package:flutter_fhe_video_similarity/page/experiment/preprocess.dart';
import 'package:flutter_fhe_video_similarity/page/share_button.dart';
import 'package:flutter_fhe_video_similarity/media/video_encryption.dart';
import 'package:flutter_fhe_video_similarity/media/seal.dart';

class ShareVideo extends StatefulWidget {
  final Thumbnail thumbnail;

  const ShareVideo({
    super.key,
    required this.thumbnail,
  });

  @override
  State<ShareVideo> createState() => ShareVideoState();
}

class ShareVideoState extends State<ShareVideo> {
  GlobalKey<PreprocessFormState> preprocessFormKey = GlobalKey();
  final Manager m = Manager();

  late Config _config;
  late CiphertextVideo _videoEncryption;
  bool _showShareButton = false;

  @override
  void initState() {
    super.initState();
    _config = Config(
      PreprocessType.sso,
      FrameCount.firstLast,
      widget.thumbnail.video.startFrame,
      widget.thumbnail.video.endFrame,
      encryptionSettings: SessionChanges(),
    );
  }

  Future<void> serializedVideo(Config config) async {
    List<double> frames = await m.getCachedNormalized(
      widget.thumbnail.video,
      config.type,
      config.frameCount,
    );
    print("got frames");
    List<Ciphertext> ciphertext =
        config.encryptionSettings.session.encryptVecDouble(frames);

    _videoEncryption = CiphertextVideo(
        ciphertext,
        widget.thumbnail.video.created,
        widget.thumbnail.video.created.add(widget.thumbnail.video.duration),
        widget.thumbnail.video.hash);

    setState(() {
      _showShareButton = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Video'),
      ),
      body: Column(
        children: [
          // Video player?
          PreprocessForm(
            thumbnail: widget.thumbnail,
            config: _config,
            onFormSubmit: (Config config) {
              _config = config;
              serializedVideo(config);
            },
            onVideoTrim: () {},
            key: preprocessFormKey,
          )
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            if (_showShareButton)
              ShareString(
                text: _videoEncryption.base64String(),
                subject: "Encrypted Video",
              ),
          ],
        ),
      ),
    );
  }
}
