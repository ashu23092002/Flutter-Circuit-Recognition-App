import 'dart:math';

Future<List<List<double>>> nonMaximumSuppression(
  List<List<double>> reshapedList,
  {double iouThreshold = 0.5,
  double confidenceThreshold = 0.4}) async{

  List<List<double>> results = [];
  List<List<double>> filteredBoxes = reshapedList
                                    .where((box) => box[4] > confidenceThreshold) // Confidence score
                                    .toList();
  if (filteredBoxes.isEmpty) return [];
  for (var box in filteredBoxes) {
    List<double> classProbs = box.sublist(5); 
    int bestClassIdx = classProbs.indexOf(classProbs.reduce(max)); 
    box[4] *= classProbs[bestClassIdx]; 
    box.add(bestClassIdx.toDouble()); 
  }

  // Sort by confidence (Descending)
  filteredBoxes.sort((a, b) => b[4].compareTo(a[4]));

  while (filteredBoxes.isNotEmpty) {
    var bestBox = filteredBoxes.removeAt(0);
    results.add(bestBox);

    // Suppress overlapping boxes with the same class
    filteredBoxes.removeWhere((box) =>
        box.last == bestBox.last && 
        iou(bestBox, box) > iouThreshold);
  }

  return results;
}

// IoU Calculation for Normalized Coordinates (0 to 1)
double iou(List<double> box1, List<double> box2) {
  // Convert center (x, y) + width/height to (x1, y1, x2, y2)
  double x1Min = box1[0] - box1[2] / 2;
  double y1Min = box1[1] - box1[3] / 2;
  double x1Max = box1[0] + box1[2] / 2;
  double y1Max = box1[1] + box1[3] / 2;

  double x2Min = box2[0] - box2[2] / 2;
  double y2Min = box2[1] - box2[3] / 2;
  double x2Max = box2[0] + box2[2] / 2;
  double y2Max = box2[1] + box2[3] / 2;

  // Compute intersection
  double xLeft = max(x1Min, x2Min);
  double yTop = max(y1Min, y2Min);
  double xRight = min(x1Max, x2Max);
  double yBottom = min(y1Max, y2Max);

  double interWidth = max(0, xRight - xLeft);
  double interHeight = max(0, yBottom - yTop);
  double interArea = interWidth * interHeight;

  // Compute union
  double box1Area = (x1Max - x1Min) * (y1Max - y1Min);
  double box2Area = (x2Max - x2Min) * (y2Max - y2Min);
  double unionArea = box1Area + box2Area - interArea;

  return interArea / unionArea; // IoU
}