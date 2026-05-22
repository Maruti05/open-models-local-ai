import 'package:flutter/widgets.dart';

class AppAnimations {
  AppAnimations._();

  // Custom curves matching modern high-fidelity animation guidelines
  static const Curve springCurve = Cubic(0.175, 0.885, 0.32, 1.1);
  static const Curve smoothOutCurve = Cubic(0.23, 1, 0.32, 1);
  static const Curve sharpInCurve = Cubic(0.55, 0.055, 0.675, 0.19);

  // Standard spring physics simulation for lists and page sheet sliding
  static SpringDescription get bouncySpring {
    return const SpringDescription(
      mass: 0.8,
      stiffness: 180.0,
      damping: 12.0,
    );
  }

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 800);
}
