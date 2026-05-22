import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

enum CurveType { temperature, topP, topK, maxTokens }

class ParameterCurve extends StatelessWidget {
  final CurveType type;
  final double value;
  final double height;

  const ParameterCurve({
    super.key,
    required this.type,
    required this.value,
    this.height = 64,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _CurvePainter(type: type, value: value, isDark: isDark),
        size: Size.infinite,
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  final CurveType type;
  final double value;
  final bool isDark;

  _CurvePainter({required this.type, required this.value, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..color = (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final h = size.height;
    final w = size.width;

    canvas.drawLine(Offset(0, h - 1), Offset(w, h - 1), bgPaint);

    switch (type) {
      case CurveType.temperature:
        _drawTemperatureCurve(canvas, size);
      case CurveType.topP:
        _drawTopPCurve(canvas, size);
      case CurveType.topK:
        _drawTopKCurve(canvas, size);
      case CurveType.maxTokens:
        _drawMaxTokensCurve(canvas, size);
    }
  }

  void _drawTemperatureCurve(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    final fillPath = Path();

    final normalizedTemp = (value - 0.1) / (1.5 - 0.1);
    final sharpness = 1.0 - (normalizedTemp * 0.85);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [AppColors.neonCyan, AppColors.vibrantIndigo],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [
          AppColors.neonCyan.withValues(alpha: 0.25),
          AppColors.vibrantIndigo.withValues(alpha: 0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final points = 60;
    double maxY = 0;
    final ys = <double>[];

    for (int i = 0; i <= points; i++) {
      final t = i / points;
      final center = 0.5;
      final sigma = sharpness * 0.12 + 0.03;
      final y = math.exp(-math.pow(t - center, 2) / (2 * sigma * sigma));
      ys.add(y);
      if (y > maxY) maxY = y;
    }

    for (int i = 0; i <= points; i++) {
      final t = i / points;
      final x = t * w;
      final y = h - (ys[i] / maxY) * (h - 8) - 4;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, h);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(w, h);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = AppColors.neonCyan
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h - (ys[30] / maxY) * (h - 8) - 4), 4, dotPaint);
  }

  void _drawTopPCurve(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = AppColors.vibrantIndigo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = AppColors.vibrantIndigo.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();
    final points = 40;

    for (int i = 0; i <= points; i++) {
      final t = i / points;
      final x = t * w;
      final prob = 1.0 - math.exp(-5 * t);
      final cutoff = t <= value ? prob : prob * math.exp(-8 * (t - value));
      final y = h - (cutoff * (h - 8)) - 4;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, h);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(w, h);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final linePaint = Paint()
      ..color = AppColors.warning.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final cutX = value * w;
    canvas.drawLine(Offset(cutX, 0), Offset(cutX, h), linePaint);

    final labelPaint = Paint()
      ..color = AppColors.warning
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cutX, 4), 3, labelPaint);
  }

  void _drawTopKCurve(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final kNormalized = (value - 5) / (100 - 5);
    final visibleCount = (kNormalized * 20).round().clamp(2, 20);

    final barWidth = w / 24;
    final startX = (w - (visibleCount * barWidth)) / 2;

    for (int i = 0; i < visibleCount; i++) {
      final barH = 4.0 + (math.Random(i + 1).nextDouble() * (h - 16));
      final isSelected = i < (visibleCount * 0.4).round();

      final barPaint = Paint()
        ..color = isSelected
            ? AppColors.success
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(startX + i * barWidth + 2, h - barH, barWidth - 4, barH),
          const Radius.circular(2),
        ),
        barPaint,
      );
    }

    final labelPaint = Paint()
      ..color = AppColors.success
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(startX + (visibleCount * 0.4).round() * barWidth, 6), 3, labelPaint);
  }

  void _drawMaxTokensCurve(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final normalized = (value - 64) / (2048 - 64);
    final fillWidth = w * normalized;

    final trackPaint = Paint()
      ..color = (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final wavePaint = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.vibrantIndigo, AppColors.neonCyan],
      ).createShader(Rect.fromLTWH(0, h * 0.3, fillWidth, h * 0.4))
      ..style = PaintingStyle.fill;

    final points = 30;
    final wavePath = Path();
    final baseH = h * 0.4;

    for (int i = 0; i <= points; i++) {
      final t = i / points;
      final x = t * fillWidth;
      final oscillation = math.sin(t * math.pi * 6) * 6;
      final y = baseH + oscillation;
      if (i == 0) {
        wavePath.moveTo(x, h);
        wavePath.lineTo(x, y);
      } else {
        wavePath.lineTo(x, y);
      }
    }
    wavePath.lineTo(fillWidth, h);
    wavePath.close();
    canvas.drawPath(wavePath, wavePaint);

    canvas.drawLine(Offset(0, h * 0.4), Offset(w, h * 0.4), trackPaint);
    canvas.drawLine(Offset(fillWidth, 0), Offset(fillWidth, h), trackPaint);

    final dotPaint = Paint()
      ..color = AppColors.neonCyan
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(fillWidth, h * 0.4), 4, dotPaint);
  }

  @override
  bool shouldRepaint(_CurvePainter old) => old.value != value || old.isDark != isDark;
}
