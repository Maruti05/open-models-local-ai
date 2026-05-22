import 'dart:async';
import 'dart:io';
import 'models/model_format.dart';
import 'loaders/model_loader.dart';
import 'loaders/gguf_model_loader.dart';
import 'loaders/tflite_model_loader.dart';
import 'loaders/onnx_model_loader.dart';
import '../services/native_bridge.dart';
import '../constants/api_endpoints.dart';

class HybridModelManager {
  HybridModelManager._privateConstructor();
  static final HybridModelManager instance = HybridModelManager._privateConstructor();

  final GGUFModelLoader _ggufLoader = GGUFModelLoader();
  final TFLiteModelLoader _tfliteLoader = TFLiteModelLoader();
  final ONNXModelLoader _onnxLoader = ONNXModelLoader();

  ModelLoader? _activeLoader;
  String? _activeModelId;

  ModelLoader? get activeLoader => _activeLoader;
  String? get activeModelId => _activeModelId;
  bool get isLoaded => _activeLoader?.isLoaded ?? false;
  String? get currentTemplate => _activeLoader?.currentTemplate;

  ModelLoader _loaderForFormat(ModelFormat format) {
    switch (format) {
      case ModelFormat.gguf:
        return _ggufLoader;
      case ModelFormat.tflite:
        return _tfliteLoader;
      case ModelFormat.onnx:
        return _onnxLoader;
      case ModelFormat.unknown:
        return _ggufLoader;
    }
  }

  Future<String> _resolveModelPath(String modelId) async {
    return await NativeBridge.instance.getModelPath(modelId);
  }

  ModelFormat _resolveFormat(String modelId, String modelPath) {
    final catalog = ApiEndpoints.localModelsCatalog;
    try {
      final entry = catalog.firstWhere((e) => e['id'] == modelId);
      final url = entry['downloadUrl'] as String? ?? '';
      final formatFromUrl = ModelFormat.fromExtension(url);
      if (formatFromUrl != ModelFormat.unknown) return formatFromUrl;
    } catch (_) {}

    final formatFromPath = ModelFormat.fromExtension(modelPath);
    if (formatFromPath != ModelFormat.unknown) return formatFromPath;

    try {
      final file = File(modelPath);
      if (file.existsSync()) {
        return ModelFormat.fromFileSize(file.lengthSync());
      }
    } catch (_) {}

    return ModelFormat.gguf;
  }

  Future<bool> loadModelToRam(
    String modelId, {
    Map<String, dynamic>? hyperparams,
  }) async {
    await unloadModel();

    final modelPath = await _resolveModelPath(modelId);
    if (modelPath.isEmpty) {
      throw Exception('Model file path could not be resolved for "$modelId".');
    }

    final format = _resolveFormat(modelId, modelPath);
    final loader = _loaderForFormat(format);

    try {
      final success = await loader.loadModel(
        modelId,
        modelPath,
        hyperparams: hyperparams,
      );
      if (success) {
        _activeLoader = loader;
        _activeModelId = modelId;
      }
      return success;
    } catch (e) {
      _activeLoader = null;
      _activeModelId = null;
      rethrow;
    }
  }

  Stream<String> generateChat({
    required List<Map<String, String>> messages,
    String? template,
    int maxTokens = 512,
    double temperature = 0.7,
    double topP = 0.9,
    int topK = 40,
  }) {
    if (_activeLoader == null || !_activeLoader!.isLoaded) {
      return Stream.error('No model loaded');
    }
    return _activeLoader!.generateChat(
      messages: messages,
      template: template ?? _activeLoader!.currentTemplate,
      maxTokens: maxTokens,
      temperature: temperature,
      topP: topP,
      topK: topK,
    );
  }

  Future<void> stopGeneration() async {
    await _activeLoader?.stopGeneration();
  }

  Future<void> unloadModel() async {
    if (_activeLoader != null && _activeLoader!.isLoaded) {
      await _activeLoader!.unloadModel();
    }
    _activeLoader = null;
    _activeModelId = null;
  }

  void dispose() {
    _ggufLoader.dispose();
    _tfliteLoader.dispose();
    _onnxLoader.dispose();
    _activeLoader = null;
    _activeModelId = null;
  }
}
