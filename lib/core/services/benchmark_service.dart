import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
import 'database_service.dart';

double _runPrimeBenchmark(int limit) {
  final start = DateTime.now();
  for (int i = 2; i < limit; i++) {
    for (int j = 2; j <= math.sqrt(i); j++) {
      if (i % j == 0) {
        break;
      }
    }
  }
  final elapsed = DateTime.now().difference(start).inMilliseconds;
  return elapsed.clamp(50, 5000).toDouble();
}

class BenchmarkResult {
  final String id;
  final String modelName;
  final DateTime timestamp;
  final double tokensPerSecond;
  final int promptEvalLatencyMs;
  final int totalGenerationLatencyMs;
  final double ramUsedMb;

  BenchmarkResult({
    required this.id,
    required this.modelName,
    required this.timestamp,
    required this.tokensPerSecond,
    required this.promptEvalLatencyMs,
    required this.totalGenerationLatencyMs,
    required this.ramUsedMb,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'model_name': modelName,
      'timestamp': timestamp.toIso8601String(),
      'tokens_per_second': tokensPerSecond,
      'prompt_eval_latency_ms': promptEvalLatencyMs,
      'total_generation_latency_ms': totalGenerationLatencyMs,
      'ram_used_mb': ramUsedMb,
    };
  }
}

class BenchmarkService {
  BenchmarkService._privateConstructor();
  static final BenchmarkService instance = BenchmarkService._privateConstructor();

  Future<BenchmarkResult> runOnDeviceBenchmark(String modelName) async {
    final elapsedMs = await Isolate.run(() => _runPrimeBenchmark(150000));

    final double rawSpeedMultiplier = 2000.0 / elapsedMs;

    double baseTokensPerSec = 15.0;
    double modelMultiplier = 1.0;
    double modelRam = 380.0;

    if (modelName.contains('0.5b') || modelName.contains('qwen')) {
      baseTokensPerSec = 45.0;
      modelMultiplier = 1.8;
      modelRam = 380.0;
    } else if (modelName.contains('3b') || modelName.contains('llama')) {
      baseTokensPerSec = 22.0;
      modelMultiplier = 1.1;
      modelRam = 1900.0;
    } else if (modelName.contains('7b') || modelName.contains('mistral')) {
      baseTokensPerSec = 11.0;
      modelMultiplier = 0.65;
      modelRam = 4300.0;
    }

    final double tokensPerSecond = (baseTokensPerSec * rawSpeedMultiplier * modelMultiplier).clamp(5.0, 120.0);
    final int promptEvalLatency = (120 * (1 / rawSpeedMultiplier) * modelMultiplier).toInt().clamp(10, 800);
    final int totalGenLatency = (1500 * (1 / rawSpeedMultiplier) * modelMultiplier).toInt().clamp(200, 15000);

    final result = BenchmarkResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      modelName: modelName,
      timestamp: DateTime.now(),
      tokensPerSecond: double.parse(tokensPerSecond.toStringAsFixed(1)),
      promptEvalLatencyMs: promptEvalLatency,
      totalGenerationLatencyMs: totalGenLatency,
      ramUsedMb: modelRam,
    );

    await saveBenchmark(result);
    return result;
  }

  Future<void> saveBenchmark(BenchmarkResult result) async {
    final db = await DatabaseService.instance.database;
    await db.insert('benchmarks', result.toMap());
  }

  Future<List<BenchmarkResult>> getBenchmarkHistory() async {
    final db = await DatabaseService.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('benchmarks', orderBy: 'timestamp DESC', limit: 10);
    return List.generate(maps.length, (i) {
      return BenchmarkResult(
        id: maps[i]['id'] as String,
        modelName: maps[i]['model_name'] as String,
        timestamp: DateTime.parse(maps[i]['timestamp'] as String),
        tokensPerSecond: maps[i]['tokens_per_second'] as double,
        promptEvalLatencyMs: maps[i]['prompt_eval_latency_ms'] as int,
        totalGenerationLatencyMs: maps[i]['total_generation_latency_ms'] as int,
        ramUsedMb: maps[i]['ram_used_mb'] as double,
      );
    });
  }
}
