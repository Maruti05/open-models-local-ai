import 'package:flutter/material.dart';
import '../../../core/widgets/collapsible_section.dart';

class ThinkingWidget extends StatelessWidget {
  final String content;
  final bool initiallyExpanded;

  const ThinkingWidget({
    super.key,
    required this.content,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      config: const CollapsibleSectionConfig(
        icon: Icons.lightbulb_outline_rounded,
        title: 'Thinking',
        lightColor: Colors.orange,
        darkColor: Colors.amber,
      ),
      content: content,
      initiallyExpanded: initiallyExpanded,
    );
  }
}
