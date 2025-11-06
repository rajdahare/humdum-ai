import 'package:flutter/material.dart';
import '../models/message.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  const ChatBubble({super.key, required this.message});

  List<TextSpan> _parseMarkdown(String text, Color defaultColor, TextStyle baseStyle) {
    final spans = <TextSpan>[];
    
    // Simple recursive parsing: find first markdown pattern and process it
    int pos = 0;
    final boldPattern = RegExp(r'\*\*(.+?)\*\*|__(.+?)__');
    final codePattern = RegExp(r'`([^`]+)`');
    final italicPattern = RegExp(r'(?<!\*)\*([^*\n]+)\*(?!\*)');
    
    while (pos < text.length) {
      Match? earliestMatch;
      String? matchText;
      TextStyle? matchStyle;
      
      // Find the earliest match after pos across all patterns
      // Check for bold (**text** or __text__)
      for (final boldMatch in boldPattern.allMatches(text)) {
        if (boldMatch.start < pos) continue;
        if (earliestMatch == null || boldMatch.start < earliestMatch.start) {
          earliestMatch = boldMatch;
          matchText = boldMatch.group(1) ?? boldMatch.group(2);
          matchStyle = baseStyle.copyWith(
            color: defaultColor,
            fontWeight: FontWeight.bold,
          );
        }
      }
      
      // Check for code (`text`)
      for (final codeMatch in codePattern.allMatches(text)) {
        if (codeMatch.start < pos) continue;
        if (earliestMatch == null || codeMatch.start < earliestMatch.start) {
          earliestMatch = codeMatch;
          matchText = codeMatch.group(1);
          matchStyle = baseStyle.copyWith(
            color: defaultColor.withOpacity(0.9),
            fontFamily: 'monospace',
            fontSize: (baseStyle.fontSize ?? 15) * 0.9,
            backgroundColor: defaultColor.withOpacity(0.2),
          );
        }
      }
      
      // Check for italic (*text* but not **text**)
      for (final italicMatch in italicPattern.allMatches(text)) {
        if (italicMatch.start < pos) continue;
        // Make sure it's not part of a bold pattern
        if (italicMatch.start == 0 || text[italicMatch.start - 1] != '*') {
          if (earliestMatch == null || italicMatch.start < earliestMatch.start) {
            earliestMatch = italicMatch;
            matchText = italicMatch.group(1);
            matchStyle = baseStyle.copyWith(
              color: defaultColor,
              fontStyle: FontStyle.italic,
            );
          }
        }
      }
      
      final nextMatchPos = earliestMatch?.start;
      
      // Add text before the match
      if (nextMatchPos != null && nextMatchPos > pos) {
        spans.add(TextSpan(
          text: text.substring(pos, nextMatchPos),
          style: baseStyle.copyWith(color: defaultColor),
        ));
      }
      
      // Add the matched formatted text
      if (nextMatchPos != null && matchText != null && matchStyle != null && earliestMatch != null) {
        spans.add(TextSpan(text: matchText, style: matchStyle));
        pos = earliestMatch.end; // Move to end of matched pattern
      } else {
        // No more matches, add remaining text
        spans.add(TextSpan(
          text: text.substring(pos),
          style: baseStyle.copyWith(color: defaultColor),
        ));
        break;
      }
    }
    
    // If no formatting found, return simple text span
    if (spans.length == 1 && spans.first.text == text) {
      return spans;
    }
    
    return spans;
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:$minute $amPm';
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == Sender.user;
    final scheme = Theme.of(context).colorScheme;
    final bg = isUser ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final txt = isUser ? scheme.onPrimaryContainer : scheme.onSurface;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;

    final baseStyle = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final textSpans = _parseMarkdown(message.text, txt, baseStyle);

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          child: Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 6),
                    bottomRight: Radius.circular(isUser ? 6 : 20),
                  ),
                  border: Border.all(
                    color: isUser
                        ? scheme.primary.withOpacity(0.2)
                        : scheme.outline.withOpacity(0.1),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: SelectableText.rich(
                  TextSpan(children: textSpans),
                  style: baseStyle.copyWith(
                    color: txt,
                    height: 1.6,
                    fontSize: 15,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
                child: Text(
                  _formatTime(message.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant.withOpacity(0.6),
                        fontSize: 11,
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


