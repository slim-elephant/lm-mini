class ParsedResponse {
  final String answer;
  final String? thinking;

  ParsedResponse({required this.answer, this.thinking});
}

class ResponseParser {
  /// Strip hidden tags ([IMG_PROMPT: ...], [MEMORY_SAVE: ...], etc.) from
  /// text intended for TTS or display. Call on `parsed.answer` before
  /// feeding to any TTS service.
  static String cleanForTts(String text) {
    var clean = text;
    // Remove fenced code blocks and inline code.
    clean = clean.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
    clean = clean.replaceAll(RegExp(r'`[^`]+`'), '');
    // Simplify markdown formatting.
    clean = clean.replaceAll(RegExp(r'\*{1,3}'), '');
    clean = clean.replaceAll(RegExp(r'^#+\s*', multiLine: true), '');
    clean = clean.replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1');
    clean = clean.replaceAll(RegExp(r'!\[([^\]]*)\]\([^)]+\)'), '');
    clean = clean.replaceAll(RegExp(r'^[-*_]{3,}\s*$', multiLine: true), '');
    // Strip [IMG_PROMPT: ...] tag (may be partial during streaming)
    clean =
        clean.replaceAll(RegExp(r'\[IMG_PROMPT:\s*.+?\]', dotAll: true), '');
    // Strip incomplete [IMG_PROMPT: ... at end of streaming chunk
    clean = clean.replaceAll(RegExp(r'\[IMG_PROMPT:[^\]]*$', dotAll: true), '');
    // Strip other hidden model tags
    clean = clean.replaceAll(
        RegExp(r'\[(?:MEMORY_SAVE|MEMORY|TOOL|ACTION|FUNCTION_CALL):[^\]]*\]',
            dotAll: true),
        '');
    // Remove emoji and related joiner/variation characters, but keep normal text.
    clean = clean.replaceAll(
      RegExp(
        r'[\u{1F1E6}-\u{1F1FF}'
        r'\u{1F300}-\u{1F5FF}'
        r'\u{1F600}-\u{1F64F}'
        r'\u{1F680}-\u{1F6FF}'
        r'\u{1F700}-\u{1F77F}'
        r'\u{1F780}-\u{1F7FF}'
        r'\u{1F800}-\u{1F8FF}'
        r'\u{1F900}-\u{1F9FF}'
        r'\u{1FA00}-\u{1FAFF}'
        r'\u{2600}-\u{26FF}'
        r'\u{2700}-\u{27BF}'
        r'\u{200D}'
        r'\u{FE0E}'
        r'\u{FE0F}]+',
        unicode: true,
      ),
      '',
    );
    // Collapse whitespace.
    clean = clean.replaceAll(RegExp(r'\s+'), ' ');
    return clean.trim();
  }

  /// Opening markers for in-progress / closed thinking blocks.
  static final RegExp _openThinkPattern = RegExp(
    r'<think>|<thinking>|<reason>|<reasoning>|'
    r'\[think\]|\[thinking\]|'
    // Gemma 4: <|channel>thought … <channel|>
    r'<\|channel>\s*thought\b|'
    // GPT-OSS / Harmony-style analysis channel
    r'<\|channel\|>\s*analysis\b|'
    // Some Qwen / Chinese templates
    r'◁think▷|'
    r'<\|redacted_thinking\|>',
    multiLine: true,
    caseSensitive: false,
  );

  static final RegExp _closeThinkPattern = RegExp(
    r'</think>|</thinking>|</reason>|</reasoning>|'
    r'\[/think\]|\[/thinking\]|'
    r'<channel\|>|'
    r'◁/think▷|'
    r'<\|/redacted_thinking\|>|'
    // GPT-OSS: leaving analysis for final/message channel
    r'<\|channel\|>\s*(?:final|message|commentary)\b',
    multiLine: true,
    caseSensitive: false,
  );

  /// Answer-only text for history reinjection / context estimates.
  /// Strips thinking blocks (including Gemma 4 channel format).
  static String answerOnly(String content) {
    final parsed = parse(content);
    return parsed.answer.trim();
  }

  /// Strip hidden model tags from text meant for people (list preview, titles).
  static String stripHiddenModelTags(String text) {
    var clean = extractImagePrompt(text).cleanContent;
    clean = clean.replaceAll(
      RegExp(
        r'\[(?:MEMORY_SAVE|MEMORY|TOOL|ACTION|FUNCTION_CALL|IMAGE_GEN_INSTRUCTION)[^\]]*\]',
        dotAll: true,
      ),
      '',
    );
    return clean.trim();
  }

  /// Remove every known thinking block from [content], leaving the answer.
  static String stripThinking(String content) {
    var text = content;
    // Gemma 4 asymmetric channel
    text = text.replaceAll(
      RegExp(
        r'<\|channel>\s*thought\b[\s\S]*?<channel\|>',
        caseSensitive: false,
      ),
      '',
    );
    // XML-style + square brackets
    text = text.replaceAll(
      RegExp(r'<think>[\s\S]*?</think>', caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(r'<thinking>[\s\S]*?</thinking>', caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(r'<reason>[\s\S]*?</reason>', caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(r'<reasoning>[\s\S]*?</reasoning>', caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(r'\[think\][\s\S]*?\[/think\]', caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(r'\[thinking\][\s\S]*?\[/thinking\]', caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(r'◁think▷[\s\S]*?◁/think▷', caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(
        r'<\|redacted_thinking\|>[\s\S]*?(?:</think>|<\|/redacted_thinking\|>)',
        caseSensitive: false,
      ),
      '',
    );
    // GPT-OSS analysis → next channel
    text = text.replaceAll(
      RegExp(
        r'<\|channel\|>\s*analysis\b[\s\S]*?(?=<\|channel\|>\s*(?:final|message|commentary)\b)',
        caseSensitive: false,
      ),
      '',
    );
    // Drop leftover channel control tokens from the answer surface
    text = text.replaceAll(
      RegExp(r'<\|channel>\s*thought\b|<channel\|>', caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(
        r'<\|channel\|>\s*(?:analysis|final|message|commentary)\b',
        caseSensitive: false,
      ),
      '',
    );
    return text.trim();
  }

  // Attempts to split thinking vs final answer.
  // Supports common patterns like <think>...</think>, <thinking>...</thinking>,
  // Gemma 4 <|channel>thought … <channel|>, or labeled "Reasoning:" / "Answer:".
  static ParsedResponse parse(String content) {
    final trimmed = content.trim();

    // 0) Opening think marker without a close yet → rest is thinking.
    final openThinkMatch = _openThinkPattern.firstMatch(trimmed);
    final hasClosedThink = _closeThinkPattern.hasMatch(trimmed);
    if (openThinkMatch != null && !hasClosedThink) {
      final preface = trimmed.substring(0, openThinkMatch.start).trim();
      final thinking = trimmed.substring(openThinkMatch.end).trim();
      final cleanedAnswer = _extractAnswerOrFallback(preface);
      return ParsedResponse(
        answer: cleanedAnswer,
        thinking: thinking.isEmpty ? null : thinking,
      );
    }

    // 1a) Gemma 4: <|channel>thought … <channel|> answer
    final gemmaChannel = RegExp(
      r'<\|channel>\s*thought\b\s*([\s\S]*?)<channel\|>',
      caseSensitive: false,
    );
    final gm = gemmaChannel.firstMatch(trimmed);
    if (gm != null) {
      final thinking = (gm.group(1) ?? '').trim();
      final answer =
          (trimmed.substring(0, gm.start) + trimmed.substring(gm.end)).trim();
      if (thinking.isNotEmpty || answer != trimmed) {
        return ParsedResponse(
          answer: _extractAnswerOrFallback(answer),
          thinking: thinking.isEmpty ? null : thinking,
        );
      }
    }

    // 1b) GPT-OSS / Harmony: <|channel|>analysis … <|channel|>final|message
    final ossAnalysis = RegExp(
      r'<\|channel\|>\s*analysis\b\s*([\s\S]*?)(?=<\|channel\|>\s*(?:final|message|commentary)\b)',
      caseSensitive: false,
    );
    final om = ossAnalysis.firstMatch(trimmed);
    if (om != null) {
      final thinking = (om.group(1) ?? '').trim();
      var answer = trimmed.substring(om.end).trim();
      answer = answer.replaceFirst(
        RegExp(r'^<\|channel\|>\s*(?:final|message|commentary)\b\s*',
            caseSensitive: false),
        '',
      );
      if (thinking.isNotEmpty) {
        return ParsedResponse(
          answer: _extractAnswerOrFallback(answer),
          thinking: thinking,
        );
      }
    }

    // 1c) ◁think▷ … ◁/think▷
    final qwenThink =
        RegExp(r'◁think▷([\s\S]*?)◁/think▷', caseSensitive: false);
    final qm = qwenThink.firstMatch(trimmed);
    if (qm != null) {
      final thinking = (qm.group(1) ?? '').trim();
      final answer =
          (trimmed.substring(0, qm.start) + trimmed.substring(qm.end)).trim();
      if (thinking.isNotEmpty) {
        return ParsedResponse(
          answer: _extractAnswerOrFallback(answer),
          thinking: thinking,
        );
      }
    }

    // 1d) <think>...</think>, [think]...[/think], and variants
    final thinkTag = RegExp(r'<think>([\s\S]*?)</think>', multiLine: true);
    final thinkTag2 =
        RegExp(r'<thinking>([\s\S]*?)</thinking>', multiLine: true);
    final reasonTag = RegExp(r'<reason>([\s\S]*?)</reason>', multiLine: true);
    final reasoningTag =
        RegExp(r'<reasoning>([\s\S]*?)</reasoning>', multiLine: true);
    final squareThinkTag =
        RegExp(r'\[think\]([\s\S]*?)\[/think\]', multiLine: true);
    final squareThinkingTag =
        RegExp(r'\[thinking\]([\s\S]*?)\[/thinking\]', multiLine: true);
    final redactedThink = RegExp(
      r'<\|redacted_thinking\|>([\s\S]*?)(?:</think>|<\|/redacted_thinking\|>)',
      multiLine: true,
      caseSensitive: false,
    );

    final m1 = thinkTag.firstMatch(trimmed);
    final m2 = m1 == null ? thinkTag2.firstMatch(trimmed) : null;
    final m3 =
        (m1 == null && m2 == null) ? reasonTag.firstMatch(trimmed) : null;
    final m4 = (m1 == null && m2 == null && m3 == null)
        ? reasoningTag.firstMatch(trimmed)
        : null;
    final m5 = (m1 == null && m2 == null && m3 == null && m4 == null)
        ? squareThinkTag.firstMatch(trimmed)
        : null;
    final m6 =
        (m1 == null && m2 == null && m3 == null && m4 == null && m5 == null)
            ? squareThinkingTag.firstMatch(trimmed)
            : null;
    final m7 = (m1 == null &&
            m2 == null &&
            m3 == null &&
            m4 == null &&
            m5 == null &&
            m6 == null)
        ? redactedThink.firstMatch(trimmed)
        : null;
    final match = m1 ?? m2 ?? m3 ?? m4 ?? m5 ?? m6 ?? m7;

    if (match != null) {
      final thinking = match.group(1)?.trim();
      String answer = (trimmed.substring(match.end)).trim();
      // Thinking may appear mid-message; keep any preface before the block.
      final preface = trimmed.substring(0, match.start).trim();
      if (preface.isNotEmpty) {
        answer = answer.isEmpty ? preface : '$preface\n$answer';
      }
      if (thinking != null && thinking.isNotEmpty) {
        final cleaned = _extractAnswerOrFallback(answer);
        return ParsedResponse(answer: cleaned, thinking: thinking);
      }
    }

    // 2) Code-fence style thinking blocks ```thinking ... ```
    final fencedThink = RegExp(
        r'```\s*(thinking|reasoning)[\r\n]+([\s\S]*?)```',
        multiLine: true);
    final fm = fencedThink.firstMatch(trimmed);
    if (fm != null) {
      final thinking = (fm.group(2) ?? '').trim();
      final remainder = (trimmed.replaceRange(fm.start, fm.end, '')).trim();
      if (thinking.isNotEmpty) {
        final cleaned = _extractAnswerOrFallback(remainder);
        return ParsedResponse(answer: cleaned, thinking: thinking);
      }
    }

    // 3) Labeled blocks: Reasoning: ... Answer: ...
    final labeled = RegExp(
        r'(Reasoning|Thoughts|Thinking)\s*:\s*([\s\S]*?)(?:\n\s*Answer\s*:\s*|$)',
        multiLine: true);
    final lm = labeled.firstMatch(trimmed);
    if (lm != null) {
      final thinking = (lm.group(2) ?? '').trim();
      final after = trimmed.substring(lm.end).trim();
      if (thinking.isNotEmpty) {
        final cleaned =
            _extractAnswerOrFallback(after.isEmpty ? trimmed : after);
        return ParsedResponse(answer: cleaned, thinking: thinking);
      }
    }

    // Fallback: no split
    return ParsedResponse(answer: _extractAnswerOrFallback(trimmed));
  }

  static bool containsClosedThink(String content) {
    return _closeThinkPattern.hasMatch(content);
  }
}

// Private helpers
String _extractAnswerOrFallback(String text) {
  // First, strip outer markdown code fence if the entire response is wrapped
  text = _stripOuterMarkdownFence(text);

  final answerTag = RegExp(r'<answer>([\s\S]*?)</answer>', multiLine: true);
  final m = answerTag.firstMatch(text);
  if (m != null) {
    final inner = (m.group(1) ?? '').trim();
    if (inner.isNotEmpty) return inner;
  }
  // If opening <answer> exists without a closing tag yet, strip the tag
  final openAnswer = RegExp(r'<answer>', multiLine: true).firstMatch(text);
  final hasCloseAnswer = RegExp(r'</answer>', multiLine: true).hasMatch(text);
  if (openAnswer != null && !hasCloseAnswer) {
    final after = text.substring(openAnswer.end).trim();
    if (after.isNotEmpty) return after;
    return '';
  }
  // Some models use <final>...</final>
  final finalTag = RegExp(r'<final>([\s\S]*?)</final>', multiLine: true);
  final mf = finalTag.firstMatch(text);
  if (mf != null) {
    final inner = (mf.group(1) ?? '').trim();
    if (inner.isNotEmpty) return inner;
  }
  // If opening <final> exists without a closing tag yet, strip the tag
  final openFinal = RegExp(r'<final>', multiLine: true).firstMatch(text);
  final hasCloseFinal = RegExp(r'</final>', multiLine: true).hasMatch(text);
  if (openFinal != null && !hasCloseFinal) {
    final after = text.substring(openFinal.end).trim();
    if (after.isNotEmpty) return after;
    return '';
  }

  // Strip <response>...</response> tags
  final responseTag =
      RegExp(r'<response>([\s\S]*?)</response>', multiLine: true);
  final mr = responseTag.firstMatch(text);
  if (mr != null) {
    final inner = (mr.group(1) ?? '').trim();
    if (inner.isNotEmpty) return inner;
  }

  // If opening <response> exists without a closing tag yet, strip the tag
  final openResponse = RegExp(r'<response>', multiLine: true).firstMatch(text);
  final hasCloseResponse =
      RegExp(r'</response>', multiLine: true).hasMatch(text);
  if (openResponse != null && !hasCloseResponse) {
    final after = text.substring(openResponse.end).trim();
    if (after.isNotEmpty) return after;
    return '';
  }

  // Drop stray Gemma / channel control tokens that leaked into the answer.
  text = text
      .replaceAll(
          RegExp(r'<\|channel>\s*thought\b|<channel\|>', caseSensitive: false),
          '')
      .replaceAll(
          RegExp(r'<\|channel\|>\s*(?:analysis|final|message|commentary)\b',
              caseSensitive: false),
          '')
      .replaceAll(RegExp(r'<\|think\|>'), '')
      .trim();

  return text;
}

/// Strips outer markdown code fence if entire response is wrapped in ```markdown ... ```
/// This handles cases where models wrap their markdown response in a code block
String _stripOuterMarkdownFence(String text) {
  final trimmed = text.trim();

  // Check for ```markdown at start (with optional language variants)
  final startPattern =
      RegExp(r'^```\s*(markdown|md|text)?\s*\n', caseSensitive: false);
  final startMatch = startPattern.firstMatch(trimmed);

  if (startMatch != null) {
    // Check if it ends with closing ```
    final endPattern = RegExp(r'\n?```\s*$');
    if (endPattern.hasMatch(trimmed)) {
      // Extract content between the fences
      final content =
          trimmed.substring(startMatch.end).replaceFirst(endPattern, '').trim();
      return content;
    }
  }

  return text;
}

// ─────────────────────────────────────────────────────────────────────────
//  Image Prompt Extraction
// ─────────────────────────────────────────────────────────────────────────

/// Result of extracting an [IMG_PROMPT] tag from AI content.
class ImagePromptResult {
  final String cleanContent; // Content with the tag removed
  final String? imagePrompt; // Extracted prompt, if present

  ImagePromptResult({required this.cleanContent, this.imagePrompt});
}

/// Extracts and strips `[IMG_PROMPT: ...]` from AI responses.
/// Matches the tag anywhere in the content (model may place text after it).
/// Also handles truncated tags where the closing `]` is missing (max output hit).
ImagePromptResult extractImagePrompt(String content) {
  // Complete tags. A reply can contain more than one; drop every copy.
  final regex = RegExp(r'\[IMG_PROMPT:\s*(.+?)\]', dotAll: true);
  final matches = regex.allMatches(content).toList();
  if (matches.isNotEmpty) {
    final prompt = matches.first.group(1)?.trim();
    var clean = content;
    for (final match in matches.reversed) {
      clean = clean.replaceRange(match.start, match.end, '');
    }
    final leftover =
        RegExp(r'\[IMG_PROMPT:\s*(.+)$', dotAll: true).firstMatch(clean);
    if (leftover != null) {
      clean = clean.replaceFirst(leftover.group(0)!, '');
    }
    return ImagePromptResult(cleanContent: clean.trim(), imagePrompt: prompt);
  }

  // Fallback: truncated tag [IMG_PROMPT: ... (no closing bracket — output limit hit)
  final truncatedRegex = RegExp(r'\[IMG_PROMPT:\s*(.+)$', dotAll: true);
  final truncatedMatch = truncatedRegex.firstMatch(content);
  if (truncatedMatch != null) {
    final prompt = truncatedMatch.group(1)?.trim();
    if (prompt != null && prompt.isNotEmpty) {
      final clean = content.replaceFirst(truncatedMatch.group(0)!, '').trim();
      return ImagePromptResult(cleanContent: clean, imagePrompt: prompt);
    }
  }

  return ImagePromptResult(cleanContent: content);
}
