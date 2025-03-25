import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:circuit_recognition_app/src/tflite_flutter_helper.dart';
import 'package:image/image.dart' as img;

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

  late TensorImage _inputImage;
  late TensorBuffer _outputBuffer;

  late List<int> _inputShape;
  late List<int> _outputShape;

  late TensorType _inputType;
  late TensorType _outputType;
  late img.Image imageInput;
  
  late var _probabilityProcessor;
  
  File? _image;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async{  
    try{
      interpreter = await Interpreter.fromAsset("assets/models/yolo9.tflite");
      debugPrint("Model Loaded");
      
      _inputShape = interpreter.getInputTensor(0).shape;
      _outputShape = interpreter.getOutputTensor(0).shape;
      _inputType = interpreter.getInputTensor(0).type;
      _outputType = interpreter.getOutputTensor(0).type;
      
      _inputImage = TensorImage(TfLiteType.kTfLiteFloat32);

      _image = File(widget.imagePath!);
      imageInput = img.decodeImage(_image!.readAsBytesSync())!;
      _inputImage.loadImage(imageInput);
      
      try{
        await _runInference();
      } catch(e) {
        debugPrint("Error loading model: $e");
      }
    } catch(e) {
      debugPrint("Error loading model: $e");
    }
  }

  Future<void> _runInference() async{
    try{
      _inputImage = _preProcess();
      debugPrint("Pre-processed image");
      _outputBuffer = TensorBuffer.createFixedSize(_outputShape, TfLiteType.kTfLiteFloat32);

      interpreter.run(_inputImage.buffer, _outputBuffer.getBuffer());
      debugPrint("Ran Inference");

      debugPrint("${_outputBuffer.getShape()}");
    } catch(e) {
      debugPrint("Error running inference: $e");
    }   
  }

  TensorImage _preProcess() {
    return ImageProcessorBuilder()
        .add(ResizeOp(
            _inputShape[1], _inputShape[2], ResizeMethod.NEAREST_NEIGHBOUR))
        .build()
        .process(_inputImage);
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
