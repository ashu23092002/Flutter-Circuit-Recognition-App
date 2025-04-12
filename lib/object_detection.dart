import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

import 'package:circuit_recognition_app/src/tflite_flutter_helper.dart';
import 'package:opencv_core/opencv.dart' as cv;
import 'package:circuit_recognition_app/utils/nms.dart';

class ObjectDetection extends StatefulWidget {
  final String? imagePath;
  const ObjectDetection({super.key, required this.imagePath});

  @override
  State<ObjectDetection> createState() => _ObjectDetectionState();
}

class _ObjectDetectionState extends State<ObjectDetection> {
  late List<File?> imageFiles = [];
  late List<String> imageLabel = [];
  late int currentIndex;

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
    imageFiles.add(_image);
    imageLabel.add("Original Image");
    currentIndex = 0;
    _loadModel();
  }

  Future<void> _loadModel() async{  
    try{
      interpreter = await Interpreter.fromAsset("assets/models/yolo11.tflite");
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

      labelledData = await nonMaximumSuppression(
        reshapedList,
        originalImageSize: [imageInput.height, imageInput.width],
        confidenceThreshold: 0.99999999,
      );
      
      debugPrint("Output Process: Labelled Data Extracted");
      debugPrint("Element Count: ${labelledData.length}");

      await _grayScaleProcessing();

      await _drawBoundingBoxes();

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
    // // NMS output
    // int numDetections = _outputShape[1]; // 300 detections
    // int featureSize = _outputShape[2];   // 6 Features per detection

    // reshapedList.clear();
    // for (int i = 0; i < numDetections; i++) {
    //   List<double> boxData = [];
    //   for (int j = 0; j < featureSize; j++) {
    //     boxData.add(outputList[i * featureSize + j]);
    //   }
    //   reshapedList.add(boxData);
    // }

    // No NMS output
    int numAnchors = _outputShape[2]; // 8400
    int featureSize = _outputShape[1]; // 8

    for (int i = 0; i < numAnchors; i++) {
      reshapedList.add(outputList.sublist(i * featureSize, (i + 1) * featureSize));
    }
  }

  Future<void> _grayScaleProcessing() async{
    try{
      cv.Mat image = cv.imread(widget.imagePath!, flags: cv.IMREAD_COLOR);
      cv.Mat grayScaleImage = await cv.cvtColor(image, cv.COLOR_RGB2GRAY);

      var grayScaleEncodedImage = cv.imencode(".jpg", grayScaleImage).$2;

      final directory = await getTemporaryDirectory();
      final grayScalefilePath = '${directory.path}/processed_${DateTime.now().millisecondsSinceEpoch}.png';

      final grayScaleFile = File(grayScalefilePath);
      await grayScaleFile.writeAsBytes(grayScaleEncodedImage);

      setState(() {
        imageFiles.add(grayScaleFile);
        imageLabel.add("Grayscale Image");
      });

      debugPrint("Processed Image Saved: $grayScalefilePath");
    } catch(e) {
      debugPrint("Error processing image: $e");
    }
  }

  Future<void> _drawBoundingBoxes() async{
    try{
      Map<int, cv.Scalar> colorMap = {};
      Random random = Random();

      cv.Mat originalImage = cv.imread(widget.imagePath!, flags: cv.IMREAD_COLOR);
      
      for(var box in labelledData) {
        int x1 = box[0].toInt(); // Top-left X
        int y1 = box[1].toInt(); // Top-left Y
        int x2 = box[2].toInt(); // Bottom-right X
        int y2 = box[3].toInt(); // Bottom-right Y
        int classId = box[5].toInt(); // Class ID
        // debugPrint("$classId");

        if (!colorMap.containsKey(classId)) {
          colorMap[classId] = cv.Scalar(
            random.nextInt(256).toDouble(),  // B
            random.nextInt(256).toDouble(),  // G
            random.nextInt(256).toDouble(),  // R
          );
        }

        cv.Scalar boxColor = colorMap[classId]!;
        cv.Rect boundingBox = cv.Rect(x1, y1, x2 - x1, y2 - y1);
        cv.rectangle(originalImage, boundingBox, boxColor, thickness: 2);
      }

      debugPrint("Color Map:");
      colorMap.forEach((classId, color) {
        debugPrint("Class $classId -> Color (BGR): ($color)");
      });

      var predictedEncodedImage = cv.imencode(".jpg", originalImage).$2;

      final directory = await getTemporaryDirectory();
      final predictedfilePath = '${directory.path}/processed_${DateTime.now().millisecondsSinceEpoch}.png';

      final predictedImageFile = File(predictedfilePath);
      await predictedImageFile.writeAsBytes(predictedEncodedImage);

      setState(() {
        imageFiles.add(predictedImageFile);
        imageLabel.add("Predicted Image");
      });

      debugPrint("Drawn bounding boxes: $predictedfilePath");
    } catch(e) {
      debugPrint("Error drawing bounding box: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    List<List<double>> currentList = showReshapedList ? reshapedList : labelledData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection'),
      ),
      body: Column(
        children: [
          Expanded(
            child:Center(
              child: Image.file(imageFiles[currentIndex]!),
            )
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    if(currentIndex > 0) {
                      currentIndex--;
                    } else {
                      currentIndex = imageFiles.length - 1;
                    }
                  });
                },
                icon: const Icon(Icons.arrow_left),
              ),
              Text(
                imageLabel[currentIndex],
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    if(currentIndex < imageFiles.length - 1) {
                      currentIndex++;
                    } else {
                      currentIndex = 0;
                    }
                  });
                },
                icon: const Icon(Icons.arrow_right),
              ),
            ],
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  setState(() => showReshapedList = !showReshapedList);
                },
                icon: const Icon(Icons.arrow_left),
              ),
              Text(
                showReshapedList ? "Reshaped List" : "Labelled Data",
              ),
              IconButton(
                onPressed: () {
                  setState(() => showReshapedList = !showReshapedList);
                },
                icon: const Icon(Icons.arrow_right),
              ),
              
            ] 
          ),
        ],
      ),
    );
  }
}
