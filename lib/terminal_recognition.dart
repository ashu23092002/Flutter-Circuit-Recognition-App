import 'dart:io';
import 'package:flutter/material.dart';
import 'package:opencv_core/opencv.dart' as cv;
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
    await _terminalLocalization();
  }

  Future<void> _grayScaleProcessing() async {
    try {
      cv.Mat image = cv.imread(widget.imagePath, flags: cv.IMREAD_COLOR);
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
      cv.Mat grayMat = cv.imread(grayImage.path, flags: cv.IMREAD_GRAYSCALE);
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

  Future<void> _terminalLocalization() async {
    final inputImage = imageFiles.last;
    cv.Mat binaryMat = cv.imread(inputImage.path, flags: cv.IMREAD_UNCHANGED);

    List<List<int>> pixelList = _imageToList(binaryMat);
    int totalPixels = pixelList.length * pixelList[0].length;
    int minGroupSize = (totalPixels * 0.01).round();
    List<List<int>> connectedGroups = _findConnectedGroups(pixelList, minGroupSize);

    int rows = binaryMat.rows;
    int cols = binaryMat.cols;
    cv.Mat colorMat = cv.Mat.zeros(rows, cols, cv.MatType.CV_8UC3);

    for (var group in connectedGroups) {
      for (var pixelIndex in group) {
        int row = pixelIndex ~/ cols;
        int col = pixelIndex % cols;

        if (row == 0 || row == rows - 1 || col == 0 || col == cols - 1) {
          colorMat.set(row, col, cv.Vec3b(0, 255, 0)); // Green for boundary touching
        } else {
          colorMat.set(row, col, cv.Vec3b(0, 0, 255));
        }
      }
    }

    var encoded = cv.imencode(".jpg", colorMat).$2;
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/highlighted_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(path);
    await file.writeAsBytes(encoded);

    setState(() {
      imageFiles.add(file);
      imageFileNames.add("Highlighted File");
      currentIndex = imageFiles.length - 1;
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
    return Scaffold(
      appBar: AppBar(title: const Text('Terminal Recognition')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Image.file(imageFiles[currentIndex]),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: Icon(Icons.arrow_back), onPressed: _previousImage),
              IconButton(icon: Icon(Icons.arrow_forward), onPressed: _nextImage),
            ],
          ),
        ],
      ),
    );
  }
}
