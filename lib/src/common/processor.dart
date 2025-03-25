import 'package:circuit_recognition_app/src/common/operator.dart';

/// Processes [T] object with prepared [Operator].
abstract class Processor<T> {
  T process(T input);
}
