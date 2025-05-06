import 'dart:io';
import 'package:flutter/material.dart';

class TerminalRecognition extends StatelessWidget {
  final String? imagePath;

  const TerminalRecognition({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection'),
      ),
      body: Center(
        child: Image.file(
          File(imagePath!),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
