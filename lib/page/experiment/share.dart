import 'package:flutter/material.dart';
import 'package:flutter_fhe_video_similarity/logging.dart';
import 'package:flutter_fhe_video_similarity/media/manager.dart';
import 'package:flutter_fhe_video_similarity/media/share_encryption_archive.dart';
import 'package:flutter_fhe_video_similarity/media/video.dart';
import 'package:flutter_fhe_video_similarity/page/experiment/encrypt.dart';
import 'package:flutter_fhe_video_similarity/page/experiment/preprocess.dart';
import 'package:flutter_fhe_video_similarity/page/logs.dart';
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
    DateTime startArchive = DateTime.now();
    return ExportCiphertextVideoZip(
            frames: frames,
            ctVideo: widget.thumbnail.video,
            session: config.encryptionSettings.session,
            tempDir: workingDir, // create a temp directory for video
            archivePath: '$videoDir/$archiveName.zip')
        .create()
        .then((file) {
      String archiveTook = nonZeroDuration(DateTime.now().difference(startArchive));
      Logging().metric(
          '📦 Packaged encrypted archive in $archiveTook',
          correlationId: widget.thumbnail.video.stats.id);
      return XFile(file.path);
    });
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const FittedBox(
        fit: BoxFit.fitWidth,
        child: Text(
          'Encrypt & Share Video',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 0, 0, 0), // Make text stand out
          ),
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 0, 172, 252), // Set AppBar background color
      actions: [
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoggingPage()));
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                  const Color.fromARGB(255, 8, 0, 44), // Button background color
                ),
                foregroundColor: MaterialStateProperty.all(
                  const Color.fromARGB(255, 0, 172, 252), // Button text color
                ),
                textStyle: MaterialStateProperty.all(
                  const TextStyle(fontFamily: 'SourceCodePro', fontWeight: FontWeight.bold
                  ),
                ),
              ),
              child: const Text('View Logs' ),
            ),
          ],
        ),
      ],
    ),
    backgroundColor: const Color.fromARGB(255, 8, 0, 44), // Set the background color of the Scaffold
    body: Column(
      children: [
        const SizedBox(height:16),
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
        ),
      ],
    ),
    floatingActionButton: _showShareButton
        ? ShareFileFloatingActionButton(file: serializedVideo(_config))
        : null,
  );
}
}