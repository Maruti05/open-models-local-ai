import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/services/native_bridge.dart';
import '../../../core/inference/hybrid_model_manager.dart';
import '../../../core/utils/hardware_checker.dart';

class ModelDownloadState {
  final String modelId;
  final double progressPercentage;
  final int downloadedBytes;
  final int totalBytes;
  final double downloadSpeedMbps;
  final String status; // 'IDLE', 'DOWNLOADING', 'COMPLETED', 'ERROR', 'PAUSED'
  final String error;

  ModelDownloadState({
    required this.modelId,
    this.progressPercentage = 0.0,
    this.downloadedBytes = 0,
    this.totalBytes = 0,
    this.downloadSpeedMbps = 0.0,
    this.status = 'IDLE',
    this.error = '',
  });

  ModelDownloadState copyWith({
    String? modelId,
    double? progressPercentage,
    int? downloadedBytes,
    int? totalBytes,
    double? downloadSpeedMbps,
    String? status,
    String? error,
  }) {
    return ModelDownloadState(
      modelId: modelId ?? this.modelId,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadSpeedMbps: downloadSpeedMbps ?? this.downloadSpeedMbps,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }
}

class ModelState {
  final List<String> downloadedModelIds;
  final Map<String, ModelDownloadState> downloads;
  final String? loadedModelId;
  final bool isModelLoading;
  final String error;

  ModelState({
    this.downloadedModelIds = const [],
    this.downloads = const {},
    this.loadedModelId,
    this.isModelLoading = false,
    this.error = '',
  });

  ModelState copyWith({
    List<String>? downloadedModelIds,
    Map<String, ModelDownloadState>? downloads,
    String? loadedModelId,
    bool? isModelLoading,
    String? error,
  }) {
    return ModelState(
      downloadedModelIds: downloadedModelIds ?? this.downloadedModelIds,
      downloads: downloads ?? this.downloads,
      loadedModelId: loadedModelId ?? this.loadedModelId,
      isModelLoading: isModelLoading ?? this.isModelLoading,
      error: error ?? this.error,
    );
  }
}

class ModelNotifier extends StateNotifier<ModelState> {
  SharedPreferences? _prefs;
  StreamSubscription<Map<String, dynamic>>? _downloadSubscription;

  ModelNotifier() : super(ModelState()) {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    final list = _prefs?.getStringList('downloaded_model_ids') ?? [];

    // Check if any GGUF models are recorded as downloaded
    state = state.copyWith(downloadedModelIds: list);

    // Initialize telemetry event listener
    _downloadSubscription =
        NativeBridge.instance.listenToDownloads().listen((data) {
      final modelId = data['model_id'] as String?;
      if (modelId == null) return;

      final status = data['status'] as String? ?? 'DOWNLOADING';
      final progress = (data['progress_percentage'] as num?)?.toDouble() ?? 0.0;
      final speed = (data['download_speed_mbps'] as num?)?.toDouble() ?? 0.0;
      final downloaded = (data['downloaded_bytes'] as num?)?.toInt() ?? 0;
      final total = (data['total_bytes'] as num?)?.toInt() ?? 0;
      final error = data['error'] as String? ?? '';

      final dlState = ModelDownloadState(
        modelId: modelId,
        progressPercentage: progress,
        downloadedBytes: downloaded,
        totalBytes: total,
        downloadSpeedMbps: speed,
        status: status,
        error: error,
      );

      final updatedDownloads = Map<String, ModelDownloadState>.from(state.downloads);
      updatedDownloads[modelId] = dlState;

      List<String> updatedDownloadedList = List.from(state.downloadedModelIds);
      if (status == 'COMPLETED') {
        if (!updatedDownloadedList.contains(modelId)) {
          updatedDownloadedList.add(modelId);
          _prefs?.setStringList('downloaded_model_ids', updatedDownloadedList);
        }
      }

      // Keep ERROR entries so UI can show retry option
      // Remove from downloaded list on error (mark as not available)
      if (status == 'ERROR' && updatedDownloadedList.contains(modelId)) {
        updatedDownloadedList.remove(modelId);
        _prefs?.setStringList('downloaded_model_ids', updatedDownloadedList);
      }

      state = state.copyWith(
        downloads: updatedDownloads,
        downloadedModelIds: updatedDownloadedList,
      );
    });
  }

  Future<void> triggerDownload(String modelId) async {
    final catalogItem = ApiEndpoints.localModelsCatalog.firstWhere(
      (element) => element['id'] == modelId,
      orElse: () => {},
    );
    if (catalogItem.isEmpty) return;

    final url = catalogItem['downloadUrl'] as String;

    final updatedDownloads = Map<String, ModelDownloadState>.from(state.downloads);
    updatedDownloads[modelId] = ModelDownloadState(
      modelId: modelId,
      status: 'DOWNLOADING',
      progressPercentage: 0.0,
    );
    state = state.copyWith(downloads: updatedDownloads);

    await NativeBridge.instance.startDownload(modelId, url);
  }

  Future<void> retryDownload(String modelId) async {
    final current = state.downloads[modelId];
    if (current != null && current.status != 'ERROR') return;

    final updatedDownloads = Map<String, ModelDownloadState>.from(state.downloads);
    updatedDownloads[modelId] = current != null
        ? current.copyWith(
            status: 'DOWNLOADING',
            progressPercentage: 0.0,
            downloadedBytes: 0,
            error: '',
          )
        : ModelDownloadState(
            modelId: modelId,
            status: 'DOWNLOADING',
          );
    state = state.copyWith(downloads: updatedDownloads);

    final catalogItem = ApiEndpoints.localModelsCatalog.firstWhere(
      (element) => element['id'] == modelId,
      orElse: () => {},
    );
    if (catalogItem.isEmpty) return;

    await NativeBridge.instance.startDownload(modelId, catalogItem['downloadUrl'] as String);
  }

  void clearDownloadError(String modelId) {
    final updatedDownloads = Map<String, ModelDownloadState>.from(state.downloads);
    updatedDownloads.remove(modelId);
    state = state.copyWith(downloads: updatedDownloads);
  }

  Future<void> deleteModel(String modelId) async {
    final success = await NativeBridge.instance.deleteModel(modelId);
    if (success) {
      final updatedList = List<String>.from(state.downloadedModelIds)..remove(modelId);
      await _prefs?.setStringList('downloaded_model_ids', updatedList);

      final updatedDownloads = Map<String, ModelDownloadState>.from(state.downloads);
      updatedDownloads.remove(modelId);

      String? loadedId = state.loadedModelId;
      if (loadedId == modelId) {
        loadedId = null;
      }

      state = state.copyWith(
        downloadedModelIds: updatedList,
        downloads: updatedDownloads,
        loadedModelId: loadedId,
      );
    }
  }

  Future<bool> loadModelToRam(
    String modelId,
    Map<String, dynamic> hyperparams, {
    int? threads,
    double? availableRamGb,
  }) async {
    state = state.copyWith(isModelLoading: true, error: '');

    if (availableRamGb != null) {
      final catalogItem = ApiEndpoints.localModelsCatalog.firstWhere(
        (element) => element['id'] == modelId,
        orElse: () => {},
      );
      if (catalogItem.isNotEmpty) {
        final minRam = (catalogItem['minRamRequired'] as num?)?.toDouble() ?? 0;
        if (!HardwareChecker.canRunModel(availableRamGb, minRam)) {
          state = state.copyWith(
            isModelLoading: false,
            error: HardwareChecker.ramShortfallMessage(availableRamGb, minRam),
          );
          return false;
        }
      }
    }

    try {
      final threadCount = threads ?? (hyperparams['threads'] as num?)?.toInt() ?? 4;
      final contextSize = (hyperparams['contextSize'] as num?)?.toInt() ?? 2048;
      final success = await HybridModelManager.instance.loadModelToRam(
        modelId,
        hyperparams: {
          'threads': threadCount,
          'contextSize': contextSize,
        },
      );
      if (success) {
        state = state.copyWith(
          isModelLoading: false,
          loadedModelId: modelId,
        );
        return true;
      } else {
        state = state.copyWith(
          isModelLoading: false,
          error: 'Failed to initialize model in RAM.',
        );
        return false;
      }
    } catch (e) {
      final errorMsg = e.toString();
      if (errorMsg.contains('corrupt') ||
          errorMsg.contains('re-download') ||
          errorMsg.contains('not a valid')) {
        final updatedList = List<String>.from(state.downloadedModelIds)..remove(modelId);
        _prefs?.setStringList('downloaded_model_ids', updatedList);
        state = state.copyWith(
          isModelLoading: false,
          error: errorMsg,
          downloadedModelIds: updatedList,
        );
      } else {
        state = state.copyWith(
          isModelLoading: false,
          error: errorMsg,
        );
      }
      return false;
    }
  }

  Future<void> unloadModel() async {
    await HybridModelManager.instance.unloadModel();
    state = state.copyWith(loadedModelId: null);
  }

  @override
  void dispose() {
    _downloadSubscription?.cancel();
    super.dispose();
  }
}

final modelProvider = StateNotifierProvider<ModelNotifier, ModelState>((ref) {
  return ModelNotifier();
});
