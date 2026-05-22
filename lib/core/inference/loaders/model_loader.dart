import 'dart:async';

abstract class ModelLoader {
  String get loaderName;
  bool get isLoaded;
  String? get currentModelId;
  String? get currentTemplate;

  Future<bool> loadModel(
    String modelId,
    String modelPath, {
    Map<String, dynamic>? hyperparams,
  });

  Stream<String> generateChat({
    required List<Map<String, String>> messages,
    String? template,
    int maxTokens = 512,
    double temperature = 0.7,
    double topP = 0.9,
    int topK = 40,
  });

  Future<void> stopGeneration();
  Future<void> unloadModel();
  void dispose();
}
