import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/native_bridge.dart';
import '../../../core/utils/hardware_checker.dart';

class DiagnosticsState {
  final bool isLoading;
  final double totalRamGb;
  final double availableRamGb;
  final int cores;
  final bool vulkan;
  final bool nnapi;
  final int modelTier;
  final String error;

  DiagnosticsState({
    this.isLoading = true,
    this.totalRamGb = 0.0,
    this.availableRamGb = 0.0,
    this.cores = 1,
    this.vulkan = false,
    this.nnapi = false,
    this.modelTier = 3,
    this.error = '',
  });

  DiagnosticsState copyWith({
    bool? isLoading,
    double? totalRamGb,
    double? availableRamGb,
    int? cores,
    bool? vulkan,
    bool? nnapi,
    int? modelTier,
    String? error,
  }) {
    return DiagnosticsState(
      isLoading: isLoading ?? this.isLoading,
      totalRamGb: totalRamGb ?? this.totalRamGb,
      availableRamGb: availableRamGb ?? this.availableRamGb,
      cores: cores ?? this.cores,
      vulkan: vulkan ?? this.vulkan,
      nnapi: nnapi ?? this.nnapi,
      modelTier: modelTier ?? this.modelTier,
      error: error ?? this.error,
    );
  }
}

class DiagnosticsNotifier extends StateNotifier<DiagnosticsState> {
  DiagnosticsNotifier() : super(DiagnosticsState()) {
    scanHardware();
  }

  Future<void> scanHardware() async {
    state = state.copyWith(isLoading: true, error: '');
    try {
      final specs = await NativeBridge.instance.checkHardware();
      if (specs.containsKey('error')) {
        state = state.copyWith(
          isLoading: false,
          error: specs['error'].toString(),
        );
        return;
      }

      final availableRam = specs['availableRamGb'] as double? ?? 0.0;
      final tier = HardwareChecker.determineModelTier(availableRam);

      state = DiagnosticsState(
        isLoading: false,
        totalRamGb: specs['totalRamGb'] as double? ?? 0.0,
        availableRamGb: availableRam,
        cores: specs['cores'] as int? ?? 1,
        vulkan: specs['vulkan'] as bool? ?? false,
        nnapi: specs['nnapi'] as bool? ?? false,
        modelTier: tier,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final diagnosticsProvider =
    StateNotifierProvider<DiagnosticsNotifier, DiagnosticsState>((ref) {
  return DiagnosticsNotifier();
});
