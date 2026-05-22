enum ModelFormat {
  gguf,
  tflite,
  onnx,
  unknown;

  String get extension {
    switch (this) {
      case ModelFormat.gguf:
        return '.gguf';
      case ModelFormat.tflite:
        return '.tflite';
      case ModelFormat.onnx:
        return '.onnx';
      case ModelFormat.unknown:
        return '';
    }
  }

  String get displayName {
    switch (this) {
      case ModelFormat.gguf:
        return 'GGUF (llama.cpp)';
      case ModelFormat.tflite:
        return 'LiteRT (TFLite)';
      case ModelFormat.onnx:
        return 'ONNX Runtime';
      case ModelFormat.unknown:
        return 'Unknown';
    }
  }

  static ModelFormat fromExtension(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.gguf')) return ModelFormat.gguf;
    if (lower.endsWith('.tflite')) return ModelFormat.tflite;
    if (lower.endsWith('.onnx')) return ModelFormat.onnx;
    return ModelFormat.unknown;
  }

  static ModelFormat fromFileSize(int bytes) {
    final mb = bytes / (1024 * 1024);
    if (mb < 300) return ModelFormat.tflite;
    if (mb <= 3000) return ModelFormat.gguf;
    return ModelFormat.gguf;
  }
}
