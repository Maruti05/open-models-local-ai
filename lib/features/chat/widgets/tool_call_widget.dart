import 'package:flutter/material.dart';
import '../../../core/widgets/collapsible_section.dart';

class ToolCallWidget extends StatelessWidget {
  final String toolName;
  final String arguments;
  final String? status;

  const ToolCallWidget({
    super.key,
    required this.toolName,
    required this.arguments,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      config: CollapsibleSectionConfig(
        icon: Icons.build_rounded,
        title: toolName,
        lightColor: Colors.blue,
        darkColor: Colors.blue,
        status: status,
      ),
      content: arguments,
    );
  }
}
