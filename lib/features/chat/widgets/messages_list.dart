import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/chat_provider.dart';
import 'message_bubble.dart';
import 'thinking_bubble.dart';

class MessagesList extends StatelessWidget {
  final ChatState chatState;
  final ScrollController scrollController;
  final VoidCallback onSend;
  final bool showThinking;
  final bool showReasoning;

  const MessagesList({
    super.key,
    required this.chatState,
    required this.scrollController,
    required this.onSend,
    required this.showThinking,
    required this.showReasoning,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messages = chatState.messages;
    final totalCount = messages.length + (chatState.isGenerating ? 1 : 0);

    if (messages.isEmpty && !chatState.isGenerating) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.textsms_outlined,
                color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.3), size: 36),
            const SizedBox(height: 16),
            Text('Empty Thread',
                style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            const SizedBox(height: 4),
            Text('Ask a prompt to begin native GGUF execution.',
                style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      reverse: true,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (chatState.isGenerating && index == 0) {
          return MessageBubble(
            role: 'assistant',
            content: chatState.streamingMessage,
            isStreaming: true,
            isFirstInGroup: true,
            isLastInGroup: index == totalCount - 1,
            showThinking: showThinking,
            showReasoning: showReasoning,
            thinkingWidget: chatState.streamingMessage.isEmpty
                ? const ThinkingBubble()
                : null,
          );
        }

        final msgIndex = index - (chatState.isGenerating ? 1 : 0);
        final message = messages[msgIndex];
        final role = message['role'] as String;
        final content = message['content'] as String;
        final tps = message['tokens_per_second'] as double?;
        final prevRole = msgIndex < messages.length - 1 ? messages[msgIndex + 1]['role'] as String : null;
        final nextRole = msgIndex > 0 ? messages[msgIndex - 1]['role'] as String : null;

        return MessageBubble(
          role: role,
          content: content,
          tokensPerSec: tps,
          isFirstInGroup: prevRole != role,
          isLastInGroup: nextRole != role,
          showThinking: showThinking,
          showReasoning: showReasoning,
        );
      },
    );
  }
}
