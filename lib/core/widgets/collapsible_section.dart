import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CollapsibleSectionConfig {
  final IconData icon;
  final String title;
  final Color lightColor;
  final Color darkColor;
  final String? status;
  final Color? statusSuccessColor;
  final Color? statusWarningColor;

  const CollapsibleSectionConfig({
    required this.icon,
    required this.title,
    required this.lightColor,
    required this.darkColor,
    this.status,
    this.statusSuccessColor,
    this.statusWarningColor,
  });
}

class CollapsibleSection extends StatefulWidget {
  final CollapsibleSectionConfig config;
  final String content;
  final bool initiallyExpanded;
  final EdgeInsetsGeometry? margin;

  const CollapsibleSection({
    super.key,
    required this.config,
    required this.content,
    this.initiallyExpanded = false,
    this.margin,
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? widget.config.darkColor : widget.config.lightColor;

    return Container(
      margin: widget.margin ?? const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Icon(widget.config.icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.config.title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                  if (widget.config.status != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.config.status == 'completed'
                            ? (widget.config.statusSuccessColor ?? AppColors.success).withValues(alpha: 0.15)
                            : (widget.config.statusWarningColor ?? AppColors.warning).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.config.status!,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: widget.config.status == 'completed'
                              ? (widget.config.statusSuccessColor ?? AppColors.success)
                              : (widget.config.statusWarningColor ?? AppColors.warning),
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: color,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: widget.config.status != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.content,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              height: 1.3,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Text(
                      widget.content,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
