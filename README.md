# Notes App - Project Documentation

A feature-rich Flutter notes application that allows users to create, edit, and delete notes with rich text formatting, image attachments, and categorization. Notes are stored locally on the device using SharedPreferences.

## Table of Contents
- [Project Overview](#project-overview)
- [Features](#features)
- [Project Structure](#project-structure)
- [Dependencies](#dependencies)
- [Implementation Details](#implementation-details)
  - [Data Model](#data-model)
  - [Data Persistence](#data-persistence)
  - [UI Components](#ui-components)
  - [Text Formatting](#text-formatting)
  - [State Management](#state-management)
- [Screens](#screens)
- [Widgets](#widgets)
- [Future Improvements](#future-improvements)

## Project Overview

The Notes App is a mobile application built with Flutter that provides users with a clean and intuitive interface for managing personal notes. The app focuses on providing a rich text editing experience with support for various formatting options, image attachments, and note categorization.

## Features

- **Note Management**:
  - Create new notes with title and content
  - Edit existing notes
  - Delete notes with swipe gesture or delete button
  - View list of all saved notes in grid or list view

- **Rich Text Formatting**:
  - Bold, italic, underline, and strikethrough text
  - Text highlighting
  - Font size adjustment
  - Text alignment (left, center, right)

- **Media Support**:
  - Add images to notes from gallery
  - View images in full screen with zoom capability

- **Organization**:
  - Categorize notes with custom categories
  - Filter notes by category
  - Search notes by title or content

- **User Experience**:
  - Dark mode UI with modern design
  - Haptic feedback for interactions
  - Smooth animations for transitions
  - Auto-save functionality
  - Undo/redo support for text editing

- **Data Management**:
  - Local storage using SharedPreferences
  - JSON serialization for data persistence

## Project Structure

The project follows a modular architecture with clear separation of concerns:

```
lib/
├── models/
│   └── note.dart              # Data model for notes
├── screens/
│   ├── image_preview_screen.dart  # Full-screen image viewer
│   ├── note_editor_screen.dart    # Note creation/editing screen
│   └── notes_list_screen.dart     # Main screen with notes list
├── services/
│   └── note_service.dart      # Data persistence service
├── widgets/
│   ├── formatted_text_editor.dart  # Rich text editor widget
│   └── note_editor_widgets.dart    # UI components for note editor
└── main.dart                  # App entry point
```

## Dependencies

The app uses the following external packages:

1. **phosphor_flutter (^2.0.1)**
   - Purpose: Modern and clean icon set
   - Usage: Used throughout the UI for icons in buttons and UI elements

2. **shared_preferences (^2.2.2)**
   - Purpose: Local data storage
   - Usage: Stores notes and categories as JSON strings

3. **intl (^0.19.0)**
   - Purpose: Internationalization and date formatting
   - Usage: Formats dates in note cards and timestamps

4. **uuid (^4.3.3)**
   - Purpose: Unique ID generation
   - Usage: Generates unique identifiers for each note

5. **flutter_staggered_grid_view (^0.7.0)**
   - Purpose: Custom grid layout
   - Usage: Creates the masonry-style grid view for notes

6. **image_picker (^1.1.2)**
   - Purpose: Access device gallery
   - Usage: Allows users to select images to attach to notes

## Implementation Details

### Data Model

The app uses a `Note` class (`models/note.dart`) to represent each note with the following properties:

- `id`: Unique identifier (UUID)
- `title`: Note title
- `content`: Note content (plain text)
- `createdAt`: Creation timestamp
- `updatedAt`: Last modification timestamp
- `category`: Optional category name
- `imageUrl`: Optional path to attached image
- `formattingJson`: JSON string storing text formatting information

The `Note` class includes methods for JSON serialization and deserialization to support data persistence.

### Data Persistence

The `NoteService` class (`services/note_service.dart`) handles all data persistence operations:

- **Storage Mechanism**: SharedPreferences is used to store notes and categories as JSON strings
- **Data Operations**:
  - `getNotes()`: Retrieves all saved notes
  - `saveNote()`: Creates or updates a note
  - `deleteNote()`: Removes a note
  - `getCategories()`: Retrieves all categories
  - `saveCategories()`: Updates the list of categories
  - `deleteCategory()`: Removes a category and updates associated notes

### UI Components

The app uses a custom dark theme with the following color scheme:
- Background: `Color(0xFF1C1C1E)` (dark gray)
- Surface elements: `Color(0xFF2C2C2E)` (slightly lighter gray)
- Input fields: `Color(0xFF3C3C3E)` (medium gray)
- Accent: `Colors.blue`
- Note cards: Pastel colors (cream, light yellow, light blue, light green, light pink, light purple)

### Text Formatting

The app implements a custom rich text editor (`widgets/formatted_text_editor.dart`) that supports:

1. **Formatting Types** (enum `FormattingType`):
   - Bold
   - Italic
   - Underline
   - Strikethrough
   - Highlight
   - Link
   - Font size

2. **Implementation Approach**:
   - The editor uses a stack with a transparent TextField for input
   - A RichText overlay displays the formatted text
   - Formatting is stored as `FormattingSpan` objects that track the start/end positions and formatting type
   - When text changes, the formatting spans are adjusted accordingly

3. **Formatting Storage**:
   - Formatting information is stored as JSON in the note's `formattingJson` field
   - Each span includes: start position, end position, formatting type, and optional parameters (fontSize, url)

### State Management

The app uses Flutter's built-in state management with `StatefulWidget` and `setState()`. Key state management features include:

1. **Auto-save**: Changes to notes are automatically saved when text changes
2. **Undo/Redo**: Text editing history is maintained in stacks for undo/redo functionality
3. **Filtering**: Notes are filtered based on search text and selected category
4. **Animation**: Animation controllers manage transitions and visual effects

## Screens

### 1. Notes List Screen (`screens/notes_list_screen.dart`)

The main screen of the app that displays all notes and provides filtering options.

**Key Components**:
- Search bar for filtering notes by title/content
- Category selector with horizontal scrolling
- Grid/List view toggle
- Floating action button to create new notes
- Note cards with preview of content
- Long-press gesture for note options (edit/delete)
- Animation for displaying note options

**Implementation Details**:
- Uses `MasonryGridView` for grid layout and `ListView` for list layout
- Implements custom animations for note selection
- Provides category management (add/delete categories)
- Implements search functionality across title and content

### 2. Note Editor Screen (`screens/note_editor_screen.dart`)

Screen for creating and editing notes with rich text formatting.

**Key Components**:
- Title input field
- Rich text content editor
- Formatting toolbar with text styling options
- Category selector
- Image attachment capability
- Undo/redo buttons

**Implementation Details**:
- Uses custom `FormattedTextEditor` for rich text editing
- Implements auto-save functionality
- Provides text formatting options through a bottom sheet
- Handles image selection and display
- Manages text history for undo/redo operations

### 3. Image Preview Screen (`screens/image_preview_screen.dart`)

Full-screen image viewer with zoom capability.

**Key Components**:
- Full-screen image display
- Zoom and pan gestures
- Close button
- Share option

**Implementation Details**:
- Uses `InteractiveViewer` for zoom and pan
- Implements hero animation for smooth transition
- Provides image sharing capability

## Widgets

### 1. Formatted Text Editor (`widgets/formatted_text_editor.dart`)

Custom rich text editor that supports various text formatting options.

**Key Components**:
- `FormattedTextEditor`: Main widget for rich text editing
- `FormattingSpan`: Class representing a formatting range
- `FormattingType`: Enum of supported formatting types

**Implementation Details**:
- Uses a stack with transparent TextField and RichText overlay
- Manages formatting spans to track formatting information
- Renders formatted text based on spans
- Handles text selection and formatting application

### 2. Note Editor Widgets (`widgets/note_editor_widgets.dart`)

Collection of UI components used in the note editor screen.

**Key Components**:
- `FormattingToolbar`: Bottom toolbar with formatting options
- `CategorySelector`: Widget for selecting note category
- `NoteContentEditor`: Wrapper for the formatted text editor
- `SelectedImageDisplay`: Widget for displaying attached images
- `FormatToggleButton`: Button for toggling formatting options

**Implementation Details**:
- Provides consistent styling across editor components
- Implements custom animations and interactions
- Handles user input and formatting actions

## Future Improvements

Potential enhancements for future versions:

### Core Features
1. **Cloud Synchronization**: Add support for syncing notes across devices
2. **Attachments**: Support for more attachment types (audio, documents, links)
3. **Export/Import**: Options to export notes in various formats (PDF, Markdown)
4. **Reminders**: Add reminder functionality to notes
5. **Encryption**: Add end-to-end encryption for sensitive notes
6. **Themes**: Support for custom themes and light mode
7. **Widgets**: Home screen widgets for quick note access
8. **Voice Notes**: Support for recording and transcribing voice notes
9. **Drawing**: Support for hand-drawn content in notes

### AI-Powered Features
10. **AI Note Summarizer**: Automatically generate concise summaries of lengthy notes
11. **AI Content Generator**: Assist users in generating content based on prompts or existing notes
12. **AI Image Generator**: Create custom images based on text descriptions within notes
13. **Smart Categorization**: Automatically suggest categories for notes based on content analysis
14. **Sentiment Analysis**: Analyze the emotional tone of notes and provide insights
15. **Voice-to-Text Transcription**: Enhanced voice note capabilities with AI transcription

### Collaboration Tools
16. **Real-time Collaboration**: Allow multiple users to edit notes simultaneously
17. **Comments and Annotations**: Add the ability to comment on specific parts of notes
18. **Version History**: Track changes and allow reverting to previous versions
19. **Flowchart and Diagram Tools**: FigJam-like functionality for creating visual diagrams
20. **Collaborative Whiteboards**: Shared canvas for brainstorming and visual collaboration
21. **Permission Management**: Granular control over who can view, edit, or comment on notes

## Getting Started

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the app
