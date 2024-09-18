// Preprocess, Encrypt, & Share a Video
import 'package:flutter/material.dart';
import 'package:flutter_fhe_video_similarity/media/manager.dart';
import 'package:flutter_fhe_video_similarity/media/video.dart';
import 'package:flutter_fhe_video_similarity/media/video_encryption.dart';
import 'package:flutter_fhe_video_similarity/page/experiment/encrypt.dart';
import 'package:flutter_fhe_video_similarity/page/experiment/preprocess.dart';
import 'package:flutter_fhe_video_similarity/page/share_button.dart';

class ShareArchive extends StatefulWidget {
  final Thumbnail thumbnail;

  const ShareArchive({
    super.key,
    required this.thumbnail,
  });

  @override
  State<ShareArchive> createState() => ShareArchiveState();
}

class ShareArchiveState extends State<ShareArchive> {
  GlobalKey<PreprocessFormState> preprocessFormKey = GlobalKey();
  final Manager m = Manager();

  late Config _config;
  late XFile videoArchive;
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
    final videoDir = await m.getVideoWorkingDirectory(widget.thumbnail.video);
    final workingDir = '$videoDir/tmp';
    final archiveFile = await ExportCiphertextVideoZip(
            frames: frames,
            ctVideo: CiphertextVideo(
              video: widget.thumbnail.video,
              startTime: widget.thumbnail.video.created,
              endTime: widget.thumbnail.video.created
                  .add(widget.thumbnail.video.duration),
              hash: widget.thumbnail.video.hash,
            ),
            session: config.encryptionSettings.session,
            tempDir: workingDir, // create a temp directory for video
            archivePath: '$videoDir/archive.zip')
        .create();

    videoArchive = XFile(archiveFile.path);

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
              ShareFile(subject: "Archive", file: videoArchive)
          ],
        ),
      ),
    );
  }
}
