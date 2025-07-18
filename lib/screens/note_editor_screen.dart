import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'dart:io';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import '../models/note.dart';
import '../services/note_service.dart';
import '../widgets/note_editor_widgets.dart';
import '../widgets/formatted_text_editor.dart';
import 'dart:convert';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final List<String>? categories;

  const NoteEditorScreen({super.key, this.note, this.categories});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final NoteService _noteService = NoteService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _contentFocusNode = FocusNode();
  final ScrollController _toolbarScrollController = ScrollController();

  final GlobalKey<State<NoteContentEditor>> _contentEditorKey = GlobalKey();

  String? _selectedCategory;
  late Note _note;
  bool _isEditing = false;
  File? _selectedImage;
  late List<String> _categories;
  TextAlign _textAlignment = TextAlign.left;
  double _fontSize = 16;

  bool _modalBold = false;
  bool _modalItalic = false;
  bool _modalUnderline = false;
  bool _modalStrikethrough = false;

  List<String> _undoStack = [];
  List<String> _redoStack = [];
  bool _isUndoRedoAction = false;

  Timer? _autoSaveTimer;

  late List<FormattingSpan> _initialFormatting;

  @override
  void initState() {
    super.initState();
    _categories = widget.categories ?? ['Work', 'Reading', 'Important'];

    if (widget.note != null) {
      _note = widget.note!;
      _titleController.text = _note.title;
      _contentController.text = _note.content;
      _selectedCategory = _note.category;
      _isEditing = true;

      if (_note.imageUrl != null && _note.imageUrl!.isNotEmpty) {
        _selectedImage = File(_note.imageUrl!);
      }

      if (_note.formattingJson != null && _note.formattingJson!.isNotEmpty) {
        try {
          final List decoded = jsonDecode(_note.formattingJson!);
          _initialFormatting = decoded
              .map((e) => FormattingSpan.fromJson(e))
              .toList();
        } catch (_) {
          _initialFormatting = [];
        }
      } else {
        _initialFormatting = [];
      }
    } else {
      _note = Note(title: '', content: '');
      _initialFormatting = [];
    }

    _undoStack.add(_contentController.text);

    _contentController.addListener(_handleTextChange);
    _titleController.addListener(_handleTextChange);

    _setupAutoSave();
  }

  void _handleTextChange() {
    if (_isUndoRedoAction) return;

    _undoStack.add(_contentController.text);
    _redoStack.clear();

    if (_undoStack.length > 100) {
      _undoStack.removeAt(0);
    }

    _autoSave();
  }

  void _setupAutoSave() {}

  void _autoSave() {
    if (_note.title != _titleController.text ||
        _note.content != _contentController.text) {
      _note.title = _titleController.text;
      _note.content = _contentController.text;
      _note.updatedAt = DateTime.now();
      _note.category = _selectedCategory;

      if (_selectedImage != null) {
        _note.imageUrl = _selectedImage!.path;
      } else {
        _note.imageUrl = null;
      }

      final editor = _contentEditorKey.currentState as dynamic;
      if (editor != null) {
        final spans = editor.getFormattingSpans();
        _note.formattingJson = jsonEncode(
          spans.map((e) => e.toJson()).toList(),
        );
      }

      _noteService.saveNote(_note);
    }
  }

  void _undo() {
    if (_undoStack.length > 1) {
      _isUndoRedoAction = true;

      _redoStack.add(_undoStack.removeLast());

      _contentController.value = TextEditingValue(
        text: _undoStack.last,
        selection: TextSelection.collapsed(offset: _undoStack.last.length),
      );

      _isUndoRedoAction = false;
      HapticFeedback.mediumImpact();
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      _isUndoRedoAction = true;

      final redoText = _redoStack.removeLast();
      _undoStack.add(redoText);

      _contentController.value = TextEditingValue(
        text: redoText,
        selection: TextSelection.collapsed(offset: redoText.length),
      );

      _isUndoRedoAction = false;
      HapticFeedback.mediumImpact();
    }
  }

  Future<void> _saveNote() async {
    _note.title = _titleController.text;
    _note.content = _contentController.text;
    _note.updatedAt = DateTime.now();
    _note.category = _selectedCategory;

    if (_selectedImage != null) {
      _note.imageUrl = _selectedImage!.path;
    } else {
      _note.imageUrl = null;
    }

    final editor = _contentEditorKey.currentState as dynamic;
    if (editor != null) {
      final spans = editor.getFormattingSpans();
      _note.formattingJson = jsonEncode(spans.map((e) => e.toJson()).toList());
    }
    await _noteService.saveNote(_note);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _insertText(String text) {
    final currentText = _contentController.text;
    final selection = _contentController.selection;

    if (selection.baseOffset < 0) {
      _contentController.text = currentText + text;
      _contentController.selection = TextSelection.collapsed(
        offset: _contentController.text.length,
      );
      return;
    }

    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      text,
    );
    _contentController.text = newText;
    _contentController.selection = TextSelection.collapsed(
      offset: selection.start + text.length,
    );
  }

  void _applyFormatting({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strikethrough,
    double? fontSize,
  }) {
    final selection = _contentController.selection;
    if (!selection.isValid || selection.isCollapsed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select text first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final editor = _contentEditorKey.currentState as dynamic;
    if (editor == null) return;

    if (bold == true) {
      editor.applyFormatting(FormattingType.bold);
    } else if (bold == false) {
      editor.removeFormatting(FormattingType.bold);
    }

    if (italic == true) {
      editor.applyFormatting(FormattingType.italic);
    } else if (italic == false) {
      editor.removeFormatting(FormattingType.italic);
    }

    if (underline == true) {
      editor.applyFormatting(FormattingType.underline);
    } else if (underline == false) {
      editor.removeFormatting(FormattingType.underline);
    }

    if (strikethrough == true) {
      editor.applyFormatting(FormattingType.strikethrough);
    } else if (strikethrough == false) {
      editor.removeFormatting(FormattingType.strikethrough);
    }

    if (fontSize != null && fontSize != 16) {
      editor.applyFormatting(FormattingType.fontSize, fontSize: fontSize);
    }

    final selectedText = _contentController.text.substring(
      selection.start,
      selection.end,
    );
    final newText = _contentController.text.replaceRange(
      selection.start,
      selection.end,
      selectedText,
    );
    _contentController.text = newText;
    _contentController.selection = TextSelection.collapsed(
      offset: selection.start + selectedText.length,
    );

    HapticFeedback.lightImpact();
  }

  void _applyHighlight() {
    final selection = _contentController.selection;
    if (!selection.isValid || selection.isCollapsed) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select text first')));
      return;
    }

    final editor = _contentEditorKey.currentState as dynamic;
    if (editor != null) {
      editor.applyFormatting(FormattingType.highlight);
    }

    HapticFeedback.lightImpact();
  }

  void _setTextAlignment(TextAlign alignment) {
    setState(() {
      _textAlignment = alignment;
    });
    HapticFeedback.lightImpact();
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildEmojiPickerContent(context),
    );
  }

  Widget _buildEmojiPickerContent(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Emoji Picker',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: _emojis.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _insertText(_emojis[index]);
                    Navigator.pop(context);
                  },
                  child: Center(
                    child: Text(
                      _emojis[index],
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  final List<String> _emojis = [
    '😀',
    '😃',
    '😄',
    '😁',
    '😆',
    '😅',
    '🤣',
    '😂',
    '🙂',
    '🙃',
    '😉',
    '😊',
    '😇',
    '🥰',
    '😍',
    '🤩',
    '😘',
    '😗',
    '😚',
    '😙',
    '😋',
    '😛',
    '😜',
    '🤪',
    '😝',
    '🤑',
    '🤗',
    '🤭',
    '🤫',
    '🤔',
    '🤐',
    '🤨',
    '😐',
    '😑',
    '😶',
    '😏',
    '😒',
    '🙄',
    '😬',
    '🤥',
    '😌',
    '😔',
    '😪',
    '🤤',
    '😴',
    '😷',
    '🤒',
    '🤕',
    '🤢',
    '🤮',
    '🤧',
    '🥵',
    '🥶',
    '🥴',
    '😵',
    '🤯',
    '🤠',
    '🥳',
    '😎',
    '🤓',
    '👍',
    '👎',
    '❤️',
    '🔥',
    '✅',
    '⭐',
    '🎉',
    '🎂',
    '🚀',
    '💯',
  ];

  void _insertLink() {
    TextEditingController linkTextController = TextEditingController();
    TextEditingController linkUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Insert Link',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: linkTextController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Link Text',
                hintStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: linkUrlController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'URL (https://...)',
                hintStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final linkText = linkTextController.text.trim();
              final linkUrl = linkUrlController.text.trim();

              if (linkText.isNotEmpty && linkUrl.isNotEmpty) {
                final selection = _contentController.selection;
                final editor = _contentEditorKey.currentState as dynamic;
                if (editor != null &&
                    selection.isValid &&
                    !selection.isCollapsed) {
                  editor.applyFormatting(FormattingType.link, url: linkUrl);
                }
              }
              Navigator.pop(context);
            },
            child: const Text('Insert', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildAttachmentOptionsContent(context),
    );
  }

  Widget _buildAttachmentOptionsContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const PhosphorIcon(
              PhosphorIconsRegular.file,
              color: Colors.white,
            ),
            title: const Text(
              'Document',
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const PhosphorIcon(
              PhosphorIconsRegular.link,
              color: Colors.white,
            ),
            title: const Text('Link', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const PhosphorIcon(
              PhosphorIconsRegular.image,
              color: Colors.white,
            ),
            title: const Text('Image', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(context);
              await _pickImage();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to pick image')));
    }
  }

  void _showCategorySelector() {
    showDialog(
      context: context,
      builder: (context) => _buildCategorySelectorDialog(context),
    );
  }

  Widget _buildCategorySelectorDialog(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2C2C2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Select Category',
        style: TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : const Color(0xFF3C3C3E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showTextFormattingOptions() {
    final selection = _contentController.selection;

    _modalBold = false;
    _modalItalic = false;
    _modalUnderline = false;
    _modalStrikethrough = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C2C2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildTextFormattingModal(context),
    );
  }

  Widget _buildTextFormattingModal(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setModalState) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Text Formatting',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                const Text('Size:', style: TextStyle(color: Colors.white)),
                Expanded(
                  child: Slider(
                    value: _fontSize,
                    min: 12,
                    max: 28,
                    divisions: 8,
                    label: _fontSize.round().toString(),
                    onChanged: (value) {
                      setModalState(() {
                        _fontSize = value;
                      });
                      setState(() {
                        _fontSize = value;
                      });
                    },
                  ),
                ),
                Text(
                  _fontSize.round().toString(),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FormatToggleButton(
                  icon: PhosphorIconsRegular.textB,
                  label: 'Bold',
                  isSelected: _modalBold,
                  onTap: () {
                    setModalState(() {
                      _modalBold = !_modalBold;
                    });
                  },
                ),
                FormatToggleButton(
                  icon: PhosphorIconsRegular.textItalic,
                  label: 'Italic',
                  isSelected: _modalItalic,
                  onTap: () {
                    setModalState(() {
                      _modalItalic = !_modalItalic;
                    });
                  },
                ),
                FormatToggleButton(
                  icon: PhosphorIconsRegular.textUnderline,
                  label: 'Underline',
                  isSelected: _modalUnderline,
                  onTap: () {
                    setModalState(() {
                      _modalUnderline = !_modalUnderline;
                    });
                  },
                ),
                FormatToggleButton(
                  icon: PhosphorIconsRegular.textStrikethrough,
                  label: 'Strike',
                  isSelected: _modalStrikethrough,
                  onTap: () {
                    setModalState(() {
                      _modalStrikethrough = !_modalStrikethrough;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                Navigator.pop(context);
                _applyFormatting(
                  bold: _modalBold,
                  italic: _modalItalic,
                  underline: _modalUnderline,
                  strikethrough: _modalStrikethrough,
                  fontSize: _fontSize,
                );
              },
              child: const Text('Apply Formatting'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          CategorySelector(
            selectedCategory: _selectedCategory,
            showCategorySelector: _showCategorySelector,
          ),

          Expanded(child: _buildContentArea()),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FormattingToolbar(
        scrollController: _toolbarScrollController,
        textAlignment: _textAlignment,
        showTextFormattingOptions: _showTextFormattingOptions,
        showEmojiPicker: _showEmojiPicker,
        applyHighlight: _applyHighlight,
        insertLink: _insertLink,
        setTextAlignment: _setTextAlignment,
        insertText: _insertText,
        pickImage: _pickImage,
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1C1C1E),
      elevation: 0,
      leading: IconButton(
        icon: const PhosphorIcon(
          PhosphorIconsRegular.arrowLeft,
          color: Colors.white,
        ),
        onPressed: () {
          HapticFeedback.mediumImpact();

          Navigator.pop(context);
        },
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const PhosphorIcon(
              PhosphorIconsRegular.arrowClockwise,
              color: Colors.white,
            ),
            onPressed: _undo,
          ),
          IconButton(
            icon: const PhosphorIcon(
              PhosphorIconsRegular.arrowCounterClockwise,
              color: Colors.white,
            ),
            onPressed: _redo,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const PhosphorIcon(
            PhosphorIconsRegular.dotsThreeVertical,
            color: Colors.white,
          ),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildContentArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            focusNode: _titleFocusNode,
            decoration: const InputDecoration(
              hintText: 'Title',
              hintStyle: TextStyle(color: Colors.grey, fontSize: 28),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
            maxLines: null,
          ),
          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: _selectedImage != null
                        ? MediaQuery.of(context).size.height * 0.4
                        : MediaQuery.of(context).size.height * 0.65,
                    child: NoteContentEditor(
                      key: _contentEditorKey,
                      contentController: _contentController,
                      contentFocusNode: _contentFocusNode,
                      textAlignment: _textAlignment,
                      fontSize: _fontSize,
                      initialFormatting: _initialFormatting,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_selectedImage != null)
                    SelectedImageDisplay(
                      image: _selectedImage!,
                      onDelete: () {
                        setState(() {
                          _selectedImage = null;
                          _note.imageUrl = null;
                        });
                      },
                    ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _autoSave();

    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    _toolbarScrollController.dispose();
    super.dispose();
  }
}
