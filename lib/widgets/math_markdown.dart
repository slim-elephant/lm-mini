import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

/// A widget that renders markdown content with LaTeX math support.
///
/// Splits content into alternating text/math segments:
/// - Block math: `$$...$$` or `\[...\]` — rendered centered on its own line
/// - Inline math: `$...$` or `\(...\)` — rendered inline within text
///
/// Non-math segments are rendered via [MarkdownBody].
/// Math segments are rendered via [Math.tex] from flutter_math_fork.
class MathMarkdown extends StatelessWidget {
  final String data;
  final bool selectable;
  final md.ExtensionSet? extensionSet;
  final MarkdownTapLinkCallback? onTapLink;
  final MarkdownStyleSheet? styleSheet;
  final Map<String, MarkdownElementBuilder>? builders;
  final Color textColor;
  final double baseFontSize;

  const MathMarkdown({
    super.key,
    required this.data,
    this.selectable = true,
    this.extensionSet,
    this.onTapLink,
    this.styleSheet,
    this.builders,
    required this.textColor,
    this.baseFontSize = 13.0,
  });

  @override
  Widget build(BuildContext context) {
    // Pre-process: escape currency $, convert HTML sub/sup to LaTeX, normalize delimiters
    var processed = _escapeCurrencyDollars(data);
    processed = _convertHtmlMathToLatex(processed);
    processed = _normalizeDelimiters(processed);

    // Quick check: if no math delimiters at all, render plain markdown
    if (!_containsMath(processed)) {
      return _buildMarkdownWithInlineMath(processed);
    }

    // Extract only BLOCK math ($$...$$) as separate segments.
    // Inline math ($...$) stays in text for the markdown builder.
    final segments = _extractBlockMath(processed);

    if (segments.length == 1 && !segments[0].isMath) {
      return _buildMarkdownWithInlineMath(segments[0].content);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: segments.map((seg) {
        if (seg.isMath) {
          return _buildBlockMathWidget(context, seg.content);
        } else {
          return _buildMarkdownWithInlineMath(seg.content);
        }
      }).toList(),
    );
  }

  // ── Pre-processing ──────────────────────────────────────────────────

  /// Escape dollar signs that look like currency amounts so they are not
  /// interpreted as LaTeX delimiters.  For example:
  ///   `$91.41 USD`  →  `\$91.41 USD` (in the rendered text, shows as `$91.41 USD`)
  ///   `$3,735,328`  →  `\$3,735,328`
  /// We replace `$` followed by a digit with an escaped dollar.
  /// This works because our _MathInlineSyntax checks for leading backslash.
  static String _escapeCurrencyDollars(String text) {
    // Match $ followed by digits (possibly with commas/dots for thousands/decimals)
    // but NOT $$ (block math delimiter) and NOT already escaped \$
    return text.replaceAllMapped(
      RegExp(r'(?<![\\\$])\$(?!\$)(?=\d)'),
      (m) => r'\$',
    );
  }

  /// Convert HTML <sub>/<sup> tags to LaTeX, grouping with the preceding
  /// base character so e.g. `T<sub>0</sub>` becomes `$T_{0}$`.
  static String _convertHtmlMathToLatex(String text) {
    if (!text.contains('<sub') && !text.contains('<sup')) return text;

    // Match: optional preceding word char + one or more consecutive sub/sup tags
    // e.g. "T<sub>0</sub>" → "$T_{0}$", "e<sup>-kt</sup>" → "$e^{-kt}$"
    final pattern = RegExp(
      r'(\w?)((?:<su[bp]>[^<]*</su[bp]>\s*)+)',
      caseSensitive: false,
    );

    return text.replaceAllMapped(pattern, (match) {
      final base = match.group(1) ?? '';
      var tags = match.group(2)!;
      tags = tags.replaceAllMapped(
        RegExp(r'<sup>(.*?)</sup>', caseSensitive: false),
        (m) => '^{${m.group(1)!}}',
      );
      tags = tags.replaceAllMapped(
        RegExp(r'<sub>(.*?)</sub>', caseSensitive: false),
        (m) => '_{${m.group(1)!}}',
      );
      tags = tags.replaceAll(RegExp(r'\s+'), '');
      return '\$$base$tags\$';
    });
  }

  /// Normalize `\(...\)` → `$...$` and `\[...\]` → `$$...$$`.
  static String _normalizeDelimiters(String text) {
    text = text.replaceAllMapped(
      RegExp(r'\\\((.+?)\\\)', dotAll: true),
      (m) => '\$${m.group(1)!}\$',
    );
    text = text.replaceAllMapped(
      RegExp(r'\\\[([\s\S]+?)\\\]'),
      (m) => '\$\$${m.group(1)!}\$\$',
    );
    return text;
  }

  // ── Detection ───────────────────────────────────────────────────────

  bool _containsMath(String text) {
    return text.contains(r'$$') ||
        RegExp(r'(?<!\\)\$(?!\$)').hasMatch(text);
  }

  // ── Block math extraction ($$...$$ only) ────────────────────────────

  /// Extracts `$$...$$` blocks into separate segments.
  /// Inline math `$...$` stays in the text for the markdown builder.
  List<_MathSegment> _extractBlockMath(String text) {
    final segments = <_MathSegment>[];
    final blockPattern = RegExp(r'\$\$([\s\S]*?)\$\$');
    int lastEnd = 0;

    for (final match in blockPattern.allMatches(text)) {
      if (match.start > lastEnd) {
        final preceding = text.substring(lastEnd, match.start);
        if (preceding.trim().isNotEmpty) {
          segments.add(_MathSegment(content: preceding, isMath: false));
        }
      }
      final tex = match.group(1)!.trim();
      if (tex.isNotEmpty) {
        segments.add(_MathSegment(content: tex, isMath: true, isBlock: true));
      }
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      final remaining = text.substring(lastEnd);
      if (remaining.trim().isNotEmpty) {
        segments.add(_MathSegment(content: remaining, isMath: false));
      }
    }

    if (segments.isEmpty) {
      segments.add(_MathSegment(content: text, isMath: false));
    }

    return segments;
  }

  // ── Rendering ───────────────────────────────────────────────────────

  /// Render markdown text with inline math ($...$) handled via custom builder.
  /// Inline math flows naturally with surrounding text as WidgetSpan.
  Widget _buildMarkdownWithInlineMath(String content) {
    if (content.trim().isEmpty) return const SizedBox.shrink();

    // Inject math inline syntax at highest priority
    final mathSyntax = _MathInlineSyntax();
    final baseSyntaxes = extensionSet?.inlineSyntaxes ??
        md.ExtensionSet.gitHubFlavored.inlineSyntaxes;
    final mergedExtensionSet = md.ExtensionSet(
      extensionSet?.blockSyntaxes ??
          md.ExtensionSet.gitHubFlavored.blockSyntaxes,
      [mathSyntax, ...baseSyntaxes],
    );

    final mergedBuilders = <String, MarkdownElementBuilder>{
      'math': _MathElementBuilder(textColor: textColor, baseFontSize: baseFontSize),
      ...?builders,
    };

    return MarkdownBody(
      data: content,
      selectable: selectable,
      extensionSet: mergedExtensionSet,
      onTapLink: onTapLink,
      styleSheet: styleSheet,
      builders: mergedBuilders,
    );
  }

  /// Render a block math expression with horizontal scrolling for overflow.
  Widget _buildBlockMathWidget(BuildContext context, String tex) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              // Include the raw tex string for the clipboard, but hide it visually
              Offstage(
                child: Text('\$\$$tex\$\$'),
              ),
              SelectionContainer.disabled(
                child: Math.tex(
                  tex,
                  textStyle: TextStyle(color: textColor, fontSize: baseFontSize + 2),
                  mathStyle: MathStyle.display,
                  onErrorFallback: (error) => Text(
                    tex,
                    style: TextStyle(
                      color: textColor,
                      fontFamily: 'monospace',
                      fontSize: baseFontSize,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHigh,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Inline math syntax for the markdown parser ───────────────────────

/// Custom inline syntax that matches `$...$` (single dollar) delimiters
/// and creates a 'math' element for the builder to render as a WidgetSpan.
class _MathInlineSyntax extends md.InlineSyntax {
  // Match $...$ where:
  // - Not preceded by backslash (escaped dollar)
  // - Content has no $ or newline
  // - Content is not empty
  _MathInlineSyntax() : super(r'(?<!\\)\$([^\$\n]+?)\$', startCharacter: 0x24);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final tex = match.group(1)!.trim();
    if (tex.isEmpty) return false;

    // Reject if content looks like currency/natural language rather than math.
    // Real inline math typically contains: operators, greek letters (\alpha),
    // superscripts (^), subscripts (_), fractions (\frac), etc.
    // Currency text contains: digits followed by lots of alphabetical words.
    // Heuristic: if content has 3+ consecutive alpha words, it's not math.
    if (RegExp(r'[a-zA-Z]{2,}\s+[a-zA-Z]{2,}\s+[a-zA-Z]{2,}').hasMatch(tex)) {
      return false;
    }

    final el = md.Element.text('math', tex);
    parser.addNode(el);
    return true;
  }
}

/// Builder that renders 'math' elements inline using flutter_math_fork.
class _MathElementBuilder extends MarkdownElementBuilder {
  final Color textColor;
  final double baseFontSize;
  _MathElementBuilder({required this.textColor, required this.baseFontSize});

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final tex = element.textContent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Offstage(
          child: Text('\$$tex\$'),
        ),
        SelectionContainer.disabled(
          child: Math.tex(
            tex,
            textStyle: TextStyle(color: textColor, fontSize: baseFontSize + 2),
            mathStyle: MathStyle.text,
            onErrorFallback: (error) => Text(
              '\$$tex\$',
              style: TextStyle(
                color: textColor,
                fontFamily: 'monospace',
                fontSize: baseFontSize,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Segment model ────────────────────────────────────────────────────

class _MathSegment {
  final String content;
  final bool isMath;
  final bool isBlock;

  const _MathSegment({
    required this.content,
    required this.isMath,
    this.isBlock = false,
  });
}
