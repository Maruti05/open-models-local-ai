class HardwareChecker {
  HardwareChecker._();

  static int determineModelTier(double availableRamGb) {
    if (availableRamGb < 4.0) {
      return 3;
    } else if (availableRamGb >= 4.0 && availableRamGb < 8.0) {
      return 2;
    } else {
      return 1;
    }
  }

  static int optimalThreadCount(int cpuCores) {
    if (cpuCores <= 2) return 2;
    if (cpuCores <= 4) return cpuCores;
    return (cpuCores * 0.75).round().clamp(4, 16);
  }

  static bool canRunModel(double availableRamGb, double minRamRequired) {
    return availableRamGb >= minRamRequired;
  }

  static String ramShortfallMessage(double availableRamGb, double minRamRequired) {
    final shortfall = minRamRequired - availableRamGb;
    return 'Insufficient RAM (${availableRamGb.toStringAsFixed(1)} GB available, '
        '${minRamRequired.toStringAsFixed(1)} GB required). '
        'Need ${shortfall.toStringAsFixed(1)} GB more.';
  }

  static String getTierLabel(int tier) {
    switch (tier) {
      case 1:
        return 'High-End';
      case 2:
        return 'Mid-Range';
      case 3:
        return 'Entry-Level';
      default:
        return 'Unknown';
    }
  }
}
