import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ThinkingBubble extends StatefulWidget {
  const ThinkingBubble({super.key});

  @override
  State<ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<ThinkingBubble>
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 12,
                  color: AppColors.neonCyan.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              ...List.generate(3, (i) {
                final delay = i * 0.15;
                final t = (_controller.value + delay) % 1.0;
                final scale = 0.4 + 0.6 * (1.0 - (t * 4.0 - 1.0).abs().clamp(0.0, 1.0));
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            HSLColor.fromAHSL(0.8, 180 + i * 30.0, 1.0, 0.55).toColor(),
                            HSLColor.fromAHSL(0.8, 220 + i * 20.0, 1.0, 0.6).toColor(),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(width: 6),
              Text('Thinking',
                  style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic,
                      color: AppColors.neonCyan.withValues(alpha: 0.6))),
            ],
          ),
        );
      },
    );
  }
}
