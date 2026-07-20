part of 'notes_screen.dart';

// Builds the horizontal filter row for each supported study material type.
class _TypeFilterBar extends StatelessWidget {
  const _TypeFilterBar({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    final types = [
      'All',
      NoteType.note,
      NoteType.studyGuide,
      NoteType.flashcards,
      NoteType.quiz,
      NoteType.formula,
    ];

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
                color: isSelected
                    ? theme.primary.withValues(alpha: 0.18)
                    : theme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? theme.primary
                      : theme.primary.withValues(alpha: 0.18),
                ),
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

// Builds the horizontal filter row for tags found in the current notebook.
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.accent.withValues(alpha: 0.18)
                    : theme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? theme.accent
                      : theme.primary.withValues(alpha: 0.15),
                ),
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

// Builds the search field used to filter notes by title, body, or tags.
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
