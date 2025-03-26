import 'dart:math';
import 'package:flutter/material.dart';

Future<List<List<double>>> nonMaximumSuppression(
  List<List<double>> reshapedList,
  {required List<int> originalImageSize,
  double iouThreshold = 0.5,
  double confidenceThreshold = 0.4}) async {

  List<List<double>> results = [];
  List<List<double>> filteredBoxes = [];

  for (var box in reshapedList) {
    int numLabels = box.length - 4;
    List<double> classProbs = box.sublist(4, 4 + numLabels);
    double maxConfidence = classProbs.reduce(max);
    int bestClassIdx = classProbs.indexOf(maxConfidence);
    if(maxConfidence > confidenceThreshold) {
      filteredBoxes.add([...box.sublist(0,4), maxConfidence, bestClassIdx.toDouble()]);
    }
  }

  if (filteredBoxes.isEmpty) return [];

  // Sort by confidence (Descending)
  filteredBoxes.sort((a, b) => b[4].compareTo(a[4]));
  
  while (filteredBoxes.isNotEmpty) {
    var bestBox = filteredBoxes.removeAt(0);
    List<double> convertedBox = convertBoxFormat(bestBox);
    convertedBox = scaleBoxes(convertedBox, originalImageSize);

    debugPrint("Boxlength: ${bestBox.length}");
    
    // Append confidence and class index to the results
    results.add([...convertedBox, bestBox[4], bestBox[5]]);

    // Suppress overlapping boxes with the same class
    filteredBoxes.removeWhere((box) =>
        box.last == bestBox[convertedBox.length + 1] && 
        iou(convertedBox, convertBoxFormat(box)) > iouThreshold);
  }

  return results;
}
// Convert from (cx, cy, w, h) to (x1, y1, x2, y2)
List<double> convertBoxFormat(List<double> box) {
  double cx = box[0], cy = box[1], w = box[2], h = box[3];
  double x1 = cx - w / 2, y1 = cy - h / 2, x2 = cx + w / 2, y2 = cy + h / 2;
  return [x1, y1, x2, y2]; // Only return bounding box coordinates
}

// Scale Bounding Boxes to Original Image Size
List<double> scaleBoxes(List<double> box, List<int> originalImageSize) {
  double imgW = originalImageSize[1].toDouble();
  double imgH = originalImageSize[0].toDouble();

  double x1 = (box[0] * imgW).clamp(0, imgW - 1);
  double y1 = (box[1] * imgH).clamp(0, imgH - 1);
  double x2 = (box[2] * imgW).clamp(0, imgW - 1);
  double y2 = (box[3] * imgH).clamp(0, imgH - 1);

  return [x1, y1, x2, y2];
}

// IoU Calculation
double iou(List<double> box1, List<double> box2) {
  double xLeft = max(box1[0], box2[0]);
  double yTop = max(box1[1], box2[1]);
  double xRight = min(box1[2], box2[2]);
  double yBottom = min(box1[3], box2[3]);

  double interWidth = max(0, xRight - xLeft);
  double interHeight = max(0, yBottom - yTop);
  double interArea = interWidth * interHeight;

  double box1Area = (box1[2] - box1[0]) * (box1[3] - box1[1]);
  double box2Area = (box2[2] - box2[0]) * (box2[3] - box2[1]);
  double unionArea = box1Area + box2Area - interArea;

  return interArea / unionArea;
}
