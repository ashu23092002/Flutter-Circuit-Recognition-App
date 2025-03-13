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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Last Picture'),),
      body: Expanded(child:Center(child: Image.file(File(widget.imagePath!)),)),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 10,
          children: [
            FloatingActionButton(
              heroTag: 'select_picture',
              onPressed: () {},
              child: IconTheme(
                data: IconThemeData(size: 40.0),
                child: const Icon(Icons.memory),
              ),
            ),
          ]
        ),
    );
  }
}
