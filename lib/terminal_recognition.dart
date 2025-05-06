import 'dart:io';
import 'package:flutter/material.dart';
import 'package:opencv_core/opencv.dart' as cv;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
class TerminalRecognition extends StatefulWidget {
  final String imagePath;

  const TerminalRecognition({super.key, required this.imagePath});

  @override
  State<TerminalRecognition> createState() => _TerminalRecognitionState();
}

class _TerminalRecognitionState extends State<TerminalRecognition> {
  late List<File> imageFiles = [];
  late List<String> imageFileNames = [];
  late List<List<int>> binaryMatrix = [];

  int imageCount = 1;
  int currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    imageFiles.add(File(widget.imagePath));
    imageFileNames.add("Original Image");
    _imageProcessing();
  }

  Future<void> _imageProcessing() async {
    await _grayScaleProcessing();
    await _adaptiveThresholding();
    debugPrint("${imageFileNames.length}");
  }

  Future<void> _grayScaleProcessing() async{
    try{
      cv.Mat image = cv.imread(widget.imagePath!, flags: cv.IMREAD_COLOR);
      cv.Mat grayScaleImage = cv.cvtColor(image, cv.COLOR_RGB2GRAY);

      var grayScaleEncodedImage = cv.imencode(".jpg", grayScaleImage).$2;

      final directory = await getTemporaryDirectory();
      final grayScalefilePath = '${directory.path}/processed_${DateTime.now().millisecondsSinceEpoch}.png';

      final grayScaleFile = File(grayScalefilePath);
      await grayScaleFile.writeAsBytes(grayScaleEncodedImage);

      setState(() {
        imageFiles.add(grayScaleFile);
        imageFileNames.add("Grayscale Image");
      });

      imageCount++;
      currentIndex = imageFiles.length - 1;

      debugPrint("Processed Image Saved: $grayScalefilePath");
    } catch(e) {
      debugPrint("Error grayscale processing image: $e");
    }
  }

  Future<void> _adaptiveThresholding() async{
    try{
      final grayScaleImageFile = imageFiles.last;
      cv.Mat grayMat = cv.imread(grayScaleImageFile.path, flags: cv.IMREAD_GRAYSCALE);

      cv.Mat thresholdedImage = cv.adaptiveThreshold(
        grayMat,
        255,
        cv.ADAPTIVE_THRESH_GAUSSIAN_C,
        cv.THRESH_BINARY_INV,
        11,
        2,
      );

      var encoded = cv.imencode(".jpg", thresholdedImage).$2;
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/adaptive_thresh_${DateTime.now().millisecondsSinceEpoch}.png';
      final thresholdedFile = File(filePath);
      await thresholdedFile.writeAsBytes(encoded);
      
      setState(() {
        imageFiles.add(thresholdedFile);
        imageFileNames.add("Adaptive Threshold");
      });

      imageCount++;
      currentIndex = imageFiles.length - 1;

      debugPrint("Adaptive Thresholded Image Saved: $filePath");
    } catch(e) {
      debugPrint("Error adaptive thresholding image: $e");
    }
  }

  void _nextImage() {
    if (currentIndex < imageFiles.length - 1) {
      setState(() {
        currentIndex++;
      });
    } else {
      setState(() {
        currentIndex = 0;
      });
    }
  }

  void _previousImage() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
      });
    } else {
      setState(() {
        currentIndex = imageFiles.length - 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terminal Recognition'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Display image based on currentIndex
          Expanded(
            child: Center(
              child: Image.file(imageFiles[currentIndex]),
            ),
          ),
          
          // Bottom row for processing and arrow buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: _previousImage,
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward),
                onPressed: _nextImage,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
