import 'package:flutter/material.dart';
import '../../../core/widgets/collapsible_section.dart';

class ReasoningWidget extends StatelessWidget {
  final String content;
  final bool initiallyExpanded;

  const ReasoningWidget({
    super.key,
    required this.content,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return CollapsibleSection(
      config: const CollapsibleSectionConfig(
        icon: Icons.psychology_rounded,
        title: 'Reasoning',
        lightColor: Colors.indigo,
        darkColor: Colors.purple,
      ),
      content: content,
      initiallyExpanded: initiallyExpanded,
    );
  }
}
