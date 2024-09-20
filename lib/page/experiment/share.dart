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
      isEncrypted: true,
      isEncryptionDisabled: true,
    );
    checkShareButtonStatus();
  }

  void checkShareButtonStatus() {
    setState(() {
      _showShareButton = m.isProcessed(
          widget.thumbnail.video, _config.type, _config.frameCount);
    });
  }

  Future<XFile> serializedVideo(Config config) async {
    List<double> frames = await m.getCachedNormalized(
      widget.thumbnail.video,
      config.type,
      config.frameCount,
    );
    final videoDir = await m.getVideoWorkingDirectory(widget.thumbnail.video);
    final archiveName = '${config.type.name}-${config.frameCount.name}';
    final workingDir = '$videoDir/tmp';
    final archiveFile = await ExportCiphertextVideoZip(
            frames: frames,
            ctVideo: widget.thumbnail.video,
            session: config.encryptionSettings.session,
            tempDir: workingDir, // create a temp directory for video
            archivePath: '$videoDir/$archiveName.zip')
        .create();

    return XFile(archiveFile.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encrypt & Share Video'),
      ),
      body: Column(
        children: [
          ...videoInfo(widget.thumbnail.video),
          PreprocessForm(
            thumbnail: widget.thumbnail,
            config: _config,
            onConfigChange: (Config config) {
              _config = config;
              checkShareButtonStatus(); // Call the state update function
            },
            onVideoTrim: () {
              checkShareButtonStatus(); // Call the state update function
            },
            onFormSubmit: () {
              checkShareButtonStatus(); // Call the state update function
            },
            key: preprocessFormKey,
          )
        ],
      ),
      floatingActionButton: _showShareButton
          ? ShareFile(
              button: const FloatingActionButton(
                onPressed: null,
                child: Icon(Icons.share),
              ),
              file: serializedVideo(_config),
              subject: 'Share Encrypted Video',
            )
          : null,
    );
  }
}
