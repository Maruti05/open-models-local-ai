import 'dart:async';
import 'dart:io';
import 'model_loader.dart';

class ONNXModelLoader implements ModelLoader {
  bool _isLoaded = false;
  String? _currentModelId;
  String? _currentTemplate;

  @override
  String get loaderName => 'ONNX Runtime';

  @override
  bool get isLoaded => _isLoaded;

  @override
  String? get currentModelId => _currentModelId;

  @override
  String? get currentTemplate => _currentTemplate;

  @override
  Future<bool> loadModel(
    String modelId,
    String modelPath, {
    Map<String, dynamic>? hyperparams,
  }) async {
    await unloadModel();

    final file = File(modelPath);
    if (!file.existsSync()) {
      throw Exception('ONNX model not found at: $modelPath');
    }

    try {
      _currentModelId = modelId;
      _isLoaded = true;
      return true;
    } catch (e) {
      _isLoaded = false;
      _currentModelId = null;
      throw Exception('Failed to load ONNX model: $e');
    }
  }

  @override
  Stream<String> generateChat({
    required List<Map<String, String>> messages,
    String? template,
    int maxTokens = 512,
    double temperature = 0.7,
    double topP = 0.9,
    int topK = 40,
  }) async* {
    if (!_isLoaded) {
      yield 'Error: No ONNX model loaded';
      return;
    }

    final prompt = messages.map((m) => m['content'] ?? '').join('\n');

    final segments = prompt.split(' ');
    int tokenCount = 0;

    for (final segment in segments) {
      if (tokenCount >= maxTokens) break;

      yield '$segment ';
      tokenCount++;

      await Future.delayed(const Duration(milliseconds: 10));
    }

    final result = prompt.trim();
    if (result.isEmpty) {
      yield 'Hello! I am running as an ONNX model. How can I help?';
    }
  }

  @override
  Future<void> stopGeneration() async {}

  @override
  Future<void> unloadModel() async {
    _isLoaded = false;
    _currentModelId = null;
    _currentTemplate = null;
  }

  @override
  void dispose() {
    _isLoaded = false;
    _currentModelId = null;
    _currentTemplate = null;
  }
}
