import 'package:circuit_recognition_app/object_detection.dart';
import 'package:circuit_recognition_app/terminal_recognition.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class DisplayPictureScreen extends StatefulWidget {
  final String? imagePath;
  ///Display Last Picture
  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  late List<FileSystemEntity> imageFiles;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    final file = File(widget.imagePath!);
    final directory = file.parent;
    imageFiles = directory
        .listSync()
        .where((f) => f is File && _isImage(f.path))
        .toList();
    currentIndex = imageFiles.indexWhere((f) => f.path == widget.imagePath);
  }

  bool _isImage(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png');
  }

  void _showImageAtIndex(int index) {
    if (index >= 0 && index < imageFiles.length) {
      setState(() {
        currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentImage = imageFiles[currentIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('Gallery'),),
      body: Center(
        child: Image.file(File(currentImage.path!)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'previous',
            onPressed: currentIndex > 0
              ? () => _showImageAtIndex(currentIndex - 1)
              : null,
            tooltip: 'Previous Image',
            child: const Icon(Icons.arrow_back),
          ),
          const SizedBox(height: 10,),
          FloatingActionButton(
            heroTag: 'next',
            onPressed: currentIndex < imageFiles.length - 1
              ? () => _showImageAtIndex(currentIndex + 1)
              : null,
            tooltip: 'Next Image',
            child: const Icon(Icons.arrow_forward),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'object_detection',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ObjectDetection(imagePath: currentImage.path),
                ),
              );
            },
            tooltip: 'Run Object Detection',
            child: const Icon(Icons.memory),
          ),
          const SizedBox(height: 10,),
          FloatingActionButton(
            heroTag: 'terminal_recognition',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => 
                    TerminalRecognition(imagePath: currentImage.path),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
