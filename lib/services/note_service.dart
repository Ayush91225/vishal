import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';

class NoteService {
  static const String _notesKey = 'notes';
  static const String _categoriesKey = 'categories';

  
  Future<List<Note>> getNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesJson = prefs.getStringList(_notesKey) ?? [];
    
    return notesJson
        .map((noteJson) => Note.fromJson(jsonDecode(noteJson)))
        .toList();
  }

  
  Future<void> saveNote(Note note) async {
    final prefs = await SharedPreferences.getInstance();
    final notes = await getNotes();
    
    final existingIndex = notes.indexWhere((n) => n.id == note.id);
    if (existingIndex >= 0) {
      notes[existingIndex] = note;
    } else {
      notes.add(note);
    }
    
    final notesJson = notes
        .map((note) => jsonEncode(note.toJson()))
        .toList();
    
    await prefs.setStringList(_notesKey, notesJson);
  }

  
  Future<void> deleteNote(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final notes = await getNotes();
    
    notes.removeWhere((note) => note.id == id);
    
    final notesJson = notes
        .map((note) => jsonEncode(note.toJson()))
        .toList();
    
    await prefs.setStringList(_notesKey, notesJson);
  }
  
  
  Future<List<String>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultCategories = ['All', 'Work', 'Reading', 'Important'];
    return prefs.getStringList(_categoriesKey) ?? defaultCategories;
  }
  
  
  Future<void> saveCategories(List<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_categoriesKey, categories);
  }
  
  
  Future<void> deleteCategory(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final categories = await getCategories();
    
    
    if (category == 'All') return;
    
    categories.remove(category);
    await prefs.setStringList(_categoriesKey, categories);
    
    
    final notes = await getNotes();
    bool hasChanges = false;
    
    for (var note in notes) {
      if (note.category == category) {
        note.category = null;
        hasChanges = true;
      }
    }
    
    if (hasChanges) {
      final notesJson = notes
          .map((note) => jsonEncode(note.toJson()))
          .toList();
      
      await prefs.setStringList(_notesKey, notesJson);
    }
  }
}