import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_fhe_video_similarity/logging.dart';

class LoadButton extends StatefulWidget {
  final Future<void> Function() onPressed;
  final String text;
  final bool timer;

  const LoadButton(
      {super.key,
      required this.onPressed,
      required this.text,
      this.timer = true});

  @override
  LoadButtonState createState() => LoadButtonState();
}

class LoadButtonState extends State<LoadButton> {
  bool isLoading = false;
  Timer? _timer;
  Duration _elapsedTime = Duration.zero;
  final Duration _interval = const Duration(milliseconds: 100);

  void _handleButtonPress() async {
    setState(() {
      isLoading = true;
      _elapsedTime = Duration.zero;
      _timer = Timer.periodic(_interval, (timer) {
        setState(() {
          _elapsedTime =
              Duration(milliseconds: timer.tick * _interval.inMilliseconds);
        });
      });
    });
    try {
      await widget.onPressed();
    } catch (e) {
      Logging().error('Error in LoadButton: $e');
      rethrow;
    } finally {
      setState(() {
        isLoading = false;
        _timer?.cancel();
      });
    }
  }
@override
@override
Widget build(BuildContext context) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      ElevatedButton(
        onPressed: isLoading ? null : _handleButtonPress,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(
            const Color.fromARGB(255, 0, 8, 44), // Background color
          ),
          side: MaterialStateProperty.all<BorderSide>(
            const BorderSide(
              color: Color.fromARGB(255, 0, 172, 252), // Light blue border color (RGBA equivalent of LightBlue)
              width: 2.0, // Border width
            ),
          ),
        ),
        child: !isLoading
            ? Text(
                widget.text,
                style: const TextStyle(color: Color.fromARGB(255, 0, 172, 252)), // Explicit text color
              )
            : const SizedBox(
                width: 24, // Set desired width
                height: 24, // Set desired height
                child: CircularProgressIndicator(
                  strokeWidth: 2, // Adjust stroke width as needed
                  color: Color.fromARGB(255,0, 172, 252),
                ),
              ),
      ),
      !widget.timer || _elapsedTime == Duration.zero
          ? const SizedBox.shrink()
          : Row(
              children: [
                const SizedBox(width: 5),
                Text(
                  '${_elapsedTime.inSeconds}.${(_elapsedTime.inMilliseconds % 1000) ~/ 100} s',
                  style: const TextStyle(
                    color: Color.fromARGB(255, 0, 172, 252), // Seconds text color
                  ),
                ),
              ],
            ),
    ],
  );
}
}