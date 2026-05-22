import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'ai_message_widget.dart';

class MessageBubble extends StatelessWidget {
  final String role;
  final String content;
  final double? tokensPerSec;
  final bool isStreaming;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool showThinking;
  final bool showReasoning;
  final Widget? thinkingWidget;

  const MessageBubble({
    super.key,
    required this.role,
    required this.content,
    this.tokensPerSec,
    this.isStreaming = false,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    this.showThinking = true,
    this.showReasoning = true,
    this.thinkingWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = role == 'user';
    final tps = tokensPerSec;
    final showThinkingIndicator = thinkingWidget != null;

    Color bgColor;
    Color borderColor;
    if (isUser) {
      bgColor = isDark
          ? AppColors.vibrantIndigo.withValues(alpha: 0.2)
          : AppColors.vibrantIndigo.withValues(alpha: 0.1);
      borderColor = AppColors.vibrantIndigo.withValues(alpha: 0.25);
    } else {
      bgColor = isDark ? AppColors.darkCardBg : Colors.white;
      borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    }

    final verticalMargin = isFirstInGroup && isLastInGroup
        ? 6.0
        : isFirstInGroup || isLastInGroup ? 4.0 : 0.5;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalMargin),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isUser ? 18 : (isLastInGroup ? 18 : 4)),
              bottomRight: Radius.circular(isUser ? (isLastInGroup ? 4 : 18) : 18),
            ),
            border: Border.all(color: borderColor, width: 0.8),
            boxShadow: isFirstInGroup
                ? [BoxShadow(color: (isDark ? Colors.black : Colors.black12).withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 2))]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isFirstInGroup)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    isUser ? 'You' : 'Agent',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isUser
                          ? AppColors.vibrantIndigo.withValues(alpha: 0.8)
                          : AppColors.neonCyan.withValues(alpha: 0.8),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              if (showThinkingIndicator)
                thinkingWidget!
              else if (isUser)
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                )
              else
                AiMessageWidget(
                  content: content,
                  isStreaming: isStreaming,
                  showThinking: showThinking,
                  showReasoning: showReasoning,
                ),
              if (!isUser && tps != null && !isStreaming) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 10, color: AppColors.neonCyan.withValues(alpha: 0.7)),
                    const SizedBox(width: 3),
                    Text('${tps.toStringAsFixed(1)} tok/s', style: TextStyle(fontSize: 9, color: AppColors.neonCyan.withValues(alpha: 0.7))),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
