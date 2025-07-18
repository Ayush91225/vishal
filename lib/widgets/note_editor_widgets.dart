import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../screens/image_preview_screen.dart';
import 'formatted_text_editor.dart';


class FormattingToolbar extends StatelessWidget {
  final ScrollController scrollController;
  final TextAlign textAlignment;
  final VoidCallback showTextFormattingOptions;
  final VoidCallback showEmojiPicker;
  final VoidCallback applyHighlight;
  final VoidCallback insertLink;
  final Function(TextAlign) setTextAlignment;
  final Function(String) insertText;
  final VoidCallback? pickImage;

  const FormattingToolbar({
    super.key,
    required this.scrollController,
    required this.textAlignment,
    required this.showTextFormattingOptions,
    required this.showEmojiPicker,
    required this.applyHighlight,
    required this.insertLink,
    required this.setTextAlignment,
    required this.insertText,
    this.pickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const PhosphorIcon(
                PhosphorIconsRegular.textT,
                color: Colors.white,
              ),
              onPressed: showTextFormattingOptions,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const PhosphorIcon(
                PhosphorIconsRegular.checkSquare,
                color: Colors.white,
              ),
              onPressed: () {
                insertText('\u2610 ');
                HapticFeedback.lightImpact();
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const PhosphorIcon(
                PhosphorIconsRegular.list,
                color: Colors.white,
              ),
              onPressed: () {
                insertText('• ');
                HapticFeedback.lightImpact();
              },
            ),

            const SizedBox(width: 8),
            IconButton(
              icon: const PhosphorIcon(
                PhosphorIconsRegular.smiley,
                color: Colors.white,
              ),
              onPressed: showEmojiPicker,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const PhosphorIcon(
                PhosphorIconsRegular.highlighterCircle,
                color: Colors.white,
              ),
              onPressed: applyHighlight,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const PhosphorIcon(
                PhosphorIconsRegular.link,
                color: Colors.white,
              ),
              onPressed: insertLink,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: PhosphorIcon(
                PhosphorIconsRegular.textAlignLeft,
                color: textAlignment == TextAlign.left
                    ? Colors.blue
                    : Colors.white,
              ),
              onPressed: () => setTextAlignment(TextAlign.left),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: PhosphorIcon(
                PhosphorIconsRegular.textAlignCenter,
                color: textAlignment == TextAlign.center
                    ? Colors.blue
                    : Colors.white,
              ),
              onPressed: () => setTextAlignment(TextAlign.center),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: PhosphorIcon(
                PhosphorIconsRegular.textAlignRight,
                color: textAlignment == TextAlign.right
                    ? Colors.blue
                    : Colors.white,
              ),
              onPressed: () => setTextAlignment(TextAlign.right),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const PhosphorIcon(
                PhosphorIconsRegular.image,
                color: Colors.white,
              ),
              onPressed: pickImage,
            ),
          ],
        ),
      ),
    );
  }
}


class CategorySelector extends StatelessWidget {
  final String? selectedCategory;
  final VoidCallback showCategorySelector;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.showCategorySelector,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
        child: GestureDetector(
          onTap: showCategorySelector,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF3C3C3E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PhosphorIcon(
                  PhosphorIconsRegular.tag,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  selectedCategory ?? 'Select category',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(width: 4),
                const PhosphorIcon(
                  PhosphorIconsRegular.caretDown,
                  color: Colors.grey,
                  size: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class NoteContentEditor extends StatefulWidget {
  final TextEditingController contentController;
  final FocusNode contentFocusNode;
  final TextAlign textAlignment;
  final double fontSize;
  final List<FormattingSpan>? initialFormatting;

  const NoteContentEditor({
    super.key,
    required this.contentController,
    required this.contentFocusNode,
    required this.textAlignment,
    required this.fontSize,
    this.initialFormatting,
  });

  @override
  State<NoteContentEditor> createState() => _NoteContentEditorState();
}

class _NoteContentEditorState extends State<NoteContentEditor> {
  
  final GlobalKey<State<FormattedTextEditor>> _editorKey = GlobalKey();

  
  void applyFormatting(FormattingType type, {double? fontSize, String? url}) {
    final state = _editorKey.currentState as dynamic;
    state?.addFormatting(type, fontSize: fontSize, url: url);
  }

  
  void removeFormatting(FormattingType type) {
    final state = _editorKey.currentState as dynamic;
    state?.removeFormatting(type);
  }

  @override
  Widget build(BuildContext context) {
    return FormattedTextEditor(
      key: _editorKey,
      controller: widget.contentController,
      focusNode: widget.contentFocusNode,
      textAlign: widget.textAlignment,
      fontSize: widget.fontSize,
      onChanged: (text) {
        
      },
      initialFormatting: widget.initialFormatting,
    );
  }

  List<FormattingSpan> getFormattingSpans() {
    final state = _editorKey.currentState as dynamic;
    return state?.getFormattingSpans() ?? [];
  }

  void setFormattingSpans(List<FormattingSpan> spans) {
    final state = _editorKey.currentState as dynamic;
    state?.setFormattingSpans(spans);
  }
}


class SelectedImageDisplay extends StatelessWidget {
  final File image;
  final VoidCallback onDelete;

  const SelectedImageDisplay({
    super.key,
    required this.image,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFF2C2C2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImagePreviewScreen(image: image),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Hero(
                tag: image.path,
                child: Image.file(
                  image,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const PhosphorIcon(
                  PhosphorIconsRegular.x,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ImagePreviewScreen(image: image),
                        ),
                      );
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: PhosphorIcon(
                        PhosphorIconsRegular.magnifyingGlassPlus,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: PhosphorIcon(
                        PhosphorIconsRegular.trash,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class FormatToggleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FormatToggleButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : const Color(0xFF3C3C3E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            PhosphorIcon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
