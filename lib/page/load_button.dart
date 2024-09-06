import 'package:flutter/material.dart';
import 'dart:async';

class LoadButton extends StatefulWidget {
  final Future<void> Function() onPressed;
  final String text;
  final bool timer;

  const LoadButton({super.key, required this.onPressed, required this.text, this.timer = true});

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
      print('Error: $e');
      rethrow;
    } finally {
      setState(() {
        isLoading = false;
        _timer?.cancel();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: isLoading ? null : _handleButtonPress,
          child: !isLoading
              ? Text(widget.text)
              : const SizedBox(
                  // Wrap CircularProgressIndicator in SizedBox
                  width: 24, // Set desired width
                  height: 24, // Set desired height
                  child: CircularProgressIndicator(
                    strokeWidth: 2, // Adjust stroke width as needed
                  ),
                ),
        ),
        !widget.timer || _elapsedTime == Duration.zero
            ? const SizedBox.shrink()
            : Row(children: [
                const SizedBox(width: 5),
                Text('${_elapsedTime.inSeconds}.${(_elapsedTime.inMilliseconds % 1000) ~/ 100} s'),
              ]
            )
      ],
    );
  }
}
