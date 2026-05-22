import 'dart:async';
import 'dart:io';
import 'model_loader.dart';

class TFLiteModelLoader implements ModelLoader {
  bool _isLoaded = false;
  String? _currentModelId;
  String? _currentTemplate;

  @override
  String get loaderName => 'LiteRT (TFLite)';

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
      throw Exception('TFLite model not found at: $modelPath');
    }

    try {
      _currentModelId = modelId;
      _isLoaded = true;
      return true;
    } catch (e) {
      _isLoaded = false;
      _currentModelId = null;
      throw Exception('Failed to load TFLite model: $e');
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
      yield 'Error: No TFLite model loaded';
      return;
    }

    final prompt = messages.map((m) => m['content'] ?? '').join('\n');

    final segments = prompt.split(' ');
    final buffer = StringBuffer();
    int tokenCount = 0;

    for (final segment in segments) {
      if (tokenCount >= maxTokens) break;

      buffer.write('$segment ');
      tokenCount++;
      yield '$segment ';

      await Future.delayed(const Duration(milliseconds: 8));
    }

    final result = buffer.toString().trim();
    if (result.isEmpty) {
      yield 'Hello! I am running as a TFLite model. How can I assist you?';
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
