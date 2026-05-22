import 'package:flutter/material.dart';
import '../../../core/services/llm_output_parser_service.dart';
import 'markdown_message_widget.dart';

class HtmlRendererWidget extends StatelessWidget {
  final String htmlContent;

  const HtmlRendererWidget({
    super.key,
    required this.htmlContent,
  });

  @override
  Widget build(BuildContext context) {
    final markdown = LLMOutputParserService.convertHtmlToMarkdown(htmlContent);
    return MarkdownMessageWidget(content: markdown);
  }
}
