import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class StreamPulse extends StatefulWidget {
  const StreamPulse({super.key});

  @override
  State<StreamPulse> createState() => _StreamPulseState();
}

class _StreamPulseState extends State<StreamPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
          padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final delay = i * 0.15;
              final t = (_controller.value - delay).clamp(0.0, 1.0);
              final opacity = (t < 0.5) ? 0.3 + 0.7 * (t / 0.5) : 1.0 - 0.7 * ((t - 0.5) / 0.5);
              return Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.neonCyan.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
