import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../app/study_nest_visuals.dart';
import '../models/study_models.dart';
import '../utils/date_labels.dart';
import '../widgets/cozy_widgets.dart';
import '../widgets/study_station_banner.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  // Creates notes screen state for tag and color filters.
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  static const _noteColors = ['honey', 'matcha', 'rose', 'ink'];
  String _selectedFilter = 'All';

  // Builds the notes board and note creation controls.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final notes = _filteredNotes(state.notes);
    final filters = _availableFilters(state.notes);

    return CozyPage(
      title: 'Notes',
      subtitle: 'Capture ideas, formulas, reminders, and tiny recaps.',
      action: IconButton.filled(
        tooltip: 'Add note',
        onPressed: () => _showNoteDialog(context),
        icon: const Icon(Icons.add),
      ),
      child: Column(
        children: [
          StudyStationBanner(
            title: 'My Notes',
            detail: 'Capture ideas, formulas, and study recaps.',
            metric: '${state.notes.length} notes',
            icon: Icons.note_alt,
            imagePath: screenBannerAsset('notes', state.selectedTheme.id),
            imageAlignment: Alignment.topCenter,
          ),
          const SizedBox(height: 14),
          _NoteFilterBar(
            filters: filters,
            selectedFilter: _selectedFilter,
            onSelected: (filter) => setState(() => _selectedFilter = filter),
          ),
          const SizedBox(height: 14),
          if (notes.isEmpty)
            const EmptyState(
              icon: '📝',
              title: 'No notes yet',
              body: 'Save quick study thoughts before they disappear.',
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final twoColumns = constraints.maxWidth > 520;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final note in notes)
                      SizedBox(
                        width: twoColumns
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth,
                        child: _NoteCard(note: note),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  // Returns notes matching the selected color or custom tag filter.
  List<StudyNote> _filteredNotes(List<StudyNote> notes) {
    if (_selectedFilter == 'All') {
      return notes;
    }
    return notes.where((note) {
      return note.colorName == _selectedFilter ||
          note.tags.contains(_selectedFilter);
    }).toList();
  }

  // Builds a stable list of available note filters from colors and tags.
  List<String> _availableFilters(List<StudyNote> notes) {
    final tags = notes.expand((note) => note.tags).toSet().toList()..sort();
    return ['All', ..._noteColors, ...tags];
  }

  // Opens the note creation or edit dialog and saves valid changes.
  Future<void> _showNoteDialog(BuildContext context, {StudyNote? note}) async {
    final state = StudyNestScope.read(context);
    final titleController = TextEditingController(text: note?.title ?? '');
    final bodyController = TextEditingController(text: note?.body ?? '');
    final tagsController = TextEditingController(
      text: note == null ? '' : note.tags.join(', '),
    );
    var selectedColor = note?.colorName ?? _noteColors.first;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(note == null ? 'New note' : 'Edit note'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bodyController,
                      maxLines: 5,
                      decoration: const InputDecoration(labelText: 'Note'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags',
                        hintText: 'exam, formulas, reading',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final colorName in _noteColors)
                          ChoiceChip(
                            label: Text(colorName),
                            selected: selectedColor == colorName,
                            onSelected: (_) {
                              setDialogState(() => selectedColor = colorName);
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    final body = bodyController.text.trim();
                    if (title.isEmpty && body.isEmpty) {
                      return;
                    }
                    final tags = _parseTags(tagsController.text);
                    final result = note == null
                        ? await state.addNote(
                            title: title.isEmpty ? 'Untitled note' : title,
                            body: body,
                            colorName: selectedColor,
                            tags: tags,
                          )
                        : null;
                    if (note != null) {
                      await state.updateNote(
                        noteId: note.id,
                        title: title.isEmpty ? 'Untitled note' : title,
                        body: body,
                        colorName: selectedColor,
                        tags: tags,
                      );
                    }
                    if (!dialogContext.mounted) {
                      return;
                    }
                    final message = result?.message ?? 'Note updated.';
                    ScaffoldMessenger.of(
                      dialogContext,
                    ).showSnackBar(SnackBar(content: Text(message)));
                    if (result != null && !result.applied) {
                      return;
                    }
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: Text(note == null ? 'Save' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Parses comma-separated custom tags into lowercase unique labels.
  List<String> _parseTags(String source) {
    final tags =
        source
            .split(',')
            .map((tag) => tag.trim().toLowerCase())
            .where((tag) => tag.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return tags;
  }
}

class _NoteFilterBar extends StatelessWidget {
  const _NoteFilterBar({
    required this.filters,
    required this.selectedFilter,
    required this.onSelected,
  });

  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onSelected;

  // Builds horizontal note filters for colors and custom tags.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in filters) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(filter),
                selected: selectedFilter == filter,
                onSelected: (_) => onSelected(filter),
                selectedColor: theme.accent.withValues(alpha: 0.18),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final StudyNote note;

  // Builds an individual sticky-note style card.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final theme = state.selectedTheme;
    final noteColor = _colorForNote(theme.surfaceAlt, note.colorName, theme.isDark);

    final textColor = theme.isDark ? theme.text : const Color(0xFF1A110A);
    final mutedColor = theme.isDark ? theme.muted : const Color(0xFF6B5040);

    return Material(
      color: noteColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          context.findAncestorStateOfType<_NotesScreenState>()?._showNoteDialog(
            context,
            note: note,
          );
        },
        onLongPress: () => state.deleteNote(note.id),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.isDark
                  ? theme.accent.withValues(alpha: 0.25)
                  : theme.primary.withValues(alpha: 0.18),
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
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete note',
                    onPressed: () => state.deleteNote(note.id),
                    icon: Icon(Icons.close, color: mutedColor, size: 18),
                  ),
                ],
              ),
              if (note.body.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  note.body,
                  style: TextStyle(height: 1.35, color: textColor),
                ),
              ],
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tag in note.tags)
                      CozyTag(label: tag, icon: Icons.sell_outlined),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Text(
                'Updated ${compactDate(note.updatedAt)}',
                style: TextStyle(color: mutedColor, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Maps the selected note color name to a theme-aware card color.
  Color _colorForNote(Color fallback, String colorName, bool isDark) {
    // Use darker tones when in dark theme so text stays readable.
    if (isDark) {
      return switch (colorName) {
        'honey' => const Color(0xFF2A1F08),
        'matcha' => const Color(0xFF141F10),
        'rose'   => const Color(0xFF221018),
        'ink'    => const Color(0xFF0E1825),
        _        => fallback,
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
