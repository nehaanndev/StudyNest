import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../models/study_models.dart';
import '../utils/date_labels.dart';
import '../widgets/cozy_widgets.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  static const _noteColors = ['honey', 'matcha', 'rose', 'ink'];

  // Builds the notes board and note creation controls.
  @override
  Widget build(BuildContext context) {
    final notes = StudyNestScope.watch(context).notes;

    return CozyPage(
      title: 'Notes',
      subtitle: 'Capture ideas, formulas, reminders, and tiny recaps.',
      action: IconButton.filled(
        tooltip: 'Add note',
        onPressed: () => _showNoteDialog(context),
        icon: const Icon(Icons.add),
      ),
      child: notes.isEmpty
          ? const EmptyState(
              icon: '📝',
              title: 'No notes yet',
              body: 'Save quick study thoughts before they disappear.',
            )
          : LayoutBuilder(
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
    );
  }

  // Opens the note creation dialog and saves a new note when valid.
  Future<void> _showNoteDialog(BuildContext context) async {
    final state = StudyNestScope.read(context);
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    var selectedColor = _noteColors.first;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('New note'),
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
                    await state.addNote(
                      title: title.isEmpty ? 'Untitled note' : title,
                      body: body,
                      colorName: selectedColor,
                    );
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
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
    final noteColor = _colorForNote(theme.surfaceAlt, note.colorName);

    return Material(
      color: noteColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onLongPress: () => state.deleteNote(note.id),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.primary.withValues(alpha: 0.22)),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete note',
                    onPressed: () => state.deleteNote(note.id),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              if (note.body.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(note.body, style: const TextStyle(height: 1.35)),
              ],
              const SizedBox(height: 14),
              Text(
                'Updated ${compactDate(note.updatedAt)}',
                style: TextStyle(color: theme.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Maps the selected note color name to a theme-aware card color.
  Color _colorForNote(Color fallback, String colorName) {
    return switch (colorName) {
      'honey' => const Color(0xFF5A3B24),
      'matcha' => const Color(0xFF344B36),
      'rose' => const Color(0xFF58343B),
      'ink' => const Color(0xFF273544),
      _ => fallback,
    };
  }
}
