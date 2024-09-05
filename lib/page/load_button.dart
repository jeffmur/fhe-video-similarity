import 'package:flutter/material.dart';

class LoadButton extends StatefulWidget {
  final Future<void> Function() onPressed;
  final String text;

  const LoadButton({super.key, required this.onPressed, required this.text});

  @override
  LoadButtonState createState() => LoadButtonState();
}

class LoadButtonState extends State<LoadButton> {
  bool isLoading = false;

  void _handleButtonPress() async {
    setState(() {
      isLoading = true;
    });
    try {
      await widget.onPressed();
    } catch (e) {
      print('Error: $e');
      rethrow;
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print(isLoading);
    return ElevatedButton(
      onPressed: isLoading ? null : _handleButtonPress,
      child: !isLoading
          ? Text(widget.text)
          : const SizedBox( // Wrap CircularProgressIndicator in SizedBox
              width: 24,    // Set desired width
              height: 24,   // Set desired height
              child: CircularProgressIndicator(
                strokeWidth: 2, // Adjust stroke width as needed
              ),
            )
    );
  }
}
