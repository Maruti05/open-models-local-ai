import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/llm_output_parser_service.dart';
import 'code_block_widget.dart';
import 'markdown_message_widget.dart';
import 'reasoning_widget.dart';
import 'thinking_widget.dart';
import 'tool_call_widget.dart';

class AiMessageWidget extends StatelessWidget {
  final String content;
  final bool isStreaming;
  final bool showThinking;
  final bool showReasoning;

  const AiMessageWidget({
    super.key,
    required this.content,
    this.isStreaming = false,
    this.showThinking = true,
    this.showReasoning = true,
  });

  @override
  Widget build(BuildContext context) {
    if (content.isEmpty) return const SizedBox.shrink();

    if (isStreaming) {
      final safeContent = LLMOutputParserService.removeUnsupportedTags(
        LLMOutputParserService.sanitizeStreamingContent(content),
      );
      if (safeContent.isEmpty && content.isNotEmpty) {
        return _buildStreamingOverflow();
      }
      if (safeContent.isEmpty) return const SizedBox.shrink();
      return MarkdownMessageWidget(content: safeContent);
    }

    final segments = LLMOutputParserService.parse(
      content,
      showThinking: showThinking,
      showReasoning: showReasoning,
    );

    if (segments.length == 1 && segments.first.type == SegmentType.text) {
      return _buildContentWithCodeBlocks(segments.first.content);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: segments.map((segment) {
        return _buildSegment(segment);
      }).toList(),
    );
  }

  Widget _buildStreamingOverflow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hourglass_top_rounded,
            size: 12,
            color: AppColors.neonCyan.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 6),
          Text(
            'Processing...',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.neonCyan.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(ContentSegment segment) {
    switch (segment.type) {
      case SegmentType.thinking:
        return ThinkingWidget(content: segment.content);
      case SegmentType.reasoning:
        return ReasoningWidget(content: segment.content);
      case SegmentType.toolCall:
        return ToolCallWidget(
          toolName: segment.metadata?['toolName'] ?? 'Tool',
          arguments: segment.content,
          status: segment.metadata?['status'],
        );
      case SegmentType.text:
        return _buildContentWithCodeBlocks(segment.content);
      case SegmentType.codeBlock:
        return CodeBlockWidget(
          code: segment.content,
          language: LLMOutputParserService.detectLanguageFromCodeBlock(
            segment.content,
          ),
        );
    }
  }

  Widget _buildContentWithCodeBlocks(String content) {
    final cleaned =
        LLMOutputParserService.removeUnsupportedTags(content).trim();
    final codeBlocks = LLMOutputParserService.extractCodeBlocks(cleaned);

    if (codeBlocks.isEmpty) {
      return MarkdownMessageWidget(content: content);
    }

    final codeBlockRegex = RegExp(
      r'```(\w*)\n(.*?)```',
      dotAll: true,
      caseSensitive: false,
    );

    final parts = <Widget>[];
    int lastEnd = 0;

    for (final match in codeBlockRegex.allMatches(content)) {
      final start = match.start;
      final end = match.end;
      final before = content.substring(lastEnd, start).trim();
      if (before.isNotEmpty) {
        parts.add(Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: MarkdownMessageWidget(content: before),
        ));
      }
      parts.add(Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: CodeBlockWidget(
          code: match.group(2)?.trim() ?? '',
          language: match.group(1)?.trim() ?? '',
        ),
      ));
      lastEnd = end;
    }

    final after = content.substring(lastEnd).trim();
    if (after.isNotEmpty) {
      parts.add(MarkdownMessageWidget(content: after));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: parts,
    );
  }
}
