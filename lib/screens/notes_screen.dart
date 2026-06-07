import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../app/study_nest_visuals.dart';
import '../models/study_models.dart';
import '../utils/date_labels.dart';
import '../widgets/cozy_widgets.dart';
import '../widgets/study_station_banner.dart';
import 'note_editor_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String _selectedTag = 'All';
  String _selectedFolder = 'All';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Builds the notes list with search, folder tabs, and filter chips.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final allNotes = state.notes;
    final notes = _filteredNotes(allNotes);
    final tagFilters = _buildTagFilters(allNotes);
    final folders = _buildFolders(allNotes);

    return CozyPage(
      title: 'Notes',
      subtitle: 'Capture ideas, formulas, reminders, and tiny recaps.',
      action: IconButton.filled(
        tooltip: 'Add note',
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudyStationBanner(
            title: 'My Notes',
            detail: 'Capture ideas, formulas, and study recaps.',
            metric: '${allNotes.length} notes',
            icon: Icons.note_alt,
            imagePath: screenBannerAsset('notes', state.selectedTheme.id),
            imageAlignment: Alignment.topCenter,
          ),
          const SizedBox(height: 14),
          // Search bar
          _SearchBar(
            controller: _searchCtrl,
            onChanged: (q) => setState(() => _searchQuery = q),
          ),
          const SizedBox(height: 10),
          // Folder filter row
          if (folders.length > 1)
            _FolderBar(
              folders: folders,
              selected: _selectedFolder,
              onSelected: (f) => setState(() => _selectedFolder = f),
            ),
          if (folders.length > 1) const SizedBox(height: 10),
          // Tag filter chips
          _TagFilterBar(
            tags: tagFilters,
            selected: _selectedTag,
            onSelected: (t) => setState(() => _selectedTag = t),
          ),
          const SizedBox(height: 14),
          if (notes.isEmpty)
            const EmptyState(
              icon: '📝',
              title: 'No notes yet',
              body: 'Tap + to save quick study thoughts.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final twoCol = constraints.maxWidth > 520;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final note in notes)
                      SizedBox(
                        width: twoCol
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth,
                        child: _NoteCard(
                          note: note,
                          onTap: () => _openEditor(context, note: note),
                          onDelete: () => state.deleteNote(note.id),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // Opens the full-screen note editor for creating or editing a note.
  void _openEditor(BuildContext context, {StudyNote? note}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
    );
  }

  // Returns notes filtered by search query, folder, and tag.
  List<StudyNote> _filteredNotes(List<StudyNote> notes) {
    return notes.where((note) {
      final matchesTag = _selectedTag == 'All' || note.tags.contains(_selectedTag);
      final matchesFolder = _selectedFolder == 'All' || note.folder == _selectedFolder;
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          note.title.toLowerCase().contains(q) ||
          note.body.toLowerCase().contains(q) ||
          note.tags.any((t) => t.contains(q));
      return matchesTag && matchesFolder && matchesSearch;
    }).toList();
  }

  // Builds a deduplicated sorted list of all tags across notes.
  List<String> _buildTagFilters(List<StudyNote> notes) {
    final tags = notes.expand((n) => n.tags).toSet().toList()..sort();
    return ['All', ...tags];
  }

  // Builds a deduplicated list of all non-empty folders.
  List<String> _buildFolders(List<StudyNote> notes) {
    final folders = notes
        .map((n) => n.folder)
        .where((f) => f.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...folders];
  }
}

// Search bar widget for filtering notes by text.
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: theme.text, decoration: TextDecoration.none),
      decoration: InputDecoration(
        hintText: 'Search notes…',
        prefixIcon: Icon(Icons.search, color: theme.muted, size: 20),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: theme.muted, size: 18),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              )
            : null,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}

// Horizontal folder selector shown as pill tabs.
class _FolderBar extends StatelessWidget {
  const _FolderBar({
    required this.folders,
    required this.selected,
    required this.onSelected,
  });
  final List<String> folders;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: folders.map((folder) {
          final isSelected = folder == selected;
          return GestureDetector(
            onTap: () => onSelected(folder),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.primary.withValues(alpha: 0.18)
                    : theme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? theme.primary
                      : theme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (folder != 'All')
                    Icon(Icons.folder_outlined, size: 13, color: isSelected ? theme.primary : theme.muted),
                  if (folder != 'All') const SizedBox(width: 4),
                  Text(
                    folder,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? theme.primary : theme.muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Horizontally scrollable tag filter chips — uses GestureDetector instead of
// ChoiceChip to avoid needing a Material ancestor.
class _TagFilterBar extends StatelessWidget {
  const _TagFilterBar({
    required this.tags,
    required this.selected,
    required this.onSelected,
  });
  final List<String> tags;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tags.map((tag) {
          final isSelected = tag == selected;
          return GestureDetector(
            onTap: () => onSelected(tag),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.accent.withValues(alpha: 0.20)
                    : theme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? theme.accent
                      : theme.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? theme.accent : theme.muted,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Individual note card showing title, preview, tags, and date.
class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });
  final StudyNote note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    final cardColor = _colorForNote(theme.surfaceAlt, note.colorName, theme.isDark);
    final textColor = theme.isDark ? theme.text : const Color(0xFF1A110A);
    final mutedColor = theme.isDark ? theme.muted : const Color(0xFF6B5040);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.isDark
                  ? theme.accent.withValues(alpha: 0.22)
                  : theme.primary.withValues(alpha: 0.16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: textColor,
                        decoration: TextDecoration.none,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onDelete,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.close, color: mutedColor, size: 16),
                    ),
                  ),
                ],
              ),
              if (note.body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  note.body,
                  style: TextStyle(
                    height: 1.4,
                    fontSize: 13,
                    color: textColor.withValues(alpha: 0.8),
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: note.tags
                      .take(3)
                      .map((tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: theme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: theme.primary,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  if (note.folder.isNotEmpty) ...[
                    Icon(Icons.folder_outlined, size: 11, color: mutedColor),
                    const SizedBox(width: 3),
                    Text(
                      note.folder,
                      style: TextStyle(fontSize: 11, color: mutedColor, decoration: TextDecoration.none),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    compactDate(note.updatedAt),
                    style: TextStyle(fontSize: 11, color: mutedColor, decoration: TextDecoration.none),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Maps a color name to its card background color for the current theme mode.
  Color _colorForNote(Color fallback, String colorName, bool isDark) {
    if (isDark) {
      return switch (colorName) {
        'honey' => const Color(0xFF2A1F08),
        'matcha' => const Color(0xFF141F10),
        'rose' => const Color(0xFF221018),
        'ink' => const Color(0xFF0E1825),
        _ => fallback,
      };
    }
    return switch (colorName) {
      'honey' => const Color(0xFFFFF0CC),
      'matcha' => const Color(0xFFE6EBCB),
      'rose' => const Color(0xFFF3D4CD),
      'ink' => const Color(0xFFDDE7ED),
      _ => fallback,
    };
  }
}
