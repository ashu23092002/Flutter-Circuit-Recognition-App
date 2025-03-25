import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ObjectDetection extends StatefulWidget {
  
  final String? imagePath;
  const ObjectDetection({super.key, required this.imagePath});

  @override
  State<ObjectDetection> createState() => _ObjectDetectionState();
}

class _ObjectDetectionState extends State<ObjectDetection> {
  late Interpreter interpreter;
  List<dynamic>? outputs;
  List<Map<String, dynamic>> results = [];

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async{  
    try{
      interpreter = await Interpreter.fromFile(File("assets/models/yolo9.tflite"));
      dynamic inputTensorSize = await interpreter.getInputTensors();
      debugPrint("$inputTensorSize");
      // TfLiteType.kTfLiteUInt32
      debugPrint("Model Loaded");
    } catch(e) {
      debugPrint("Error loading model: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detection'),),
      body: Column(
        children: [
          Expanded(child:Center(child: Image.file(File(widget.imagePath!)),)),
          results.isNotEmpty
          ? Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text("Class: ${results[index]['class_id']}"),
                    subtitle:
                        Text("Confidence: ${results[index]['confidence']}"),
                  );
                },
              ),
            )
          : const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
