import 'dart:async';
import 'dart:io';
import 'model_loader.dart';

abstract class StubModelLoader implements ModelLoader {
  bool isLoadedState = false;
  String? currentModelIdState;
  String? currentTemplateState;

  String get stubDisplayName;
  int get tokenDelayMs;

  @override
  String get loaderName => stubDisplayName;

  @override
  bool get isLoaded => isLoadedState;

  @override
  String? get currentModelId => currentModelIdState;

  @override
  String? get currentTemplate => currentTemplateState;

  @override
  Future<bool> loadModel(
    String modelId,
    String modelPath, {
    Map<String, dynamic>? hyperparams,
  }) async {
    await unloadModel();

    final file = File(modelPath);
    if (!file.existsSync()) {
      throw Exception('$stubDisplayName model not found at: $modelPath');
    }

    try {
      currentModelIdState = modelId;
      isLoadedState = true;
      return true;
    } catch (e) {
      isLoadedState = false;
      currentModelIdState = null;
      throw Exception('Failed to load $stubDisplayName model: $e');
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
    if (!isLoadedState) {
      yield 'Error: No $stubDisplayName model loaded';
      return;
    }

    final prompt = messages.map((m) => m['content'] ?? '').join('\n');
    final segments = prompt.split(' ');
    int tokenCount = 0;

    for (final segment in segments) {
      if (tokenCount >= maxTokens) break;
      yield '$segment ';
      tokenCount++;
      await Future.delayed(Duration(milliseconds: tokenDelayMs));
    }

    final result = prompt.trim();
    if (result.isEmpty) {
      yield 'Hello! I am running as a $stubDisplayName model. How can I help?';
    }
  }

  @override
  Future<void> stopGeneration() async {}

  @override
  Future<void> unloadModel() async {
    isLoadedState = false;
    currentModelIdState = null;
    currentTemplateState = null;
  }

  @override
  void dispose() {
    isLoadedState = false;
    currentModelIdState = null;
    currentTemplateState = null;
  }
}
