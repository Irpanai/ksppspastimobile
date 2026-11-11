import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mendeteksi apakah string mengandung tag HTML format berita.
bool _containsHtmlTags(String input) {
  return RegExp(
    r'</?(?:p|div|span|br|hr|h[1-6]|b|strong|i|em|u|s|del|strike|ul|ol|li|blockquote|table|thead|tbody|tfoot|tr|th|td|a|code|pre)\b[^>]*>',
    caseSensitive: false,
  ).hasMatch(input);
}

/// Mengubah konten HTML berita/promo menjadi teks ringkas polos untuk cuplikan kartu.
String stripHtmlToPlainText(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  if (!_containsHtmlTags(raw)) {
    return raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  var text = raw
      .replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'</?(?:p|div|br|tr|li|h[1-6]|blockquote|table|hr)\b[^>]*>', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'<[^>]+>'), '');

  text = _decodeHtmlEntities(text);
  return text.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _decodeHtmlEntities(String input) {
  var out = input
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&#160;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&ndash;', '–')
      .replaceAll('&mdash;', '—')
      .replaceAll('&rsquo;', '’')
      .replaceAll('&lsquo;', '‘')
      .replaceAll('&rdquo;', '”')
      .replaceAll('&ldquo;', '“')
      .replaceAll('&bull;', '•');

  out = out.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
    final code = int.tryParse(m.group(1) ?? '');
    return (code != null && code > 0 && code <= 0x10FFFF) ? String.fromCharCode(code) : m.group(0)!;
  });

  out = out.replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) {
    final code = int.tryParse(m.group(1) ?? '', radix: 16);
    return (code != null && code > 0 && code <= 0x10FFFF) ? String.fromCharCode(code) : m.group(0)!;
  });

  return out;
}

/// Widget pembaca artikel/berita kaya format (Mendukung bold, italic, underline,
/// warna, daftar poin/nomor, kutipan berita, tautan, & tabel responsif).
class RichArticleViewer extends StatefulWidget {
  final String content;
  final Color accentColor;
  final TextStyle? baseStyle;

  const RichArticleViewer({
    super.key,
    required this.content,
    this.accentColor = const Color(0xFF1B5E20),
    this.baseStyle,
  });

  @override
  State<RichArticleViewer> createState() => _RichArticleViewerState();
}

class _RichArticleViewerState extends State<RichArticleViewer> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  TextStyle get _defaultBaseStyle =>
      widget.baseStyle ??
      const TextStyle(
        fontSize: 14,
        color: Color(0xFF334155),
        height: 1.65,
      );

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final trimmed = widget.content.trim();
    if (trimmed.isEmpty) {
      return const SizedBox.shrink();
    }

    // Jika konten teks polos tanpa tag HTML, tampilkan langsung dengan jarak paragraf rapi
    if (!_containsHtmlTags(trimmed)) {
      return SelectableText(
        trimmed,
        style: _defaultBaseStyle,
      );
    }

    final root = _HtmlParser.parse(trimmed);
    final widgets = _buildBlockWidgets(root.children, _defaultBaseStyle);

    if (widgets.isEmpty) {
      return SelectableText(stripHtmlToPlainText(trimmed), style: _defaultBaseStyle);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }

  List<Widget> _buildBlockWidgets(List<_HtmlNode> nodes, TextStyle baseStyle) {
    final List<Widget> result = [];
    final List<_HtmlNode> inlineBuffer = [];

    void flushInlineBuffer() {
      if (inlineBuffer.isEmpty) return;
      final spans = _buildInlineSpans(inlineBuffer, baseStyle);
      inlineBuffer.clear();
      if (_hasVisibleText(spans)) {
        result.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text.rich(
              TextSpan(children: spans, style: baseStyle),
              textAlign: TextAlign.left,
            ),
          ),
        );
      }
    }

    for (final node in nodes) {
      if (node.isText) {
        if (node.text.trim().isNotEmpty || inlineBuffer.isNotEmpty) {
          inlineBuffer.add(node);
        }
        continue;
      }

      final tag = node.tag;
      if (_isInlineTag(tag)) {
        inlineBuffer.add(node);
        continue;
      }

      flushInlineBuffer();

      switch (tag) {
        case 'h1':
        case 'h2':
        case 'h3':
        case 'h4':
          final headingStyle = _headingStyle(tag, baseStyle);
          final align = _parseTextAlign(node);
          final spans = _buildInlineSpans(node.children, headingStyle);
          if (_hasVisibleText(spans)) {
            result.add(
              Padding(
                padding: EdgeInsets.only(
                  top: result.isEmpty ? 2 : 12,
                  bottom: tag == 'h2' ? 8 : 6,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text.rich(
                      TextSpan(children: spans, style: headingStyle),
                      textAlign: align,
                    ),
                    if (tag == 'h2') ...[
                      const SizedBox(height: 5),
                      Container(height: 1, color: const Color(0xFFF1F5F9)),
                    ],
                  ],
                ),
              ),
            );
          }
          break;

        case 'p':
        case 'div':
          if (_containsBlockChild(node)) {
            result.addAll(_buildBlockWidgets(node.children, baseStyle));
          } else {
            final align = _parseTextAlign(node);
            final styled = _applyInlineStyleAttrs(baseStyle, node.attrs);
            final spans = _buildInlineSpans(node.children, styled);
            if (_hasVisibleText(spans)) {
              result.add(
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text.rich(
                    TextSpan(children: spans, style: styled),
                    textAlign: align,
                  ),
                ),
              );
            }
          }
          break;

        case 'blockquote':
          final quoteStyle = baseStyle.copyWith(
            fontStyle: FontStyle.italic,
            color: const Color(0xFF1E293B),
          );
          final innerWidgets = _buildBlockWidgets(node.children, quoteStyle);
          if (innerWidgets.isNotEmpty) {
            result.add(
              Container(
                margin: const EdgeInsets.only(top: 4, bottom: 12),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.06),
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                  border: Border(
                    left: BorderSide(color: widget.accentColor, width: 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: innerWidgets,
                ),
              ),
            );
          }
          break;

        case 'ul':
        case 'ol':
          result.add(_buildListWidget(node, baseStyle, ordered: tag == 'ol'));
          break;

        case 'hr':
          result.add(
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: Color(0xFFE2E8F0)),
            ),
          );
          break;

        case 'table':
          result.add(_buildTableWidget(node, baseStyle));
          break;

        case 'pre':
          final codeText = _extractPlainText(node);
          if (codeText.trim().isNotEmpty) {
            result.add(
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  codeText.trim(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    color: Color(0xFF0F172A),
                    height: 1.5,
                  ),
                ),
              ),
            );
          }
          break;

        default:
          result.addAll(_buildBlockWidgets(node.children, baseStyle));
          break;
      }
    }

    flushInlineBuffer();
    return result;
  }

  Widget _buildListWidget(_HtmlNode listNode, TextStyle baseStyle, {required bool ordered}) {
    final items = listNode.children.where((c) => !c.isText && c.tag == 'li').toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(items.length, (idx) {
          final item = items[idx];
          final marker = ordered ? '${idx + 1}.' : '•';

          final Widget contentWidget;
          if (_containsBlockChild(item)) {
            contentWidget = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _buildBlockWidgets(item.children, baseStyle),
            );
          } else {
            final spans = _buildInlineSpans(item.children, baseStyle);
            contentWidget = Text.rich(
              TextSpan(children: spans, style: baseStyle),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: ordered ? 24 : 18,
                  child: Text(
                    marker,
                    style: baseStyle.copyWith(
                      fontWeight: FontWeight.bold,
                      color: widget.accentColor,
                    ),
                  ),
                ),
                Expanded(child: contentWidget),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTableWidget(_HtmlNode tableNode, TextStyle baseStyle) {
    final List<_TableRowData> rows = [];

    void collectRows(_HtmlNode container, {bool defaultHeader = false}) {
      for (final child in container.children) {
        if (child.isText) continue;
        if (child.tag == 'tr') {
          final cells = child.children.where((c) => !c.isText && (c.tag == 'th' || c.tag == 'td')).toList();
          if (cells.isNotEmpty) {
            final isHeaderRow = defaultHeader || cells.every((c) => c.tag == 'th');
            rows.add(_TableRowData(cells: cells, isHeader: isHeaderRow));
          }
        } else if (child.tag == 'thead') {
          collectRows(child, defaultHeader: true);
        } else if (child.tag == 'tbody' || child.tag == 'tfoot') {
          collectRows(child, defaultHeader: false);
        }
      }
    }

    collectRows(tableNode);
    if (rows.isEmpty) return const SizedBox.shrink();

    int maxCols = 1;
    for (final r in rows) {
      maxCols = math.max(maxCols, r.cells.length);
    }

    // Estimasi lebar kolom agar tabel sempit memenuhi layar dan tabel lebar bisa di-scroll horizontal
    final List<double> estimatedColWidths = List.filled(maxCols, 92.0);
    for (final r in rows) {
      for (int c = 0; c < r.cells.length; c++) {
        final plain = _extractPlainText(r.cells[c]).trim();
        final wanted = (plain.length * 7.5) + 28.0;
        estimatedColWidths[c] = math.max(estimatedColWidths[c], wanted.clamp(88.0, 210.0));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 320.0;
          final sumEstimated = estimatedColWidths.fold<double>(0, (a, b) => a + b);
          final bool needsHorizontalScroll = sumEstimated > availableWidth + 2;

          final Map<int, TableColumnWidth> colWidths = {};
          final double totalTableWidth;
          if (!needsHorizontalScroll && sumEstimated > 0) {
            final scale = availableWidth / sumEstimated;
            for (int c = 0; c < maxCols; c++) {
              colWidths[c] = FixedColumnWidth(estimatedColWidths[c] * scale);
            }
            totalTableWidth = availableWidth;
          } else {
            for (int c = 0; c < maxCols; c++) {
              colWidths[c] = FixedColumnWidth(estimatedColWidths[c]);
            }
            totalTableWidth = sumEstimated;
          }

          int bodyRowIdx = 0;
          final tableWidget = Container(
            width: totalTableWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Table(
              columnWidths: colWidths,
              defaultVerticalAlignment: TableCellVerticalAlignment.top,
              border: const TableBorder.symmetric(
                inside: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
              children: rows.map((rowData) {
                final bool isHeader = rowData.isHeader;
                final Color rowBg;
                if (isHeader) {
                  rowBg = widget.accentColor.withValues(alpha: 0.1);
                } else {
                  rowBg = (bodyRowIdx % 2 == 1) ? const Color(0xFFF8FAFC) : Colors.white;
                  bodyRowIdx++;
                }

                return TableRow(
                  decoration: BoxDecoration(color: rowBg),
                  children: List.generate(maxCols, (colIdx) {
                    if (colIdx >= rowData.cells.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                        child: SizedBox.shrink(),
                      );
                    }
                    final cellNode = rowData.cells[colIdx];
                    final cellBaseStyle = baseStyle.copyWith(
                      fontSize: 12.5,
                      height: 1.45,
                      fontWeight: isHeader || cellNode.tag == 'th' ? FontWeight.bold : FontWeight.normal,
                      color: isHeader || cellNode.tag == 'th' ? const Color(0xFF0F172A) : const Color(0xFF334155),
                    );
                    final align = _parseTextAlign(cellNode);
                    final spans = _buildInlineSpans(cellNode.children, cellBaseStyle);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      child: Text.rich(
                        TextSpan(
                          children: spans.isEmpty ? [const TextSpan(text: '')] : spans,
                          style: cellBaseStyle,
                        ),
                        textAlign: align,
                      ),
                    );
                  }),
                );
              }).toList(),
            ),
          );

          if (!needsHorizontalScroll) {
            return tableWidget;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: tableWidget,
              ),
              const SizedBox(height: 4),
              const Row(
                children: [
                  Icon(Icons.swipe_rounded, size: 13, color: Color(0xFF94A3B8)),
                  SizedBox(width: 4),
                  Text(
                    'Geser tabel ke samping untuk melihat seluruh kolom',
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  List<InlineSpan> _buildInlineSpans(List<_HtmlNode> nodes, TextStyle currentStyle, {String? linkHref}) {
    final List<InlineSpan> spans = [];

    for (final node in nodes) {
      if (node.isText) {
        final normalized = _normalizeHtmlWhitespace(node.text);
        if (normalized.isEmpty) continue;

        TapGestureRecognizer? recognizer;
        if (linkHref != null && linkHref.isNotEmpty) {
          recognizer = TapGestureRecognizer()..onTap = () => _openUrl(linkHref);
          _recognizers.add(recognizer);
        }

        spans.add(
          TextSpan(
            text: normalized,
            style: currentStyle,
            recognizer: recognizer,
          ),
        );
        continue;
      }

      switch (node.tag) {
        case 'br':
          spans.add(const TextSpan(text: '\n'));
          break;
        case 'b':
        case 'strong':
          spans.addAll(_buildInlineSpans(
            node.children,
            currentStyle.copyWith(fontWeight: FontWeight.bold, color: currentStyle.color ?? const Color(0xFF0F172A)),
            linkHref: linkHref,
          ));
          break;
        case 'i':
        case 'em':
          spans.addAll(_buildInlineSpans(
            node.children,
            currentStyle.copyWith(fontStyle: FontStyle.italic),
            linkHref: linkHref,
          ));
          break;
        case 'u':
          spans.addAll(_buildInlineSpans(
            node.children,
            _mergeDecoration(currentStyle, TextDecoration.underline),
            linkHref: linkHref,
          ));
          break;
        case 's':
        case 'del':
        case 'strike':
          spans.addAll(_buildInlineSpans(
            node.children,
            _mergeDecoration(currentStyle, TextDecoration.lineThrough),
            linkHref: linkHref,
          ));
          break;
        case 'code':
          spans.addAll(_buildInlineSpans(
            node.children,
            currentStyle.copyWith(
              fontFamily: 'monospace',
              fontSize: (currentStyle.fontSize ?? 14) - 1,
              backgroundColor: const Color(0xFFF1F5F9),
              color: const Color(0xFF0F172A),
            ),
            linkHref: linkHref,
          ));
          break;
        case 'a':
          final href = node.attrs['href']?.trim();
          final linkStyle = _mergeDecoration(
            currentStyle.copyWith(color: widget.accentColor, fontWeight: FontWeight.w600),
            TextDecoration.underline,
          );
          spans.addAll(_buildInlineSpans(node.children, linkStyle, linkHref: href));
          break;
        case 'p':
        case 'div':
          // Jika <p> atau <div> berada di dalam sel tabel (td/th), sisip jeda baris antar blok
          final beforeLen = spans.length;
          final styled = _applyInlineStyleAttrs(currentStyle, node.attrs);
          spans.addAll(_buildInlineSpans(node.children, styled, linkHref: linkHref));
          if (spans.length > beforeLen && node != nodes.last) {
            spans.add(const TextSpan(text: '\n'));
          }
          break;
        default:
          final styled = _applyInlineStyleAttrs(currentStyle, node.attrs);
          spans.addAll(_buildInlineSpans(node.children, styled, linkHref: linkHref));
          break;
      }
    }

    return spans;
  }

  TextStyle _headingStyle(String tag, TextStyle baseStyle) {
    final size = switch (tag) {
      'h1' => 19.0,
      'h2' => 16.5,
      'h3' => 15.0,
      _ => 14.0,
    };
    return baseStyle.copyWith(
      fontSize: size,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF0F172A),
      height: 1.35,
    );
  }

  TextStyle _applyInlineStyleAttrs(TextStyle style, Map<String, String> attrs) {
    var updated = style;
    final directColor = attrs['color'];
    if (directColor != null && directColor.isNotEmpty) {
      final parsed = _parseCssColor(directColor);
      if (parsed != null) updated = updated.copyWith(color: parsed);
    }

    final rawStyle = attrs['style'];
    if (rawStyle == null || rawStyle.isEmpty) return updated;

    for (final decl in rawStyle.split(';')) {
      final idx = decl.indexOf(':');
      if (idx == -1) continue;
      final prop = decl.substring(0, idx).trim().toLowerCase();
      final val = decl.substring(idx + 1).trim();

      switch (prop) {
        case 'font-weight':
          if (val == 'bold' || (int.tryParse(val) ?? 0) >= 600) {
            updated = updated.copyWith(fontWeight: FontWeight.bold);
          }
          break;
        case 'font-style':
          if (val == 'italic') {
            updated = updated.copyWith(fontStyle: FontStyle.italic);
          }
          break;
        case 'text-decoration':
          if (val.contains('underline')) {
            updated = _mergeDecoration(updated, TextDecoration.underline);
          }
          if (val.contains('line-through')) {
            updated = _mergeDecoration(updated, TextDecoration.lineThrough);
          }
          break;
        case 'color':
          final parsed = _parseCssColor(val);
          if (parsed != null) updated = updated.copyWith(color: parsed);
          break;
        case 'background-color':
          if (val.toLowerCase() != 'transparent') {
            final parsed = _parseCssColor(val);
            if (parsed != null) updated = updated.copyWith(backgroundColor: parsed);
          }
          break;
      }
    }
    return updated;
  }

  TextAlign _parseTextAlign(_HtmlNode node) {
    final styleAttr = node.attrs['style']?.toLowerCase() ?? '';
    final alignAttr = node.attrs['align']?.toLowerCase() ?? '';
    final combined = '$styleAttr $alignAttr';
    if (combined.contains('center')) return TextAlign.center;
    if (combined.contains('right')) return TextAlign.right;
    if (combined.contains('justify')) return TextAlign.justify;
    return TextAlign.left;
  }

  Color? _parseCssColor(String raw) {
    final val = raw.trim().toLowerCase();
    if (val.startsWith('#')) {
      var hex = val.substring(1);
      if (hex.length == 3) {
        hex = hex.split('').map((c) => '$c$c').join();
      }
      if (hex.length == 6) {
        final n = int.tryParse('FF$hex', radix: 16);
        if (n != null) return Color(n);
      }
    }
    final rgbMatch = RegExp(r'rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)').firstMatch(val);
    if (rgbMatch != null) {
      final r = int.tryParse(rgbMatch.group(1)!) ?? 0;
      final g = int.tryParse(rgbMatch.group(2)!) ?? 0;
      final b = int.tryParse(rgbMatch.group(3)!) ?? 0;
      return Color.fromARGB(255, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255));
    }
    return null;
  }

  TextStyle _mergeDecoration(TextStyle style, TextDecoration add) {
    final existing = style.decoration;
    if (existing == null || existing == TextDecoration.none) {
      return style.copyWith(decoration: add);
    }
    return style.copyWith(decoration: TextDecoration.combine([existing, add]));
  }

  String _normalizeHtmlWhitespace(String raw) {
    final decoded = _decodeHtmlEntities(raw);
    // Pertahankan non-breaking space hanya sebagai spasi tunggal jika berulang antar tag
    return decoded.replaceAll(RegExp(r'[\r\n\t]+'), ' ').replaceAll(RegExp(r' {2,}'), ' ');
  }

  bool _isInlineTag(String tag) {
    return const {'b', 'strong', 'i', 'em', 'u', 's', 'del', 'strike', 'span', 'a', 'code', 'br', 'font'}.contains(tag);
  }

  bool _containsBlockChild(_HtmlNode node) {
    return node.children.any((c) => !c.isText && !_isInlineTag(c.tag));
  }

  bool _hasVisibleText(List<InlineSpan> spans) {
    for (final s in spans) {
      if (s is TextSpan) {
        if ((s.text ?? '').trim().isNotEmpty) return true;
        if (s.children != null && _hasVisibleText(s.children!)) return true;
      }
    }
    return false;
  }

  String _extractPlainText(_HtmlNode node) {
    if (node.isText) return _decodeHtmlEntities(node.text);
    if (node.tag == 'br') return '\n';
    return node.children.map(_extractPlainText).join();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _TableRowData {
  final List<_HtmlNode> cells;
  final bool isHeader;
  const _TableRowData({required this.cells, required this.isHeader});
}

class _HtmlNode {
  final String tag;
  final Map<String, String> attrs;
  final List<_HtmlNode> children;
  final String text;
  final bool isText;

  _HtmlNode.element(this.tag, this.attrs)
      : children = [],
        text = '',
        isText = false;

  _HtmlNode.text(this.text)
      : tag = '#text',
        attrs = const {},
        children = const [],
        isText = true;
}

class _HtmlParser {
  static const _voidTags = {'br', 'hr', 'img', 'input', 'meta', 'link', 'col'};

  static _HtmlNode parse(String html) {
    final root = _HtmlNode.element('root', {});
    final List<_HtmlNode> stack = [root];

    final tagRegex = RegExp(r'<([^>]+)>', dotAll: true);
    int lastIdx = 0;

    for (final match in tagRegex.allMatches(html)) {
      if (match.start > lastIdx) {
        final rawText = html.substring(lastIdx, match.start);
        if (rawText.isNotEmpty) {
          stack.last.children.add(_HtmlNode.text(rawText));
        }
      }
      lastIdx = match.end;

      final inside = match.group(1)!.trim();
      if (inside.isEmpty || inside.startsWith('!')) continue;

      if (inside.startsWith('/')) {
        final closeTag = inside.substring(1).trim().toLowerCase().split(RegExp(r'\s+')).first;
        // Tutup sampai menemukan tag pembuka yang cocok
        for (int i = stack.length - 1; i >= 1; i--) {
          if (stack[i].tag == closeTag) {
            stack.removeRange(i, stack.length);
            break;
          }
        }
        continue;
      }

      final selfClosing = inside.endsWith('/');
      final cleanInside = selfClosing ? inside.substring(0, inside.length - 1).trim() : inside;
      final spaceIdx = cleanInside.indexOf(RegExp(r'\s'));
      final tagName = (spaceIdx == -1 ? cleanInside : cleanInside.substring(0, spaceIdx)).toLowerCase();
      final attrStr = spaceIdx == -1 ? '' : cleanInside.substring(spaceIdx + 1);
      final attrs = _parseAttrs(attrStr);

      // Penutupan implisit untuk <p> sebelum block lain atau <li> sebelum <li>
      if (tagName == 'li' && stack.any((n) => n.tag == 'li')) {
        while (stack.length > 1 && stack.last.tag != 'ul' && stack.last.tag != 'ol') {
          stack.removeLast();
        }
      } else if (const {'p', 'div', 'h1', 'h2', 'h3', 'h4', 'ul', 'ol', 'table', 'blockquote', 'hr'}.contains(tagName) &&
          stack.last.tag == 'p') {
        stack.removeLast();
      }

      final el = _HtmlNode.element(tagName, attrs);
      stack.last.children.add(el);

      if (!selfClosing && !_voidTags.contains(tagName)) {
        stack.add(el);
      }
    }

    if (lastIdx < html.length) {
      final tail = html.substring(lastIdx);
      if (tail.isNotEmpty) {
        stack.last.children.add(_HtmlNode.text(tail));
      }
    }

    return root;
  }

  static Map<String, String> _parseAttrs(String raw) {
    final Map<String, String> attrs = {};
    if (raw.trim().isEmpty) return attrs;

    final attrRegex = RegExp(r'''([a-zA-Z0-9_-]+)\s*(?:=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'>]+)))?''');
    for (final m in attrRegex.allMatches(raw)) {
      final name = m.group(1)!.toLowerCase();
      final val = m.group(2) ?? m.group(3) ?? m.group(4) ?? '';
      attrs[name] = _decodeHtmlEntities(val);
    }
    return attrs;
  }
}
