import 'dart:io';
import 'dart:math';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:opencv_core/opencv.dart' as cv;
import 'package:image/image.dart' as img;

import 'package:circuit_recognition_app/utils/yolo.dart';
import 'package:circuit_recognition_app/utils/bbox.dart';
import 'package:circuit_recognition_app/utils/labels.dart';

class Component{
  String id;
  List<List<List<int>>> terminals;
  
  Component(this.id, this.terminals);
}

class Net {
  final String netId;
  final List<String> connectedTerminals; // Format: "ComponentId.TerminalIndex"
  Net(this.netId, this.connectedTerminals);
}
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
  bool showBoundingBoxes = true;

  late int currentIndex;
  
  late List<File?> imageFiles = [];
  late List<String> imageFileNames = [];
  late List<int> labelCounter = [];

  List<List<double>>? inferenceOutput;
  List<int> classes = [];
  List<List<double>> bboxes = [];
  List<double> scores = [];
  List<Component> circuitComponents = [];

  int? imageWidth;
  int? imageHeight;

  File? _image;

  bool showReshapedList = true;

  late final YoloModel model;

  @override
  void initState() {
    super.initState();
    labelCounter = List.filled(labels.length, 0);
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
    _initializeProcessing();
    
  }

  Future<void> _initializeProcessing() async{
    await _runInference();
    await _grayScaleProcessing();
    await _adaptiveThresholding();
    await _terminalRecognition();
    // final imageWires = imageFiles.last;
    // cv.Mat imageWireMat = cv.imread(imageWires!.path, flags: cv.IMREAD_GRAYSCALE);
    // final netlist = await generateNetlist(imageWireMat, circuitComponents);
    
    // for (final net in netlist) {
    //   debugPrint('${net.netId}: ${net.connectedTerminals.join(', ')}');
    // }
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

  Future<List<Net>> generateNetlist(cv.Mat wireImage, List<Component> components) async {
    final height = wireImage.rows;
    final width = wireImage.cols;

    // Convert image to binary: white = wire pixel (255), black = background (0)
    final wirePixels = <Offset>{};
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (wireImage.at<int>(y, x) > 128) {
          wirePixels.add(Offset(x.toDouble(), y.toDouble()));
        }
      }
    }

    // Build terminal point map: Offset -> "ComponentId.TerminalIndex"
    final terminalPointMap = <Offset, String>{};
    for (final component in components) {
      for (int t = 0; t < component.terminals.length; t++) {
        final terminalPixels = component.terminals[t];
        for (final p in terminalPixels) {
          final offset = Offset(p[0].toDouble(), p[1].toDouble());
          terminalPointMap[offset] = '${component.id}.$t';
        }
      }
    }

    final visited = <Offset>{};
    final netlist = <Net>[];
    int netCount = 1;

    for (final start in terminalPointMap.keys) {
      if (visited.contains(start)) continue;

      final connected = <String>{};
      final stack = Queue<Offset>();
      stack.add(start);
      visited.add(start);

      while (stack.isNotEmpty) {
        final current = stack.removeLast();

        // If it's a terminal, add to net
        if (terminalPointMap.containsKey(current)) {
          connected.add(terminalPointMap[current]!);
        }

        // Explore 4-connected neighbors
        for (final dx in [-1, 0, 1]) {
          for (final dy in [-1, 0, 1]) {
            if ((dx.abs() + dy.abs()) != 1) continue; // skip diagonals & self
            final nx = current.dx + dx;
            final ny = current.dy + dy;
            final neighbor = Offset(nx, ny);

            if (nx < 0 || ny < 0 || nx >= width || ny >= height) continue;
            if (!wirePixels.contains(neighbor)) continue;
            if (visited.contains(neighbor)) continue;

            visited.add(neighbor);
            stack.add(neighbor);
          }
        }
      }

      if (connected.length >= 2) {
        final netId = 'N${netCount.toString().padLeft(3, '0')}';
        netlist.add(Net(netId, connected.toList()));
        netCount++;
      }
    }

    return netlist;
  }

  Future<void> _terminalRecognition() async{
    final imageWires = imageFiles.last;
    cv.Mat imageWireMat = cv.imread(imageWires!.path, flags: cv.IMREAD_COLOR);

    for (int i = 0; i < bboxes.length; i++) {
      if(labels[classes[i]] == "junction") {
        continue;
      }
      // Zero out the region
      int x = (bboxes[i][0] - bboxes[i][2] / 2).toInt();
      int y = (bboxes[i][1] - bboxes[i][3] / 2).toInt();
      int width = bboxes[i][2].toInt();
      int height = bboxes[i][3].toInt();

      // Suppress Circuit Element
      var roi = imageWireMat.region(cv.Rect(x, y, width, height));
      
      roi.setTo(cv.Scalar.black);
      
      if(labels[classes[i]] == "text") {
        continue;
      }
      
      labelCounter[classes[i]]++;
      String componentId = '${labels[classes[i]]}${labelCounter[classes[i]]}';
      late List<List<List<int>>> componentTerminals;
      componentTerminals = await _terminalLocalization(bboxes[i]);

      for(List<List<int>> coord in componentTerminals) {
        for(List<int> point in coord) {
          int cx = point[0], cy = point[1];

          cv.circle(
            imageWireMat, 
            cv.Point(cx, cy), 
            3, 
            cv.Scalar.green,
            thickness: -1,
          );
        }
      }

      circuitComponents.add(
        Component(componentId, componentTerminals)
      );
    }

    var encoded = cv.imencode(".jpg", imageWireMat).$2;
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/terminal_recognition_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(path);
    await file.writeAsBytes(encoded);

    setState(() {
      imageFiles.add(file);
      imageFileNames.add("Terminal Recognition");
      currentIndex = imageFiles.length - 1;
    });
  }

  Future<List<List<List<int>>>> _terminalLocalization(List<double> bboxList) async {
    // Step 1: Load the binary image from the file
    int index = imageFileNames.indexOf("Adaptive Threshold");
    final inputImage = imageFiles[index];
    cv.Mat binaryMat = cv.imread(inputImage!.path, flags: cv.IMREAD_UNCHANGED);

    // Step 2: Crop the image using the bbox list
    // Assuming the bbox list contains [x_center, y_center, width, height] for the cropping
    int x = (bboxList[0] - bboxList[2] / 2).toInt(); // x-coordinate of the top-left corner
    int y = (bboxList[1] - bboxList[3] / 2).toInt(); // y-coordinate of the top-left corner
    int width = bboxList[2].toInt(); // width of the bounding box
    int height = bboxList[3].toInt(); // height of the bounding box
    
    int cropLimit = 1;
    // Crop the binary image based on the bbox
    cv.Mat croppedMat = binaryMat.rowRange(
        y - cropLimit, 
        y + height + cropLimit
      ).colRange(
        x - cropLimit,
        x + width + cropLimit
      );

    // Step 3: Convert the cropped binary image into a list of pixels
    List<List<int>> pixelList = _imageToList(croppedMat);

    // Step 4: Calculate the total number of pixels in the cropped image
    int totalPixels = pixelList.length * pixelList[0].length;

    // Step 5: Set a threshold for the minimum group size
    int minGroupSize = (totalPixels * 0.01).round();

    // Step 6: Find the connected groups of pixels in the cropped image
    List<List<int>> connectedGroups = _findConnectedGroups(pixelList, minGroupSize);

    // Step 7: Get the number of rows and columns in the cropped image
    int rows = croppedMat.rows;
    int cols = croppedMat.cols;

    // Step 8: Initialize an empty list to store groups that touch the boundary
    List<List<int>> boundaryTouchingGroups = [];

    // Step 9: Iterate over each connected group to check if any pixel touches the boundary
    for (var group in connectedGroups) {
      // Step 10: Iterate through each pixel in the group
      for (var pixelIndex in group) {
        int row = pixelIndex ~/ cols; // Calculate the row index of the pixel
        int col = pixelIndex % cols; // Calculate the column index of the pixel

        // Step 11: Check if the pixel is on the boundary (top row, bottom row, left column, or right column)
        if (row == 0 || row == rows - 1 || col == 0 || col == cols - 1) {
          // Step 12: If boundary is touched, add the whole group to the list
          List<int> groupCoordinates = [x + col, y + row];
          boundaryTouchingGroups.add(groupCoordinates);
        }
      }
    }

    // Step 13: Return the list of groups that touch the boundary
    return _groupAdjacentCoordinates(boundaryTouchingGroups);
  }

  List<List<List<int>>> _groupAdjacentCoordinates(List<List<int>> coordinates) {
    Set<String> visited = {};
    Set<String> coordSet = coordinates.map((c) => '${c[0]},${c[1]}').toSet();
    List<List<List<int>>> resultGroups = [];

    List<List<int>> directions = [
      [0, 1], [1, 0], [0, -1], [-1, 0]  // right, down, left, up
    ];

    for (var coord in coordinates) {
      String key = '${coord[0]},${coord[1]}';
      if (visited.contains(key)) continue;

      List<List<int>> group = [];
      Queue<List<int>> queue = Queue();
      queue.add(coord);
      visited.add(key);

      while (queue.isNotEmpty) {
        List<int> current = queue.removeFirst();
        group.add(current);

        for (var dir in directions) {
          int newRow = current[0] + dir[0];
          int newCol = current[1] + dir[1];
          String newKey = '$newRow,$newCol';

          if (coordSet.contains(newKey) && !visited.contains(newKey)) {
            visited.add(newKey);
            queue.add([newRow, newCol]);
          }
        }
      }

      resultGroups.add(group);
    }

    return resultGroups;
  }

  Future<void> _grayScaleProcessing() async {
    try {
      cv.Mat image = cv.imread(widget.imagePath!, flags: cv.IMREAD_COLOR);
      cv.Mat grayScaleImage = cv.cvtColor(image, cv.COLOR_RGB2GRAY);
      var encoded = cv.imencode(".jpg", grayScaleImage).$2;
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/grayscale_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(encoded);

      setState(() {
        imageFiles.add(file);
        imageFileNames.add("Grayscale Image");
        currentIndex = imageFiles.length - 1;
      });
    } catch (e) {
      debugPrint("Error in grayscale processing: $e");
    }
  }

  Future<void> _adaptiveThresholding() async {
    try {
      final grayImage = imageFiles.last;
      cv.Mat grayMat = cv.imread(grayImage!.path, flags: cv.IMREAD_GRAYSCALE);
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
      final path = '${directory.path}/adaptive_thresh_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(encoded);

      setState(() {
        imageFiles.add(file);
        imageFileNames.add("Adaptive Threshold");
        currentIndex = imageFiles.length - 1;
      });
    } catch (e) {
      debugPrint("Error in adaptive thresholding: $e");
    }
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

  List<List<int>> _imageToList(cv.Mat binaryMat) {
    int rows = binaryMat.rows;
    int cols = binaryMat.cols;
    List<List<int>> binaryMatrix = [];

    for (int i = 0; i < rows; i++) {
      List<int> row = [];
      for (int j = 0; j < cols; j++) {
        int value = binaryMat.at(i, j);
        row.add(value > 128 ? 1 : 0);
      }
      binaryMatrix.add(row);
    }

    return binaryMatrix;
  }

  List<List<int>> _findConnectedGroups(List<List<int>> pixelList, int minGroupSize) {
    int rows = pixelList.length;
    int cols = pixelList[0].length;
    final directions = [
      [-1, 0], [1, 0], [0, -1], [0, 1],
      [-1, -1], [-1, 1], [1, -1], [1, 1]
    ];

    List<List<bool>> visited = List.generate(rows, (_) => List.generate(cols, (_) => false));
    List<List<int>> filteredGroups = [];

    void dfs(int r, int c, List<int> group) {
      List<List<int>> stack = [[r, c]];
      visited[r][c] = true;

      while (stack.isNotEmpty) {
        var current = stack.removeLast();
        int row = current[0], col = current[1];
        group.add(row * cols + col);

        for (var dir in directions) {
          int nr = row + dir[0], nc = col + dir[1];
          if (nr >= 0 && nr < rows && nc >= 0 && nc < cols &&
              !visited[nr][nc] && pixelList[nr][nc] == 1) {
            visited[nr][nc] = true;
            stack.add([nr, nc]);
          }
        }
      }
    }

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        if (pixelList[i][j] == 1 && !visited[i][j]) {
          List<int> group = [];
          dfs(i, j, group);
          if (group.length >= minGroupSize) {
            filteredGroups.add(group);
          }
        }
      }
    }

    return filteredGroups;
  }

  void _nextImage() {
    setState(() {
      currentIndex = (currentIndex + 1) % imageFiles.length;
    });
  }

  void _previousImage() {
    setState(() {
      currentIndex = (currentIndex - 1 + imageFiles.length) % imageFiles.length;
    });
  }
  
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
                  if(showBoundingBoxes) ...bboxesWidgets,
                ],
              ),
            ),
            const Divider(),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        showBoundingBoxes = !showBoundingBoxes;
                      });
                    }, 
                    icon: Icon(showBoundingBoxes ? Icons.visibility : Icons.visibility_off),
                    tooltip: "Show Bounding Boxes",
                  ),
                  IconButton(
                    onPressed: _previousImage, 
                    icon: Icon(Icons.arrow_back), 
                    tooltip: "Go to ${imageFileNames[currentIndex == 0 ? imageFileNames.length - 1 : currentIndex - 1]} Image",
                  ),
                  Text("${imageFileNames[currentIndex]}"),
                  IconButton(
                    onPressed: _nextImage, 
                    icon: Icon(Icons.arrow_forward), 
                    tooltip: "Go to ${imageFileNames[currentIndex == imageFileNames.length - 1 ? 0 : currentIndex + 1]} Image",
                  ),
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
}
