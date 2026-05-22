import 'dart:async';
import 'dart:io';
import 'package:llama_flutter_android/llama_flutter_android.dart';
import 'model_loader.dart';

class GGUFModelLoader implements ModelLoader {
  LlamaController? _controller;
  String? _currentModelId;

  @override
  String get loaderName => 'GGUF (llama.cpp)';

  @override
  bool get isLoaded => _controller != null;

  @override
  String? get currentModelId => _currentModelId;

  @override
  String? get currentTemplate =>
      _currentModelId != null ? _modelTemplates[_currentModelId] : null;

  static const Map<String, String> _modelTemplates = {
    'smollm_135m_q2': 'chatml',
    'smollm_135m_iq3': 'chatml',
    'smollm_135m_q4': 'chatml',
    'smollm_360m_q2': 'chatml',
    'smollm_360m_q3': 'chatml',
    'smollm_360m_q4': 'chatml',
    'tinyllama_1_1b_q2': 'llama2',
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

  @override
  Future<bool> loadModel(
    String modelId,
    String modelPath, {
    Map<String, dynamic>? hyperparams,
  }) async {
    await unloadModel();

    final file = File(modelPath);
    if (!file.existsSync()) {
      throw Exception('Model file not found at: $modelPath');
    }

    final fileSize = file.lengthSync();
    if (fileSize < 8192) {
      file.deleteSync();
      throw Exception('Model file is corrupt or incomplete '
          '(${_formatBytes(fileSize)}). File deleted. Please re-download.');
    }

    if (!_isValidGguf(file)) {
      file.deleteSync();
      throw Exception('Model file is not a valid GGUF format '
          '(corrupt or incompatible). File deleted. Please re-download.');
    }

    final threads = (hyperparams?['threads'] as num?)?.toInt() ?? 4;
    final contextSize = (hyperparams?['contextSize'] as num?)?.toInt() ?? 2048;
    final gpuLayers = (hyperparams?['gpuLayers'] as num?)?.toInt();

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
      throw Exception(
        'Failed to initialize model in GGUF inference engine.\n'
        'This may indicate a corrupt or incompatible model file.\n'
        'Technical details: $e',
      );
    }
  }

  bool _isValidGguf(File file) {
    try {
      final raf = file.openSync(mode: FileMode.read);
      final magic = raf.readSync(4);
      raf.closeSync();
      if (magic.length < 4) return false;
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

  @override
  Stream<String> generateChat({
    required List<Map<String, String>> messages,
    String? template,
    int maxTokens = 512,
    double temperature = 0.7,
    double topP = 0.9,
    int topK = 40,
  }) {
    if (_controller == null) {
      return Stream.error('No GGUF model loaded');
    }
    final chatMessages = messages.map((m) =>
      ChatMessage(role: m['role']!, content: m['content']!)
    ).toList();
    return _controller!.generateChat(
      messages: chatMessages,
      template: template,
      maxTokens: maxTokens,
      temperature: temperature,
      topP: topP,
      topK: topK,
    );
  }

  @override
  Future<void> stopGeneration() async {
    await _controller?.stop();
  }

  @override
  Future<void> unloadModel() async {
    if (_controller != null) {
      try {
        await _controller!.dispose();
      } catch (_) {}
      _controller = null;
    }
    _currentModelId = null;
  }

  @override
  void dispose() {
    _controller?.dispose();
    _controller = null;
    _currentModelId = null;
  }
}
