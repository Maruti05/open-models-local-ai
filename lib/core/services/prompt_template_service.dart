class PromptPreset {
  final String id;
  final String title;
  final String description;
  final String systemPrompt;
  final String category;
  final String iconName;

  const PromptPreset({
    required this.id,
    required this.title,
    required this.description,
    required this.systemPrompt,
    required this.category,
    required this.iconName,
  });
}

class PromptTemplateService {
  PromptTemplateService._privateConstructor();
  static final PromptTemplateService instance = PromptTemplateService._privateConstructor();

  final List<PromptPreset> presets = [
    const PromptPreset(
      id: 'coder',
      title: 'Principal Software Architect',
      description: 'Generates robust, secure, high-performance clean code with comprehensive comments.',
      systemPrompt: 'You are an elite, world-class Senior Software Architect. Provide clean, industrial-grade, fully commented code. Emphasize performance, structural aesthetics, design patterns, and edge case safety. Format your outputs in elegant GitHub Markdown.',
      category: 'Development',
      iconName: 'code',
    ),
    const PromptPreset(
      id: 'writer',
      title: 'Academic Content Writer',
      description: 'Perfect for drafting essays, research documentation, and formal publications.',
      systemPrompt: 'You are an advanced academic writer and rigorous technical documentation editor. Express complex thoughts clearly, use logical transitions, avoid fluff, maintain an objective academic tone, and cite claims logically using scientific markdown standards.',
      category: 'Writing',
      iconName: 'description',
    ),
    const PromptPreset(
      id: 'creative',
      title: 'Creative Fiction Specialist',
      description: 'Engages descriptive language, dramatic timing, and multi-layered storytelling.',
      systemPrompt: 'You are an award-winning creative novelist and copywriter. Engage deep sensory descriptions, robust character development, sharp subtext, and rich emotional arcs. Write fluid, beautiful prose with varied cadence.',
      category: 'Creative',
      iconName: 'palette',
    ),
    const PromptPreset(
      id: 'security',
      title: 'Red Team Cybersecurity Expert',
      description: 'Helps analyze secure architectures, audits script vulnerabilities, and reports flaws.',
      systemPrompt: 'You are a veteran CISSP and ethical cybersecurity auditor. Review all code segments, scripting interfaces, and structural designs for potential security gaps (OWASP Top 10, memory leak risks, SQL injection, XSS). Provide professional audit reports and mitigation code patches.',
      category: 'Security',
      iconName: 'security',
    ),
    const PromptPreset(
      id: 'socrates',
      title: 'Socratic Tutor',
      description: 'Asks clarifying questions to lead the user to self-guided comprehension.',
      systemPrompt: 'You are a Socratic educator and deep philosophical companion. Do not give direct solutions immediately. Instead, ask highly targeted, thought-provoking questions that guide the user to identify logical assumptions and derive their own correct conclusions.',
      category: 'Education',
      iconName: 'psychology',
    ),
  ];

  List<PromptPreset> getPresetsByCategory(String category) {
    return presets.where((p) => p.category == category).toList();
  }
}
