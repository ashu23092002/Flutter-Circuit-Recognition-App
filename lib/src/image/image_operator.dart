import 'dart:math';

import 'package:circuit_recognition_app/src/common/operator.dart';
import 'package:circuit_recognition_app/src/image/tensor_image.dart';

/// Operates a TensorImage object. Used in ImageProcessor.
abstract class ImageOperator extends Operator<TensorImage> {
  /// See [Operator.apply]
  TensorImage apply(TensorImage image);

  /// Computes the width of the expected output image when input image size is given.
  int getOutputImageWidth(int inputImageHeight, int inputImageWidth);

  /// Computes the height of the expected output image when input image size is given.
  int getOutputImageHeight(int inputImageHeight, int inputImageWidth);

  /// Transforms a [point] from coordinates system of the result image back to the one of the input
  /// image.
  Point inverseTransform(
      Point point, int inputImageHeight, int inputImageWidth);
}
