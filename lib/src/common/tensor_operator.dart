import 'package:circuit_recognition_app/src/common/operator.dart';
import 'package:circuit_recognition_app/src/tensorbuffer/tensorbuffer.dart';

/// Applies some operation on TensorBuffers.
abstract class TensorOperator extends Operator<TensorBuffer> {
  /// See [Operator.apply].
  @override
  TensorBuffer apply(TensorBuffer input);
}
