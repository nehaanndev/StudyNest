import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../app/study_nest_visuals.dart';
import '../models/study_content_models.dart';
import '../models/study_models.dart';
import '../utils/date_labels.dart';
import '../widgets/cozy_widgets.dart';
import '../widgets/study_station_banner.dart';
import 'flashcard_screen.dart';
import 'formula_sheet_screen.dart';
import 'note_editor_screen.dart';
import 'quiz_screen.dart';
import 'study_guide_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  // Active type filter: 'All' or any NoteType constant.
  String _typeFilter = 'All';
  // Active tag filter.
  String _tagFilter = 'All';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Builds the full notes layout with banner, search, filters, and cards.
  @override
  Widget build(BuildContext context) {
    final state = StudyNestScope.watch(context);
    final allNotes = state.notes;
    final notes = _filteredNotes(allNotes);
    final tagFilters = _buildTagFilters(allNotes);

    return CozyPage(
      title: 'Notes',
      subtitle: 'Notes, guides, flashcards, quizzes, and formulas.',
      action: _CreateButton(onCreated: () => setState(() {})),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudyStationBanner(
            title: 'Study Notes',
            detail: 'All your study materials in one place.',
            metric: '${allNotes.length} item${allNotes.length == 1 ? '' : 's'}',
            icon: Icons.menu_book_outlined,
            imagePath: screenBannerAsset('notes', state.selectedTheme.id),
            imageAlignment: Alignment.topCenter,
          ),
          const SizedBox(height: 14),
          _SearchBar(
            controller: _searchCtrl,
            onChanged: (q) => setState(() => _searchQuery = q),
          ),
          const SizedBox(height: 10),
          // Type filter chips
          _TypeFilterBar(
            selected: _typeFilter,
            onSelected: (t) => setState(() => _typeFilter = t),
          ),
          // Tag filter chips (only shown when there are tags)
          if (tagFilters.length > 1) ...[
            const SizedBox(height: 8),
            _TagFilterBar(
              tags: tagFilters,
              selected: _tagFilter,
              onSelected: (t) => setState(() => _tagFilter = t),
            ),
          ],
          const SizedBox(height: 14),
          if (notes.isEmpty)
            const EmptyState(
              icon: '📚',
              title: 'Nothing here yet',
              body: 'Tap + to create a note, guide, flashcards, quiz, or formula sheet.',
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
                          onTap: () => _openItem(context, note),
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

  // Routes to the correct editor for the note's type.
  void _openItem(BuildContext context, StudyNote note) {
    final route = switch (note.noteType) {
      NoteType.studyGuide => MaterialPageRoute(builder: (_) => StudyGuideScreen(note: note)),
      NoteType.flashcards => MaterialPageRoute(builder: (_) => FlashcardScreen(note: note)),
      NoteType.quiz => MaterialPageRoute(builder: (_) => QuizScreen(note: note)),
      NoteType.formula => MaterialPageRoute(builder: (_) => FormulaSheetScreen(note: note)),
      _ => MaterialPageRoute(builder: (_) => NoteEditorScreen(note: note)),
    };
    Navigator.of(context).push(route);
  }

  // Applies all active filters to the note list.
  List<StudyNote> _filteredNotes(List<StudyNote> notes) {
    return notes.where((note) {
      final matchesType = _typeFilter == 'All' || note.noteType == _typeFilter;
      final matchesTag = _tagFilter == 'All' || note.tags.contains(_tagFilter);
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          note.title.toLowerCase().contains(q) ||
          note.body.toLowerCase().contains(q) ||
          note.tags.any((t) => t.contains(q));
      return matchesType && matchesTag && matchesSearch;
    }).toList();
  }

  // Builds deduplicated sorted tag filter list from all notes.
  List<String> _buildTagFilters(List<StudyNote> notes) {
    final tags = notes.expand((n) => n.tags).toSet().toList()..sort();
    return ['All', ...tags];
  }
}

// Floating "+" button that shows a creation menu bottom sheet.
class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onCreated});
  final VoidCallback onCreated;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: 'Create',
      icon: const Icon(Icons.add),
      onPressed: () => _showMenu(context),
    );
  }

  // Presents a bottom sheet with all creation options.
  void _showMenu(BuildContext context) {
    final theme = StudyNestScope.read(context).selectedTheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: theme.primary.withValues(alpha: 0.15)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: theme.muted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text('Create', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: theme.text)),
            const SizedBox(height: 16),
            _CreateOption(
              emoji: '📝', label: 'New Note', subtitle: 'Plain text with formatting',
              onTap: () { Navigator.of(context).pop(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NoteEditorScreen())); },
            ),
            _CreateOption(
              emoji: '📖', label: 'New Study Guide', subtitle: 'Sections, bullets, key terms',
              onTap: () { Navigator.of(context).pop(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudyGuideScreen())); },
            ),
            _CreateOption(
              emoji: '🃏', label: 'New Flashcard Set', subtitle: 'Front/back cards with review mode',
              onTap: () { Navigator.of(context).pop(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FlashcardScreen())); },
            ),
            _CreateOption(
              emoji: '❓', label: 'New Quiz', subtitle: 'Multiple choice with scoring',
              onTap: () { Navigator.of(context).pop(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const QuizScreen())); },
            ),
            _CreateOption(
              emoji: '🔢', label: 'New Formula Sheet', subtitle: 'Formulas with explanations',
              onTap: () { Navigator.of(context).pop(); Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FormulaSheetScreen())); },
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

// A single row in the creation menu.
class _CreateOption extends StatelessWidget {
  const _CreateOption({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  final String emoji;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    return Column(
      children: [
        ListTile(
          leading: Text(emoji, style: const TextStyle(fontSize: 26)),
          title: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: theme.text)),
          subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: theme.muted)),
          trailing: Icon(Icons.arrow_forward_ios, size: 14, color: theme.muted),
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        if (!isLast) Divider(color: theme.primary.withValues(alpha: 0.08), height: 1),
      ],
    );
  }
}

// Horizontal type-filter chip row (All, Note, Study Guide, Flashcards, Quiz, Formulas).
class _TypeFilterBar extends StatelessWidget {
  const _TypeFilterBar({required this.selected, required this.onSelected});
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    final types = ['All', NoteType.note, NoteType.studyGuide, NoteType.flashcards, NoteType.quiz, NoteType.formula];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: types.map((type) {
          final isSelected = type == selected;
          final label = type == 'All' ? 'All' : NoteType.label(type);
          final emoji = type == 'All' ? '' : '${NoteType.emoji(type)} ';
          return GestureDetector(
            onTap: () => onSelected(type),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? theme.primary.withValues(alpha: 0.18) : theme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? theme.primary : theme.primary.withValues(alpha: 0.18)),
              ),
              child: Text(
                '$emoji$label',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? theme.primary : theme.muted,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Horizontal tag-filter chip row.
class _TagFilterBar extends StatelessWidget {
  const _TagFilterBar({required this.tags, required this.selected, required this.onSelected});
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? theme.accent.withValues(alpha: 0.18) : theme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? theme.accent : theme.primary.withValues(alpha: 0.15)),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  fontSize: 11,
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

// Search bar widget for filtering notes by title or body text.
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
                onPressed: () { controller.clear(); onChanged(''); },
              )
            : null,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}

// Card widget for displaying a note/study item in the grid.
class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.onTap, required this.onDelete});
  final StudyNote note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    final cardColor = _colorForNote(theme.surfaceAlt, note.colorName, theme.isDark);
    final textColor = theme.isDark ? theme.text : const Color(0xFF1A110A);
    final mutedColor = theme.isDark ? theme.muted : const Color(0xFF6B5040);
    final isStructured = note.noteType != NoteType.note;

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
                  // Type icon badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      NoteType.emoji(note.noteType),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      note.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
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
                      child: Icon(Icons.close, color: mutedColor, size: 15),
                    ),
                  ),
                ],
              ),
              if (!isStructured && note.body.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  note.body,
                  style: TextStyle(height: 1.4, fontSize: 13, color: textColor.withValues(alpha: 0.8), decoration: TextDecoration.none),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (isStructured) ...[
                const SizedBox(height: 6),
                Text(
                  NoteType.label(note.noteType),
                  style: TextStyle(fontSize: 12, color: theme.primary, fontWeight: FontWeight.w600, decoration: TextDecoration.none),
                ),
              ],
              if (note.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: note.tags.take(3).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: theme.primary, decoration: TextDecoration.none)),
                  )).toList(),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                compactDate(note.updatedAt),
                style: TextStyle(fontSize: 10, color: mutedColor, decoration: TextDecoration.none),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Maps a note color name to its background color for the current theme mode.
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
