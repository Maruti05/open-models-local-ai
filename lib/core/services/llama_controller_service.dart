import 'dart:async';
import 'dart:io';
import 'package:llama_flutter_android/llama_flutter_android.dart';
import 'native_bridge.dart';

class LlamaControllerService {
  LlamaControllerService._privateConstructor();
  static final LlamaControllerService instance = LlamaControllerService._privateConstructor();

  LlamaController? _controller;
  String? _currentModelId;

  bool get isLoaded => _controller != null;
  String? get currentModelId => _currentModelId;

  static const Map<String, String> _modelTemplates = {
    'smollm_135m_q4': 'chatml',
    'smollm_360m_q4': 'chatml',
    'qwen_0_5b_q2': 'chatml',
    'qwen_0_5b_q4': 'chatml',
    'phi_1_5_q2': 'phi',
    'gemma_2_2b_q2': 'gemma',
    'phi_2_q2': 'phi',
    'gemma_2_2b_q4': 'gemma',
    'llama_3_3b_q4': 'llama2',
    'phi_3_mini_q4': 'phi',
    'mistral_7b_q4': 'llama2',
  };

  String? get currentTemplate => _currentModelId != null
      ? _modelTemplates[_currentModelId]
      : null;

  Future<String> getModelPath(String modelId) async {
    return await NativeBridge.instance.getModelPath(modelId);
  }

  Future<bool> loadModel(
    String modelId, {
    int threads = 4,
    int contextSize = 2048,
    int? gpuLayers,
  }) async {
    await unloadModel();

    final modelPath = await getModelPath(modelId);
    if (modelPath.isEmpty) {
      throw Exception('Model file path could not be resolved for "$modelId".');
    }

    final file = File(modelPath);
    if (!file.existsSync()) {
      throw Exception('Model file not found at: $modelPath\n'
          'Please download the model first.');
    }

    final fileSize = file.lengthSync();
    if (fileSize < 8192) {
      file.deleteSync();
      throw Exception('Model file is corrupt or incomplete '
          '(${_formatBytes(fileSize)}). File deleted. Please re-download.');
    }

    // Validate GGUF magic bytes: first 4 bytes must be "GGUF" (0x47 0x47 0x55 0x46)
    if (!_isValidGguf(file)) {
      file.deleteSync();
      throw Exception('Model file is not a valid GGUF format '
          '(corrupt or incompatible). File deleted. Please re-download.');
    }

    final controller = LlamaController();
    try {
      await controller.loadModel(
        modelPath: modelPath,
        threads: threads,
        contextSize: contextSize,
        gpuLayers: gpuLayers,
      );
      _controller = controller;
      _currentModelId = modelId;
      return true;
    } catch (e) {
      controller.dispose();
      // If the plugin itself failed, suggest re-download
      throw Exception(
          'Failed to initialize model in inference engine.\n'
          'This may indicate a corrupt or incompatible model file.\n'
          'Please delete and re-download the model.\n'
          'Technical details: $e');
    }
  }

  bool _isValidGguf(File file) {
    try {
      final raf = file.openSync(mode: FileMode.read);
      final magic = raf.readSync(4);
      raf.closeSync();
      if (magic.length < 4) return false;
      // GGUF magic = bytes [0x47, 0x47, 0x55, 0x46] = "GGUF"
      return magic[0] == 0x47 && magic[1] == 0x47 &&
             magic[2] == 0x55 && magic[3] == 0x46;
    } catch (_) {
      return false;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1073741824) {
      return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
    } else if (bytes >= 1048576) {
      return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '$bytes B';
  }

  Stream<String> generateChat({
    required List<ChatMessage> messages,
    String? template,
    int maxTokens = 512,
    double temperature = 0.7,
    double topP = 0.9,
    int topK = 40,
  }) {
    if (_controller == null) {
      return Stream.error('No model loaded');
    }
    return _controller!.generateChat(
      messages: messages,
      template: template,
      maxTokens: maxTokens,
      temperature: temperature,
      topP: topP,
      topK: topK,
    );
  }

  Future<void> stopGeneration() async {
    await _controller?.stop();
  }

  Future<void> unloadModel() async {
    if (_controller != null) {
      try {
        await _controller!.dispose();
      } catch (_) {}
      _controller = null;
    }
    _currentModelId = null;
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
    _currentModelId = null;
  }
}
