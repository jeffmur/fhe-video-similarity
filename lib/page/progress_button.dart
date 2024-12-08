import 'package:flutter/material.dart';
import 'dart:async';

class ProgressButton extends StatefulWidget {
  final Future<void> Function() onPressed;
  final String text;

  const ProgressButton({required this.onPressed, required this.text, Key? key}) : super(key: key);

  @override
  _ProgressButtonState createState() => _ProgressButtonState();
}

class _ProgressButtonState extends State<ProgressButton> {
  bool _isLoading = false;
  double _progress = 0.0;

  void _startTask() async {
    setState(() {
      _isLoading = true;
      _progress = 0.0;
    });

    // Simulate progress update
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _progress += 0.01;
        if (_progress >= 1.0) {
          timer.cancel();
        }
      });
    });

    await widget.onPressed();

    setState(() {
      _isLoading = false;
      _progress = 1.0;
    });

    // Hide progress bar after a delay
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _progress = 0.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _startTask,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(12), // Adjust padding to make the button more compact
        shape: const CircleBorder(), // Make the button circular
      ),
      child: _isLoading
          ? Stack(
              alignment: Alignment.center,
              children: [
                // Circular Progress Bar
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color.fromARGB(255, 0, 172, 252),
                    ),
                    strokeWidth: 6,
                  ),
                ),
                // Percentage Text above the progress bar
                Positioned(
                  top: 15,
                  child: Text(
                    '${(_progress * 100).round()}%',
                    style: const TextStyle(
                      color: Color.fromARGB(255, 0, 174, 255),
                      fontWeight: FontWeight.bold,
                      fontSize: 12, // Adjust font size to fit the button size
                    ),
                  ),
                ),
              ],
            )
          : Text(widget.text),
    );
  }
}
