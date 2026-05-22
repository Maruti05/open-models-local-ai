import 'model_format.dart';

class ModelInfo {
  final String id;
  final String name;
  final String params;
  final double sizeMb;
  final double minRamGb;
  final int tier;
  final String description;
  final String downloadUrl;
  final ModelFormat format;

  const ModelInfo({
    required this.id,
    required this.name,
    required this.params,
    required this.sizeMb,
    required this.minRamGb,
    required this.tier,
    required this.description,
    required this.downloadUrl,
    required this.format,
  });

  double get sizeGb => sizeMb / 1024;

  factory ModelInfo.fromCatalogEntry(Map<String, dynamic> entry) {
    final sizeGb = (entry['sizeGb'] as num?)?.toDouble() ?? 0.0;
    final downloadUrl = entry['downloadUrl'] as String? ?? '';
    final format = ModelFormat.fromExtension(downloadUrl);

    return ModelInfo(
      id: entry['id'] as String? ?? '',
      name: entry['name'] as String? ?? '',
      params: entry['params'] as String? ?? '',
      sizeMb: sizeGb * 1024,
      minRamGb: (entry['minRamRequired'] as num?)?.toDouble() ?? 0.0,
      tier: (entry['tier'] as num?)?.toInt() ?? 3,
      description: entry['description'] as String? ?? '',
      downloadUrl: downloadUrl,
      format: format,
    );
  }

  Map<String, dynamic> toCatalogEntry() {
    return {
      'id': id,
      'name': name,
      'sizeGb': sizeGb,
      'params': params,
      'minRamRequired': minRamGb,
      'tier': tier,
      'description': description,
      'downloadUrl': downloadUrl,
      'format': format.name,
    };
  }
}
