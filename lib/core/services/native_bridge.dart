import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../constants/app_strings.dart';

class NativeBridge {
  NativeBridge._privateConstructor();
  static final NativeBridge instance = NativeBridge._privateConstructor();

  static const MethodChannel _methodChannel =
      MethodChannel(AppStrings.channelDiagnostics);
  static const EventChannel _downloadEventChannel =
      EventChannel(AppStrings.channelDownloadStream);
  static const EventChannel _inferenceEventChannel =
      EventChannel(AppStrings.channelInferenceStream);

  // Diagnostic Scanning calls
  Future<Map<String, dynamic>> checkHardware() async {
    try {
      final String? result =
          await _methodChannel.invokeMethod('getHardwareSpecs');
      if (result == null) return {};
      return Map<String, dynamic>.from(jsonDecode(result));
    } catch (e) {
      return {
        'error': e.toString(),
        'totalRamGb': 0.0,
        'availableRamGb': 0.0,
        'cores': 1,
        'vulkan': false,
        'nnapi': false,
      };
    }
  }

  // Model download hooks
  Stream<Map<String, dynamic>> listenToDownloads() {
    return _downloadEventChannel.receiveBroadcastStream().map((event) {
      if (event is String) {
        return Map<String, dynamic>.from(jsonDecode(event));
      }
      return {};
    });
  }

  Future<bool> startDownload(String modelId, String downloadUrl) async {
    try {
      final bool? success = await _methodChannel.invokeMethod('startDownload', {
        'modelId': modelId,
        'downloadUrl': downloadUrl,
      });
      return success ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteModel(String modelId) async {
    try {
      final bool? success = await _methodChannel.invokeMethod('deleteModel', {
        'modelId': modelId,
      });
      return success ?? false;
    } catch (e) {
      return false;
    }
  }

  // Open device WiFi settings
  Future<void> openWifiSettings() async {
    try {
      await _methodChannel.invokeMethod('openWifiSettings');
    } catch (_) {}
  }

  // Get model file path from native storage
  Future<String> getModelPath(String modelId) async {
    final String? path = await _methodChannel.invokeMethod('getModelPath', {
      'modelId': modelId,
    });
    if (path == null || path.isEmpty) {
      throw Exception('Failed to resolve storage path for model "$modelId".');
    }
    return path;
  }

  // Inference Core Loading
  Future<bool> loadModel(String modelId, Map<String, dynamic> params) async {
    try {
      final bool? success = await _methodChannel.invokeMethod('loadModel', {
        'modelId': modelId,
        ...params,
      });
      return success ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> unloadModel() async {
    try {
      final bool? success = await _methodChannel.invokeMethod('unloadModel');
      return success ?? false;
    } catch (e) {
      return false;
    }
  }

  // Inference session triggers
  Future<void> runInference(String prompt, {Map<String, dynamic>? hyperparams}) async {
    try {
      final args = <String, dynamic>{'prompt': prompt};
      if (hyperparams != null) {
        args.addAll(hyperparams);
      }
      await _methodChannel.invokeMethod('runInference', args);
    } catch (e) {
      // Ignored: failures bubble up over Event Channel stream errors
    }
  }

  Stream<String> listenToInference() {
    return _inferenceEventChannel.receiveBroadcastStream().map((event) {
      if (event is String) {
        return event;
      }
      return '';
    });
  }
}
