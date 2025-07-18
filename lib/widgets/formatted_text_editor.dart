import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';


class FormattedTextEditor extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final TextAlign textAlign;
  final double fontSize;
  final Function(String) onChanged;
  final List<FormattingSpan>? initialFormatting;

  const FormattedTextEditor({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.textAlign,
    required this.fontSize,
    required this.onChanged,
    this.initialFormatting,
  }) : super(key: key);

  @override
  State<FormattedTextEditor> createState() => _FormattedTextEditorState();
}

class _FormattedTextEditorState extends State<FormattedTextEditor> {
  
  List<FormattingSpan> _formattingSpans = [];

  List<FormattingSpan> getFormattingSpans() =>
      List.unmodifiable(_formattingSpans);
  void setFormattingSpans(List<FormattingSpan> spans) {
    setState(() {
      _formattingSpans = List.from(spans);
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialFormatting != null) {
      _formattingSpans = List.from(widget.initialFormatting!);
    }
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    
    _updateFormattingSpans();
    widget.onChanged(widget.controller.text);
  }

  void _updateFormattingSpans() {
    
    
    setState(() {});
  }

  
  void addFormatting(FormattingType type, {double? fontSize, String? url}) {
    final selection = widget.controller.selection;
    if (!selection.isValid || selection.isCollapsed) return;

    setState(() {
      _formattingSpans.add(
        FormattingSpan(
          start: selection.start,
          end: selection.end,
          type: type,
          fontSize: fontSize,
          url: url,
        ),
      );
    });
  }

  
  void removeFormatting(FormattingType type) {
    final selection = widget.controller.selection;
    if (!selection.isValid || selection.isCollapsed) return;

    setState(() {
      _formattingSpans.removeWhere(
        (span) =>
            span.type == type &&
            span.start == selection.start &&
            span.end == selection.end,
      );
    });
  }

  
  void addLink(String url) {
    final selection = widget.controller.selection;
    if (!selection.isValid || selection.isCollapsed) return;

    setState(() {
      _formattingSpans.add(
        FormattingSpan(
          start: selection.start,
          end: selection.end,
          type: FormattingType.link,
          url: url,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        
        TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          decoration: const InputDecoration(
            hintText: 'Start writing...',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          style: TextStyle(
            fontSize: widget.fontSize,
            color: Colors.transparent, 
            height: 1.5,
          ),
          textAlign: widget.textAlign,
          maxLines: null,
          expands: true,
          textAlignVertical: TextAlignVertical.top,
          cursorColor: Colors.white,
          enableInteractiveSelection: true,
        ),

        
        IgnorePointer(
          child: Container(
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.only(top: 2),
            child: AnimatedBuilder(
              animation: widget.controller,
              builder: (context, child) {
                return RichText(
                  textAlign: widget.textAlign,
                  text: _buildFormattedText(),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  TextSpan _buildFormattedText() {
    if (widget.controller.text.isEmpty) {
      return const TextSpan(
        text: 'Start writing...',
        style: TextStyle(color: Colors.grey, height: 1.5),
      );
    }

    final text = widget.controller.text;
    final List<InlineSpan> spans = [];

    
    _formattingSpans.sort((a, b) => a.start.compareTo(b.start));

    int currentPos = 0;

    
    for (final span in _formattingSpans) {
      
      if (span.start < 0 || span.end > text.length || span.start >= span.end) {
        continue;
      }
      
      if (span.start > currentPos) {
        final safeStart = currentPos.clamp(0, text.length);
        final safeEnd = span.start.clamp(0, text.length);
        if (safeStart < safeEnd) {
          spans.add(
            TextSpan(
              text: text.substring(safeStart, safeEnd),
              style: TextStyle(color: Colors.white, fontSize: widget.fontSize),
            ),
          );
        }
      }

      
      final safeSpanStart = span.start.clamp(0, text.length);
      final safeSpanEnd = span.end.clamp(0, text.length);
      if (safeSpanStart >= safeSpanEnd) {
        currentPos = safeSpanEnd;
        continue;
      }
      final formattedText = text.substring(safeSpanStart, safeSpanEnd);
      TextStyle style = TextStyle(
        color: Colors.white,
        fontSize: span.fontSize ?? widget.fontSize,
      );

      switch (span.type) {
        case FormattingType.bold:
          style = style.copyWith(fontWeight: FontWeight.bold);
          break;
        case FormattingType.italic:
          style = style.copyWith(fontStyle: FontStyle.italic);
          break;
        case FormattingType.underline:
          style = style.copyWith(decoration: TextDecoration.underline);
          break;
        case FormattingType.strikethrough:
          style = style.copyWith(decoration: TextDecoration.lineThrough);
          break;
        case FormattingType.highlight:
          style = style.copyWith(
            backgroundColor: Colors.yellow,
            color: Colors.black,
          );
          break;
        case FormattingType.link:
          style = style.copyWith(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          );
          spans.add(
            TextSpan(
              text: formattedText,
              style: style,
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  
                  if (span.url != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening:  {span.url}')),
                    );
                  }
                },
            ),
          );
          currentPos = safeSpanEnd;
          continue;
        case FormattingType.fontSize:
          
          break;
      }

      spans.add(TextSpan(text: formattedText, style: style));
      currentPos = safeSpanEnd;
    }

    
    if (currentPos < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(currentPos),
          style: TextStyle(color: Colors.white, fontSize: widget.fontSize),
        ),
      );
    }

    return TextSpan(
      style: TextStyle(height: 1.5, fontSize: widget.fontSize),
      children: spans,
    );
  }
}


enum FormattingType {
  bold,
  italic,
  underline,
  strikethrough,
  highlight,
  link,
  fontSize,
}


class FormattingSpan {
  final int start;
  final int end;
  final FormattingType type;
  final double? fontSize;
  final String? url;

  FormattingSpan({
    required this.start,
    required this.end,
    required this.type,
    this.fontSize,
    this.url,
  });

  Map<String, dynamic> toJson() => {
    'start': start,
    'end': end,
    'type': type.index,
    'fontSize': fontSize,
    'url': url,
  };

  static FormattingSpan fromJson(Map<String, dynamic> json) => FormattingSpan(
    start: json['start'],
    end: json['end'],
    type: FormattingType.values[json['type']],
    fontSize: (json['fontSize'] as num?)?.toDouble(),
    url: json['url'],
  );
}
