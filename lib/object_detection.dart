import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
// import 'package:path_provider/path_provider.dart';

// import 'package:opencv_core/opencv.dart' as cv;
import 'package:image/image.dart' as img;

import 'package:circuit_recognition_app/utils/yolo.dart';
import 'package:circuit_recognition_app/utils/bbox.dart';
import 'package:circuit_recognition_app/utils/labels.dart';
class ObjectDetection extends StatefulWidget {
  final String? imagePath;
  const ObjectDetection({super.key, required this.imagePath});

  @override
  State<ObjectDetection> createState() => _ObjectDetectionState();
}

class _ObjectDetectionState extends State<ObjectDetection> {
  static const inModelWidth = 640;
  static const inModelHeight = 640;
  final int numClasses = labels.length;
  static const double maxImageWidgetHeight = 400;

  double confidenceThreshold = 0.1;
  double iouThreshold = 0.1;
  bool agnosticNMS = true;
  bool isLoading = true;

  late int currentIndex;
  
  late List<File?> imageFiles = [];
  late List<String> imageFileNames = [];
  
  List<List<double>>? inferenceOutput;
  List<int> classes = [];
  List<List<double>> bboxes = [];
  List<double> scores = [];
  
  int? imageWidth;
  int? imageHeight;

  File? _image;

  bool showReshapedList = true;

  late final YoloModel model;

  @override
  void initState() {
    super.initState();
    model = YoloModel(
      'assets/models/yolov8_electronic-circuits-ifz6c.tflite',
      inModelWidth,
      inModelHeight,
      labels.length,
    );
    model.init();
    _image = File(widget.imagePath!);
    imageFiles.add(_image);
    imageFileNames.add("Original Image");
    currentIndex = 0;
    _runInference();
  }

  Future<void> _runInference() async{
    final image = img.decodeImage(await _image!.readAsBytes());
    imageWidth = image!.width;
    imageHeight = image.height;
    inferenceOutput = model.infer(image);
    updatePostprocess();
    setState(() {
      isLoading = false;
    });
  }

  // Future<void> _grayScaleProcessing() async{
  //   try{
  //     cv.Mat image = cv.imread(widget.imagePath!, flags: cv.IMREAD_COLOR);
  //     cv.Mat grayScaleImage = cv.cvtColor(image, cv.COLOR_RGB2GRAY);

  //     var grayScaleEncodedImage = cv.imencode(".jpg", grayScaleImage).$2;

  //     final directory = await getTemporaryDirectory();
  //     final grayScalefilePath = '${directory.path}/processed_${DateTime.now().millisecondsSinceEpoch}.png';

  //     final grayScaleFile = File(grayScalefilePath);
  //     await grayScaleFile.writeAsBytes(grayScaleEncodedImage);

  //     setState(() {
  //       imageFiles.add(grayScaleFile);
  //       imageFileNames.add("Grayscale Image");
  //     });

  //     debugPrint("Processed Image Saved: $grayScalefilePath");
  //   } catch(e) {
  //     debugPrint("Error processing image: $e");
  //   }
  // }

  
  @override
  Widget build(BuildContext context) {
    if(isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    final bboxesColors = List<Color>.generate(
      numClasses,
      (_) => Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0),
    );
    final double displayWidth = MediaQuery.of(context).size.width;
    double resizeFactor = 1;
    
    if (imageWidth != null && imageHeight != null) {
      double k1 = displayWidth / imageWidth!;
      double k2 = maxImageWidgetHeight / imageHeight!;
      resizeFactor = min(k1, k2);
    }

    List<Bbox> bboxesWidgets = [];
    for (int i = 0; i < bboxes.length; i++) {
      final box = bboxes[i];
      final boxClass = classes[i];
      bboxesWidgets.add(
        Bbox(
            box[0] * resizeFactor,
            box[1] * resizeFactor,
            box[2] * resizeFactor,
            box[3] * resizeFactor,
            labels[boxClass],
            scores[i],
            bboxesColors[boxClass]),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Object Detection'),
      ),
      body:
        Column(
          children: [
            SizedBox(
              width: imageWidth! * resizeFactor,
              height: imageHeight! * resizeFactor,
              child: Stack(
                children: [
                  Image.file(
                    imageFiles[currentIndex]!,
                    width: imageWidth! * resizeFactor,
                    height: imageHeight! * resizeFactor,
                    fit: BoxFit.fill, // ensures it uses the same scaling
                  ),
                  ...bboxesWidgets,
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Index')),
                    DataColumn(label: Text('Label')),
                    DataColumn(label: Text('Confidence')),
                    DataColumn(label: Text('X')),
                    DataColumn(label: Text('Y')),
                    DataColumn(label: Text('Width')),
                    DataColumn(label: Text('Height')),
                  ], 
                  rows: List.generate(bboxes.length, (index) {
                    final classIndex = classes[index];
                    final label = labels[classIndex];
                    final score = scores[index];
                    final box = bboxes[index];

                    final x = box[0].toStringAsFixed(1);
                    final y = box[1].toStringAsFixed(1);
                    final width = box[2].toStringAsFixed(1);
                    final height = box[3].toStringAsFixed(1);

                    return DataRow(
                      cells: [
                        DataCell(Text('${index + 1}')),
                        DataCell(Text(label)),
                        DataCell(Text('${(score * 100).toStringAsFixed(1)}%')),
                        DataCell(Text(x)),
                        DataCell(Text(y)),
                        DataCell(Text(width)),
                        DataCell(Text(height)),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
    );
  }

  void updatePostprocess() {
    if (inferenceOutput == null) {
      return;
    }

    List<int> newClasses = [];
    List<List<double>> newBboxes = [];
    List<double> newScores = [];
    (newClasses, newBboxes, newScores) = model.postprocess(
      inferenceOutput!,
      imageWidth!,
      imageHeight!,
      confidenceThreshold: confidenceThreshold,
      iouThreshold: iouThreshold,
      agnostic: agnosticNMS,
    );
    setState(() {
      classes = newClasses;
      bboxes = newBboxes;
      scores = newScores;
    });
  }
}
