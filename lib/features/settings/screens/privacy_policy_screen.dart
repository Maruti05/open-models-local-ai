import 'package:flutter/material.dart';
import '../../../core/widgets/legal_section.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy'), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const LegalSection(title: 'Data Collection & Storage',
              body: 'All data processing occurs exclusively on-device. No personal information, '
                  'chat history, or model usage data is transmitted, collected, or stored '
                  'on external servers. Your conversations remain entirely within the local '
                  'SQLite database on your device.'),
          const LegalSection(title: 'On-Device Processing',
              body: 'This application operates fully offline. All AI inference is performed '
                  'locally via llama.cpp using downloaded GGUF models. No internet '
                  'connection is required for core functionality, and no data leaves your device.'),
          const LegalSection(title: 'Generated Content',
              body: 'This application runs open-source AI models locally on your device. '
                  'AI model outputs are generated based on user input and may vary. '
                  'You are responsible for the content you generate and how it is used. '
                  'The developers assume no liability for outputs produced by the models.'),
          const LegalSection(title: 'User Responsibility',
              body: 'You are solely responsible for any content you generate, share, or '
                  'distribute using this application. The developers assume no liability '
                  'for outputs produced by the AI models, including any content that '
                  'may be considered offensive, explicit, or illegal in your jurisdiction.'),
          const LegalSection(title: 'Model Files',
              body: 'GGUF model files downloaded through the application are obtained from '
                  'third-party sources (Hugging Face). These files remain on your device '
                  'and are not shared with any third parties by the application itself. '
                  'Review the respective model licenses on Hugging Face for terms of use.'),
          const LegalSection(title: 'Third-Party Services',
              body: 'The application only connects to the internet to download model files '
                  'from Hugging Face when explicitly initiated by the user. No analytics, '
                  'crash reporting, or telemetry services are integrated.'),
          const LegalSection(title: 'Data Deletion',
              body: 'You may delete all locally stored data including chat history and '
                  'downloaded models at any time through the application settings or '
                  'by uninstalling the application.'),
          const LegalSection(title: 'Changes to This Policy',
              body: 'We reserve the right to update this privacy policy. Continued use of '
                  'the application after changes constitutes acceptance of the updated policy.'),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
