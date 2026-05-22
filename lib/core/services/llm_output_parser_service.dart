enum SegmentType { text, thinking, reasoning, toolCall, codeBlock }

class ContentSegment {
  final SegmentType type;
  final String content;
  final Map<String, String>? metadata;

  const ContentSegment({
    required this.type,
    required this.content,
    this.metadata,
  });
}

class LLMOutputParserService {
  LLMOutputParserService._();

  static final RegExp _thinkingTag = RegExp(
    r'<think>(.*?)</think>',
    dotAll: true,
    caseSensitive: false,
  );
  static final RegExp _thinkingTagAlt = RegExp(
    r'<thinking>(.*?)</thinking>',
    dotAll: true,
    caseSensitive: false,
  );
  static final RegExp _reasoningTag = RegExp(
    r'<reasoning>(.*?)</reasoning>',
    dotAll: true,
    caseSensitive: false,
  );
  static final RegExp _toolCallTag = RegExp(
    r'<(tool_call|tool|function_call|function)>(.*?)</\1>',
    dotAll: true,
    caseSensitive: false,
  );
  static final RegExp _allSpecialTags = RegExp(
    r'</?(think|thinking|reasoning|tool_call|tool|function_call|function|'
    r'plan|system|assistant|user|scratchpad|cot|reflection|observation|'
        r'context|meta|analysis|internal|plan|step|output|input|memory)[^>]*>',
    dotAll: true,
    caseSensitive: false,
  );
  static final RegExp _codeBlock = RegExp(
    r'```(\w*)\n(.*?)```',
    dotAll: true,
    caseSensitive: false,
  );
  static final RegExp _htmlTags = RegExp(
    r'</?(p|br|div|span|ul|ol|li|h1|h2|h3|strong|em|a|pre|code)[^>]*>',
    dotAll: true,
    caseSensitive: false,
  );
  static final RegExp _anyXmlTag = RegExp(
    r'<([a-zA-Z_][a-zA-Z0-9_-]*)(\s[^>]*)?>.*?</\1>',
    dotAll: true,
    caseSensitive: false,
  );

  static List<ContentSegment> parse(
    String rawContent, {
    bool showThinking = true,
    bool showReasoning = true,
  }) {
    final segments = <ContentSegment>[];
    String remaining = rawContent;

    while (remaining.isNotEmpty) {
      int earliestIndex = remaining.length;
      SegmentType? earliestType;
      String? earliestMatch;
      int earliestMatchEnd = 0;
      Map<String, String>? earliestMetadata;

      void checkPattern(RegExp regex, SegmentType type,
          {bool extractMetadata = false}) {
        final match = regex.firstMatch(remaining);
        if (match != null && match.start < earliestIndex) {
          earliestIndex = match.start;
          earliestType = type;
          earliestMatch = match.group(0)!;
          earliestMatchEnd = match.end;
          if (extractMetadata) {
            final tagName = match.group(1)!.toLowerCase();
            earliestMetadata = {'toolName': tagName, 'toolId': tagName};
          }
        }
      }

      checkPattern(_thinkingTag, SegmentType.thinking);
      checkPattern(_thinkingTagAlt, SegmentType.thinking);
      checkPattern(_reasoningTag, SegmentType.reasoning);
      checkPattern(_toolCallTag, SegmentType.toolCall,
          extractMetadata: true);

      if (earliestType == null) {
        if (remaining.trim().isNotEmpty) {
          segments.add(ContentSegment(
            type: SegmentType.text,
            content: remaining.trim(),
          ));
        }
        break;
      }

      if (earliestIndex > 0) {
        final before = remaining.substring(0, earliestIndex).trim();
        if (before.isNotEmpty) {
          segments.add(ContentSegment(
            type: SegmentType.text,
            content: before,
          ));
        }
      }

      if (!showThinking &&
          (earliestType == SegmentType.thinking)) {
        remaining = remaining.substring(earliestMatchEnd);
        continue;
      }

      if (!showReasoning && earliestType == SegmentType.reasoning) {
        remaining = remaining.substring(earliestMatchEnd);
        continue;
      }

      String innerContent;
      if (earliestType == SegmentType.thinking || earliestType == SegmentType.reasoning) {
        final match = RegExp(
          r'<(think|thinking|reasoning)>(.*?)</\1>',
          dotAll: true,
          caseSensitive: false,
        ).firstMatch(earliestMatch!);
        innerContent = match?.group(2)?.trim() ?? '';
      } else {
        final match = RegExp(
          r'<(tool_call|tool|function_call|function)>(.*?)</\1>',
          dotAll: true,
          caseSensitive: false,
        ).firstMatch(earliestMatch!);
        innerContent = match?.group(2)?.trim() ?? '';
      }

      if (earliestType != null) {
        segments.add(ContentSegment(
          type: earliestType!,
          content: innerContent,
          metadata: earliestMetadata,
        ));
      }

      remaining = remaining.substring(earliestMatchEnd);
    }

    return segments;
  }

  static String cleanOutput(String content, {
    bool showThinking = false,
    bool showReasoning = false,
  }) {
    String result = content;
    if (!showThinking) {
      result = result.replaceAll(_thinkingTag, '');
      result = result.replaceAll(_thinkingTagAlt, '');
    }
    if (!showReasoning) {
      result = result.replaceAll(_reasoningTag, '');
    }
    result = result.replaceAll(_toolCallTag, '');
    result = removeUnsupportedTags(result);
    result = normalizeWhitespace(result);
    return result.trim();
  }

  static String sanitizeMarkdown(String content) {
    String result = content;
    result = result.replaceAllMapped(_htmlTags, (match) {
      final tag = match.group(0)!;
      if (tag.startsWith('</')) {
        return '';
      }
      if (tag.startsWith('<br') || tag.startsWith('<p>') || tag.startsWith('<div>')) {
        return '\n';
      }
      if (tag.startsWith('<h1>')) return '# ';
      if (tag.startsWith('<h2>')) return '## ';
      if (tag.startsWith('<h3>')) return '### ';
      if (tag.startsWith('<strong>') || tag.startsWith('<b>')) return '**';
      if (tag.startsWith('</strong>') || tag.startsWith('</b>')) return '**';
      if (tag.startsWith('<em>') || tag.startsWith('<i>')) return '*';
      if (tag.startsWith('</em>') || tag.startsWith('</i>')) return '*';
      if (tag.startsWith('<li>')) return '- ';
      if (tag.startsWith('<code>')) return '`';
      if (tag.startsWith('</code>')) return '`';
      if (tag.startsWith('<pre>')) return '```\n';
      if (tag.startsWith('</pre>')) return '\n```';
      return '';
    });
    return result;
  }

  static List<Map<String, String>> extractCodeBlocks(String content) {
    final blocks = <Map<String, String>>[];
    for (final match in _codeBlock.allMatches(content)) {
      blocks.add({
        'language': match.group(1)?.trim() ?? '',
        'code': match.group(2)?.trim() ?? '',
      });
    }
    return blocks;
  }

  static List<String> extractThinking(String content) {
    final results = <String>[];
    for (final match in _thinkingTag.allMatches(content)) {
      results.add(match.group(1)!.trim());
    }
    for (final match in _thinkingTagAlt.allMatches(content)) {
      results.add(match.group(1)!.trim());
    }
    return results;
  }

  static List<String> extractToolCalls(String content) {
    final results = <String>[];
    for (final match in _toolCallTag.allMatches(content)) {
      results.add(match.group(2)!.trim());
    }
    return results;
  }

  static List<String> extractReasoning(String content) {
    final results = <String>[];
    for (final match in _reasoningTag.allMatches(content)) {
      results.add(match.group(1)!.trim());
    }
    return results;
  }

  static List<String> extractHtml(String content) {
    final results = <String>[];
    for (final match in _htmlTags.allMatches(content)) {
      results.add(match.group(0)!);
    }
    return results;
  }

  static String normalizeWhitespace(String content) {
    String result = content;
    result = result.replaceAll(RegExp(r'\r\n?'), '\n');
    result = result.replaceAll(RegExp(r' {3,}'), '  ');
    result = result.replaceAll(RegExp(r'\n{4,}'), '\n\n\n');
    return result.trim();
  }

  static String removeUnsupportedTags(String content) {
    String result = content;
    result = result.replaceAll(_allSpecialTags, '');
    result = result.replaceAllMapped(_anyXmlTag, (match) {
      final fullTag = match.group(0)!;
      final tagName = match.group(1)?.toLowerCase() ?? '';
      final Set<String> knownTags = {
        'think', 'thinking', 'reasoning', 'tool_call', 'tool',
        'function_call', 'function',
      };
      if (knownTags.contains(tagName)) {
        return fullTag;
      }
      return '';
    });
    return result;
  }

  static String detectLanguageFromCodeBlock(String code, [String? declaredLang]) {
    if (declaredLang != null && declaredLang.isNotEmpty) {
      return declaredLang;
    }
    final codeTrimmed = code.trim();

    if (codeTrimmed.startsWith('import ') &&
        (codeTrimmed.contains('package:') || codeTrimmed.contains('dart:'))) {
      return 'dart';
    }
    if (codeTrimmed.startsWith('fun ') || codeTrimmed.startsWith('val ') ||
        codeTrimmed.startsWith('var ') && codeTrimmed.contains(':')) {
      return 'kotlin';
    }
    if (codeTrimmed.startsWith('public class') ||
        codeTrimmed.startsWith('private class') ||
        codeTrimmed.startsWith('@Override')) {
      return 'java';
    }
    if (codeTrimmed.startsWith('def ') || codeTrimmed.startsWith('import ') &&
        (codeTrimmed.contains('from') || codeTrimmed.contains('as'))) {
      return 'python';
    }
    if ((codeTrimmed.startsWith('const ') || codeTrimmed.startsWith('let ') ||
        codeTrimmed.startsWith('var ')) &&
        (codeTrimmed.contains('=>') || codeTrimmed.contains('function'))) {
      return 'javascript';
    }
    if (codeTrimmed.startsWith('#include') || codeTrimmed.startsWith('int main') ||
        codeTrimmed.startsWith('void ') && codeTrimmed.contains('{')) {
      return 'cpp';
    }
    if (codeTrimmed.startsWith('SELECT') || codeTrimmed.startsWith('select ') ||
        codeTrimmed.startsWith('INSERT') || codeTrimmed.startsWith('CREATE')) {
      return 'sql';
    }
    if (codeTrimmed.startsWith('{') && codeTrimmed.contains('"')) {
      return 'json';
    }
    if (codeTrimmed.startsWith('#!/bin/bash') || codeTrimmed.startsWith('#!/bin/sh') ||
        codeTrimmed.startsWith('#!/usr/bin')) {
      return 'bash';
    }
    if (codeTrimmed.startsWith('<') && (codeTrimmed.contains('</') ||
        codeTrimmed.contains('/>'))) {
      return 'xml';
    }

    return '';
  }

  static String convertHtmlToMarkdown(String html) {
    String result = html;
    result = result.replaceAll(RegExp(r'<h1[^>]*>(.*?)</h1>', dotAll: true, caseSensitive: false), r'# $1\n');
    result = result.replaceAll(RegExp(r'<h2[^>]*>(.*?)</h2>', dotAll: true, caseSensitive: false), r'## $1\n');
    result = result.replaceAll(RegExp(r'<h3[^>]*>(.*?)</h3>', dotAll: true, caseSensitive: false), r'### $1\n');
    result = result.replaceAll(RegExp(r'<strong[^>]*>(.*?)</strong>', dotAll: true, caseSensitive: false), r'**$1**');
    result = result.replaceAll(RegExp(r'<em[^>]*>(.*?)</em>', dotAll: true, caseSensitive: false), r'*$1*');
    result = result.replaceAll(RegExp(r'<code[^>]*>(.*?)</code>', dotAll: true, caseSensitive: false), r'`$1`');
    result = result.replaceAll(RegExp(r'<pre[^>]*>(.*?)</pre>', dotAll: true, caseSensitive: false), r'```\n$1\n```');
    result = result.replaceAll(RegExp(r'<p[^>]*>(.*?)</p>', dotAll: true, caseSensitive: false), r'$1\n\n');
    result = result.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    result = result.replaceAll(RegExp(r'<li[^>]*>(.*?)</li>', dotAll: true, caseSensitive: false), r'- $1\n');
    result = result.replaceAll(RegExp(r'<a\s+href="([^"]*)"[^>]*>(.*?)</a>', dotAll: true, caseSensitive: false), r'[$2]($1)');
    result = result.replaceAll(RegExp(r'</?(?:ul|ol|div|span)[^>]*>', dotAll: true, caseSensitive: false), '');
    result = normalizeWhitespace(result);
    return result.trim();
  }

  static bool isStreamingPartialTag(String content) {
    final openTags = <String>[];
    final tagRegex = RegExp(r'<(/?)([a-zA-Z_][a-zA-Z0-9_-]*)[^>]*>');
    for (final match in tagRegex.allMatches(content)) {
      final isClosing = match.group(1) == '/';
      final tagName = match.group(2)!.toLowerCase();
      if (isClosing) {
        if (openTags.isNotEmpty && openTags.last == tagName) {
          openTags.removeLast();
        }
      } else {
        openTags.add(tagName);
      }
    }
    return openTags.isNotEmpty;
  }

  static String sanitizeStreamingContent(String content) {
    if (!isStreamingPartialTag(content)) return content;
    String result = content;
    result = result.replaceAll(RegExp(r'<think[^>]*$', dotAll: true), '');
    result = result.replaceAll(RegExp(r'<thinking[^>]*$', dotAll: true), '');
    result = result.replaceAll(RegExp(r'<reasoning[^>]*$', dotAll: true), '');
    result = result.replaceAll(RegExp(r'<tool_call[^>]*$', dotAll: true), '');
    result = result.replaceAll(RegExp(r'<tool[^>]*$', dotAll: true), '');
    result = result.replaceAll(RegExp(r'<function_call[^>]*$', dotAll: true), '');
    result = result.replaceAll(RegExp(r'<function[^>]*$', dotAll: true), '');
    return result;
  }
}
