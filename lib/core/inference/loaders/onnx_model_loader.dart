import 'stub_model_loader.dart';

class ONNXModelLoader extends StubModelLoader {
  @override
  String get stubDisplayName => 'ONNX Runtime';

  @override
  int get tokenDelayMs => 10;
}
