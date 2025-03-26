import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

import 'package:circuit_recognition_app/src/tflite_flutter_helper.dart';
import 'package:circuit_recognition_app/utils/nms.dart';

class ObjectDetection extends StatefulWidget {
  
  final String? imagePath;
  const ObjectDetection({super.key, required this.imagePath});

  @override
  State<ObjectDetection> createState() => _ObjectDetectionState();
}

class _ObjectDetectionState extends State<ObjectDetection> {
  late Interpreter interpreter;
  List<dynamic>? outputs;

  late TensorImage _inputImage;
  late TensorBuffer _outputBuffer;

  late List<int> _inputShape;
  late List<int> _outputShape;

  final int _inputType = TfLiteType.kTfLiteFloat32;
  final int _outputType = TfLiteType.kTfLiteFloat32;

  late img.Image imageInput;
  
  late List<double> outputList;
  
  late List<List<double>> reshapedList = [];
  File? _image;

  late List<List<double>> labelledData = [];
  bool showReshapedList = true;

  @override
  void initState() {
    super.initState();
    _image = File(widget.imagePath!);
    _loadModel();
  }

  Future<void> _loadModel() async{  
    try{
      interpreter = await Interpreter.fromAsset("assets/models/yolo9.tflite");
      debugPrint("Model Loaded");
      
      _inputShape = interpreter.getInputTensor(0).shape;
      _outputShape = interpreter.getOutputTensor(0).shape;

      _inputImage = TensorImage(_inputType);

      
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
      _outputBuffer = TensorBuffer.createFixedSize(_outputShape, _outputType);

      interpreter.run(_inputImage.buffer, _outputBuffer.getBuffer());
      debugPrint("Ran Inference");

      outputList = _outputBuffer.getDoubleList();

      await _processOutput();
      debugPrint("Output Process: Reshaped List Extracted");
      debugPrint("Original Image Size: ${imageInput.height}, ${imageInput.width}");
      labelledData = await nonMaximumSuppression(
        reshapedList,
        originalImageSize: [imageInput.height, imageInput.width],
      );

      
      debugPrint("Output Process: Labelled Data Extracted");
      debugPrint("Element Count: ${labelledData.length}");
      setState(() {});
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

  Future<void> _processOutput() async{
    int numAnchors = _outputShape[2]; // 8400
    int featureSize = _outputShape[1]; // 8

    for (int i = 0; i < numAnchors; i++) {
      reshapedList.add(outputList.sublist(i * featureSize, (i + 1) * featureSize));
    }
  }

  @override
  Widget build(BuildContext context) {
    List<List<double>> currentList = showReshapedList ? reshapedList : labelledData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() => showReshapedList = showReshapedList ? false : true);
            },
            icon: const Icon(Icons.arrow_left),
          ),
          IconButton(
            onPressed: () {
              setState(() => showReshapedList = showReshapedList ? false : true);
            },
            icon: const Icon(Icons.arrow_right),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child:Center(
              child: Image.file(File(widget.imagePath!)),
            )
          ),
          Text(
            "Original Image",
          ),
          currentList.isNotEmpty
          ? Expanded(
            child: ListView.builder(
              itemCount: currentList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text("$index."),
                  subtitle: Text("Values: ${currentList[index].join(", ")}"),
                );
              }
            )
          )
          : Row(
            children: [
              const Center(child: CircularProgressIndicator()),
              const Text("Detecting"),
            ],
          ),
          Text(
            showReshapedList ? "Reshaped List" : "Labelled Data",
          ),
        ],
      ),
    );
  }
}
