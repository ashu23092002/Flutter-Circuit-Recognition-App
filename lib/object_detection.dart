import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
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
      debugPrint("Model Loaded");
    } catch(e) {
      debugPrint("Error loading model: $e");
    }
  }

  Future<void> _runInference() async {
    var input = await preprocessImage(widget.imagePath!);
    var output = List.filled(1 * 8 * 8400, 0).reshape([1, 8, 8400]);

    interpreter.run(input, output);
    setState(() {
      results = parseDetections(output);
    });
  }

  List<Map<String, dynamic>> parseDetections(List output) {
    List<Map<String, dynamic>> results = [];

    for (int i = 0; i < 8400; i++) {
      double confidence = output[0][4][i];
      if (confidence > 0.5) {
        results.add({
          'x_min': output[0][0][i] * 640,
          'y_min': output[0][1][i] * 640,
          'x_max': output[0][2][i] * 640,
          'y_max': output[0][3][i] * 640,
          'confidence': confidence,
          'class_id': output[0][5][i].toInt(),
        });
      }
    }
    return results;
  }

  Future<Float32List> preprocessImage(String imagePath) async {
    File imageFile = File(imagePath);
    List<int> imageBytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(Uint8List.fromList(imageBytes));

    if (image == null) {
      throw Exception("Error decoding image");
    }

    img.Image resizedImage = img.copyResize(image, width: 640, height: 640);

    var input = Float32List(1 * 640 * 640 * 3);
    int pixelIndex = 0;

    for (int y = 0; y < 640; y++) {
      for (int x = 0; x < 640; x++) {
        var pixel = resizedImage.getPixel(x, y);
        input[pixelIndex++] = pixel.r / 255.0;
        input[pixelIndex++] = pixel.g / 255.0;
        input[pixelIndex++] = pixel.b / 255.0;
      }
    }
    return input;
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
