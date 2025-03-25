import 'dart:ffi';

import 'package:ffi/ffi.dart';

base class TfLiteBertQuestionAnswerer extends Opaque {}

base class TfLiteQaAnswer extends Struct {
  @Int32()
  external int start;
  @Int32()
  external int end;
  @Double()
  external double logit;

  external Pointer<Utf8> text;
}

base class TfLiteQaAnswers extends Struct {
  @Int32()
  external int size;

  external Pointer<TfLiteQaAnswer> answers;
}
