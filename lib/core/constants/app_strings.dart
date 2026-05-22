class AppStrings {
  AppStrings._();

  // Channel Namespaces
  static const String channelDiagnostics = 'com.vedica.labs/diagnostics';
  static const String channelDownloadStream = 'com.vedica.labs/download_stream';
  static const String channelInferenceStream = 'com.vedica.labs/inference_stream';

  // UI Headers & Strings
  static const String appName = 'OpenModels Local AI';
  static const String dashboardTitle = 'Hardware Telemetry';
  static const String modelCatalogTitle = 'Model Repository';
  static const String chatTitle = 'Local Inference';
  static const String settingsTitle = 'Hyperparameters';

  // Diagnostic Indicators
  static const String ramScanning = 'Scanning Device RAM configuration...';
  static const String cpuScanning = 'Retrieving compute core telemetry...';
  static const String accelScanning = 'Probing Vulkan & NNAPI interfaces...';

  // Error Labels
  static const String errorDbInit = 'Failed to initialize SQLite secure storage.';
  static const String errorChannelFail = 'Native platform interface unavailable.';
  static const String errorOomRisk = 'Model parameters exceed available hardware safe limits!';
}
