import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter/services.dart';
import '../models/note.dart';
import '../services/note_service.dart';
import 'note_editor_screen.dart';
import 'image_preview_screen.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen>
    with SingleTickerProviderStateMixin {
  final NoteService _noteService = NoteService();
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  bool _isGridView = true;
  Note? _selectedNote;
  bool _showingOptions = false;

  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _blurAnimation;
  late Animation<double> _opacityAnimation;

  
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories().then((_) => _loadNotes());
    _searchController.addListener(_filterNotes);

    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _blurAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
    });

    final notes = await _noteService.getNotes();

    setState(() {
      _notes = notes;
      _filteredNotes = notes;
      _isLoading = false;
    });
    _filterNotes();
  }

  void _filterNotes() {
    setState(() {
      _filteredNotes = _notes.where((note) {
        final matchesSearch =
            note.title.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ) ||
            note.content.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            );

        final matchesCategory =
            _selectedCategory == 'All' ||
            (note.category?.toLowerCase() == _selectedCategory.toLowerCase());

        return matchesSearch && matchesCategory;
      }).toList()
        
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
  }

  Color _getNoteColor(int index) {
    final colors = [
      const Color(0xFFE8D5C4), 
      const Color(0xFFFFF2CC), 
      const Color(0xFFE1F5FE), 
      const Color(0xFFE8F5E8), 
      const Color(0xFFFCE4EC), 
      const Color(0xFFF3E5F5), 
    ];
    return colors[index % colors.length];
  }
  
  
  String _stripFormattingTags(String text) {
    
    text = text.replaceAll('**', '');
    
    
    text = text.replaceAll('_', '');
    
    
    text = text.replaceAll('<u>', '').replaceAll('</u>', '');
    
    
    text = text.replaceAll('~~', '');
    
    
    text = text.replaceAll('<highlight>', '').replaceAll('</highlight>', '');
    
    
    final sizeTagRegex = RegExp(r'<size=\d+\.\d+>|</size>');
    text = text.replaceAll(sizeTagRegex, '');
    
    return text;
  }

  Widget _buildNoteCard(Note note, int index, {bool isSelected = false}) {
    
    final formattedDate = DateFormat('MMM d, yyyy · h:mm a').format(note.updatedAt);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _getNoteColor(index),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isSelected ? 0.15 : 0.05),
            blurRadius: isSelected ? 15 : 10,
            spreadRadius: isSelected ? 2 : 0,
            offset: isSelected ? const Offset(0, 6) : const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note.imageUrl != null && note.imageUrl!.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImagePreviewScreen(image: File(note.imageUrl!)),
                  ),
                );
              },
              child: Hero(
                tag: note.imageUrl!,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(note.imageUrl!),
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
            ),
          if (note.imageUrl != null && note.imageUrl!.isNotEmpty)
            const SizedBox(height: 12),
          Text(
            note.title.isEmpty ? 'Untitled Note' : note.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            _stripFormattingTags(note.content),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.4,
            ),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              
              Expanded(
                child: Row(
                  children: [
                    PhosphorIcon(
                      PhosphorIconsRegular.clock,
                      color: Colors.black45,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              if (note.category != null && note.category!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    note.category!,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }



  void _editNote(Note note) async {
    
    _animationController.reverse().then((_) {
      setState(() {
        _showingOptions = false;
        _selectedNote = null;
      });
    });

    
    HapticFeedback.mediumImpact();

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteEditorScreen(
        note: note,
        categories: _categories.where((c) => c != 'All').toList(),
      )),
    );
    _loadNotes();
  }

  void _deleteNote(Note note) async {
    
    _animationController.reverse().then((_) {
      setState(() {
        _showingOptions = false;
        _selectedNote = null;
      });
    });

    
    HapticFeedback.heavyImpact();

    await _noteService.deleteNote(note.id);
    _loadNotes();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Note deleted'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  
  Future<void> _loadCategories() async {
    final categories = await _noteService.getCategories();
    setState(() {
      _categories = categories;
    });
  }
  
  
  Future<void> _saveCategories() async {
    await _noteService.saveCategories(_categories);
  }
  
  void _showAddCategoryDialog() {
    
    String newCategory = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Add Category',
          style: TextStyle(color: Colors.white),
        ),
        content: TextFormField(
          initialValue: '',
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            newCategory = value;
          },
          decoration: InputDecoration(
            hintText: 'Category name',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: const Color(0xFF3C3C3E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              final trimmedCategory = newCategory.trim();
              if (trimmedCategory.isNotEmpty &&
                  !_categories.contains(trimmedCategory)) {
                setState(() {
                  _categories.add(trimmedCategory);
                  _selectedCategory = trimmedCategory;
                });
                _saveCategories(); 
                _filterNotes();
                HapticFeedback.mediumImpact();
              }
              Navigator.pop(context);
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteCategoryDialog(String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Delete Category',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "$category"? Notes with this category will be uncategorized.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCategory(category);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  void _deleteCategory(String category) async {
    
    if (category == 'All') return;
    
    
    HapticFeedback.heavyImpact();
    
    
    setState(() {
      _categories.remove(category);
      if (_selectedCategory == category) {
        _selectedCategory = 'All';
      }
    });
    
    await _noteService.deleteCategory(category);
    _loadNotes();
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Category "$category" deleted'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF1C1C1E),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1C1C1E),
            elevation: 0,
            automaticallyImplyLeading: false,
            titleSpacing: 16,
            title: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search your notes',
                  hintStyle: TextStyle(color: Colors.grey),
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                  isDense: true,
                ),
              ),
            ),
            toolbarHeight: 70,
            actions: [
              IconButton(
                icon: PhosphorIcon(
                  _isGridView
                      ? PhosphorIconsRegular.rows
                      : PhosphorIconsRegular.squaresFour,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: Column(
            children: [
              
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    
                    GestureDetector(
                      onTap: () {
                        _showAddCategoryDialog();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3C3C3E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey[600]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            PhosphorIcon(
                              PhosphorIconsRegular.plus,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text('Add', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          final isSelected = _selectedCategory == category;
                          final noteCount = category == 'All'
                              ? _notes.length
                              : _notes
                                    .where(
                                      (note) =>
                                          note.category?.toLowerCase() ==
                                          category.toLowerCase(),
                                    )
                                    .length;

                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = category;
                                });
                                _filterNotes();
                              },
                              onLongPress: () {
                                
                                if (category != 'All' && !['Work', 'Reading', 'Important'].contains(category)) {
                                  HapticFeedback.mediumImpact();
                                  _showDeleteCategoryDialog(category);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: isSelected
                                      ? null
                                      : Border.all(color: Colors.grey[600]!),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      category,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.black
                                            : Colors.white,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 4),
                                      Text(
                                        '($noteCount)',
                                        style: const TextStyle(
                                          color: Colors.black54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredNotes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            PhosphorIcon(
                              PhosphorIconsRegular.notepad,
                              size: 64,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No notes found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the + button to create a note',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _isGridView
                            ? MasonryGridView.builder(
                                gridDelegate:
                                    const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                    ),
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                itemCount: _filteredNotes.length,
                                itemBuilder: (context, index) {
                                  final note = _filteredNotes[index];
                                  return GestureDetector(
                                    onTap: () async {
                                      if (_showingOptions) {
                                        setState(() {
                                          _showingOptions = false;
                                          _selectedNote = null;
                                        });
                                        return;
                                      }
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              NoteEditorScreen(
                                                note: note,
                                                categories: _categories.where((c) => c != 'All').toList(),
                                              ),
                                        ),
                                      );
                                      _loadNotes();
                                    },
                                    onLongPress: () {
                                      setState(() {
                                        _selectedNote = note;
                                        _showingOptions = true;
                                      });
                                      
                                      HapticFeedback.mediumImpact();
                                      
                                      _animationController.forward();
                                    },
                                    child: _buildNoteCard(note, index),
                                  );
                                },
                              )
                            : ListView.builder(
                                itemCount: _filteredNotes.length,
                                itemBuilder: (context, index) {
                                  final note = _filteredNotes[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: GestureDetector(
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                NoteEditorScreen(
                                                  note: note,
                                                  categories: _categories.where((c) => c != 'All').toList(),
                                                ),
                                          ),
                                        );
                                        _loadNotes();
                                      },
                                      onLongPress: () {
                                        setState(() {
                                          _selectedNote = note;
                                          _showingOptions = true;
                                        });
                                        
                                        HapticFeedback.mediumImpact();
                                        
                                        _animationController.forward();
                                      },
                                      child: _buildNoteCard(note, index),
                                    ),
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: Colors.white,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteEditorScreen(
                    categories: _categories.where((c) => c != 'All').toList(),
                  ),
                ),
              );
              _loadNotes();
            },
            child: const PhosphorIcon(
              PhosphorIconsRegular.plus,
              color: Colors.black,
              size: 24,
            ),
          ),
        ),
        if (_showingOptions && _selectedNote != null)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return GestureDetector(
                  onTap: () {
                    _animationController.reverse().then((_) {
                      setState(() {
                        _showingOptions = false;
                        _selectedNote = null;
                      });
                    });
                  },
                  child: Stack(
                    children: [
                      
                      BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: _blurAnimation.value,
                          sigmaY: _blurAnimation.value,
                        ),
                        child: Container(
                          color: Colors.black.withOpacity(
                            0.6 * _opacityAnimation.value,
                          ),
                        ),
                      ),
                      
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            
                            Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Container(
                                width: MediaQuery.of(context).size.width * 0.85,
                                margin: const EdgeInsets.only(bottom: 24),
                                child: _buildNoteCard(
                                  _selectedNote!,
                                  _filteredNotes.indexOf(_selectedNote!),
                                  isSelected: true,
                                ),
                              ),
                            ),
                            
                            Opacity(
                              opacity: _opacityAnimation.value,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(50),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(50),
                                        onTap: () => _editNote(_selectedNote!),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 16,
                                          ),
                                          child: Column(
                                            children: [
                                              const PhosphorIcon(
                                                PhosphorIconsRegular.pencil,
                                                color: Colors.black,
                                                size: 32,
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'Edit',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(50),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(50),
                                        onTap: () =>
                                            _deleteNote(_selectedNote!),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 16,
                                          ),
                                          child: Column(
                                            children: [
                                              const PhosphorIcon(
                                                PhosphorIconsRegular.trash,
                                                color: Colors.red,
                                                size: 32,
                                              ),
                                              const SizedBox(height: 8),
                                              const Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
