import 'stub_model_loader.dart';

class TFLiteModelLoader extends StubModelLoader {
  @override
  String get stubDisplayName => 'LiteRT (TFLite)';

  @override
  int get tokenDelayMs => 8;
}
