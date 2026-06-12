import 'dart:async';

import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../models/study_content_models.dart';
import '../models/study_models.dart';

// Full-screen editor for Study Guide notes.
class StudyGuideScreen extends StatefulWidget {
  const StudyGuideScreen({super.key, this.note});

  // Existing note to edit, or null to create a new one.
  final StudyNote? note;

  @override
  State<StudyGuideScreen> createState() => _StudyGuideScreenState();
}

class _StudyGuideScreenState extends State<StudyGuideScreen> {
  late final TextEditingController _titleCtrl;
  late List<StudyGuideSection> _sections;
  late List<String> _tags;
  Timer? _saveTimer;
  bool _saved = false;
  String? _noteId;

  @override
  void initState() {
    super.initState();
    _noteId = widget.note?.id;
    _titleCtrl = TextEditingController(text: widget.note?.title ?? '');
    _tags = List.from(widget.note?.tags ?? []);

    final json = widget.note?.contentJson;
    if (json != null) {
      _sections = StudyGuideContent.fromJson(json).sections.toList();
    } else {
      _sections = [StudyGuideSection.blank()];
    }

    _titleCtrl.addListener(_scheduleAutoSave);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _titleCtrl.removeListener(_scheduleAutoSave);
    _titleCtrl.dispose();
    super.dispose();
  }

  // Debounces saves so writes happen 2 seconds after the last change.
  void _scheduleAutoSave() {
    setState(() => _saved = false);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), _save);
  }

  // Persists the study guide to app state.
  Future<void> _save() async {
    final state = StudyNestScope.read(context);
    final title = _titleCtrl.text.trim();
    if (title.isEmpty &&
        _sections.every((s) => s.title.isEmpty && s.notes.isEmpty)) {
      return;
    }

    final content = StudyGuideContent(sections: _sections).toJson();

    if (_noteId == null) {
      final result = await state.addNote(
        title: title.isEmpty ? 'Study Guide' : title,
        body: '',
        colorName: 'matcha',
        tags: _tags,
        noteType: NoteType.studyGuide,
        contentJson: content,
      );
      if (result.applied && mounted) {
        final created = state.notes.firstWhere(
          (n) => n.noteType == NoteType.studyGuide && n.contentJson == content,
          orElse: () => state.notes.first,
        );
        _noteId = created.id;
      }
    } else {
      await state.updateNote(
        noteId: _noteId!,
        title: title.isEmpty ? 'Study Guide' : title,
        body: '',
        colorName: 'matcha',
        tags: _tags,
        contentJson: content,
      );
    }
    if (mounted) setState(() => _saved = true);
  }

  // Adds a blank section to the guide.
  void _addSection() {
    setState(() => _sections.add(StudyGuideSection.blank()));
    _scheduleAutoSave();
  }

  // Removes a section by index.
  void _removeSection(int index) {
    setState(() => _sections.removeAt(index));
    _scheduleAutoSave();
  }

  // Updates the title of a section at the given index.
  void _updateSectionTitle(int index, String value) {
    _sections[index] = _sections[index].copyWith(title: value);
    _scheduleAutoSave();
  }

  // Updates the notes text of a section at the given index.
  void _updateSectionNotes(int index, String value) {
    _sections[index] = _sections[index].copyWith(notes: value);
    _scheduleAutoSave();
  }

  // Adds a blank key term to a section.
  void _addKeyTerm(int sectionIndex) {
    final updated = List<KeyTerm>.from(_sections[sectionIndex].keyTerms)
      ..add(const KeyTerm(term: '', definition: ''));
    setState(() {
      _sections[sectionIndex] = _sections[sectionIndex].copyWith(
        keyTerms: updated,
      );
    });
    _scheduleAutoSave();
  }

  // Updates a key term within a section.
  void _updateKeyTerm(
    int sectionIndex,
    int termIndex,
    String term,
    String def,
  ) {
    final updated = List<KeyTerm>.from(_sections[sectionIndex].keyTerms);
    updated[termIndex] = KeyTerm(term: term, definition: def);
    setState(() {
      _sections[sectionIndex] = _sections[sectionIndex].copyWith(
        keyTerms: updated,
      );
    });
    _scheduleAutoSave();
  }

  // Removes a key term from a section.
  void _removeKeyTerm(int sectionIndex, int termIndex) {
    final updated = List<KeyTerm>.from(_sections[sectionIndex].keyTerms)
      ..removeAt(termIndex);
    setState(() {
      _sections[sectionIndex] = _sections[sectionIndex].copyWith(
        keyTerms: updated,
      );
    });
    _scheduleAutoSave();
  }

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: theme.primary,
          onPressed: () async {
            _saveTimer?.cancel();
            await _save();
            if (!context.mounted) {
              return;
            }
            Navigator.of(context).pop();
          },
        ),
        title: Row(
          children: [
            Text('📖 ', style: const TextStyle(fontSize: 18)),
            Text(
              'Study Guide',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.text,
              ),
            ),
          ],
        ),
        actions: [
          if (_saved)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                'Saved',
                style: TextStyle(fontSize: 13, color: theme.muted),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
        children: [
          // Title field
          TextField(
            controller: _titleCtrl,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: theme.text,
              decoration: TextDecoration.none,
            ),
            decoration: InputDecoration(
              hintText: 'Guide title…',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              hintStyle: TextStyle(color: theme.muted),
            ),
          ),
          const SizedBox(height: 8),
          // Sections
          for (int i = 0; i < _sections.length; i++)
            _SectionCard(
              index: i,
              section: _sections[i],
              onTitleChanged: (v) => _updateSectionTitle(i, v),
              onNotesChanged: (v) => _updateSectionNotes(i, v),
              onAddKeyTerm: () => _addKeyTerm(i),
              onKeyTermChanged: (ti, term, def) =>
                  _updateKeyTerm(i, ti, term, def),
              onRemoveKeyTerm: (ti) => _removeKeyTerm(i, ti),
              onRemove: _sections.length > 1 ? () => _removeSection(i) : null,
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _addSection,
            icon: const Icon(Icons.add),
            label: const Text('Add Section'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.primary,
              side: BorderSide(color: theme.primary.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Card widget for a single study guide section.
class _SectionCard extends StatefulWidget {
  const _SectionCard({
    required this.index,
    required this.section,
    required this.onTitleChanged,
    required this.onNotesChanged,
    required this.onAddKeyTerm,
    required this.onKeyTermChanged,
    required this.onRemoveKeyTerm,
    this.onRemove,
  });

  final int index;
  final StudyGuideSection section;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onNotesChanged;
  final VoidCallback onAddKeyTerm;
  final void Function(int, String, String) onKeyTermChanged;
  final ValueChanged<int> onRemoveKeyTerm;
  final VoidCallback? onRemove;

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.section.title);
    _notesCtrl = TextEditingController(text: widget.section.notes);
    _titleCtrl.addListener(() => widget.onTitleChanged(_titleCtrl.text));
    _notesCtrl.addListener(() => widget.onNotesChanged(_notesCtrl.text));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Text(
                  'Section ${widget.index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (widget.onRemove != null)
                  IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: theme.muted,
                      size: 18,
                    ),
                    onPressed: widget.onRemove,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _titleCtrl,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: theme.text,
                decoration: TextDecoration.none,
              ),
              decoration: InputDecoration(
                hintText: 'Section title…',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintStyle: TextStyle(color: theme.muted),
              ),
            ),
          ),
          Divider(color: theme.primary.withValues(alpha: 0.1), height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _notesCtrl,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: theme.text,
                decoration: TextDecoration.none,
              ),
              decoration: InputDecoration(
                hintText: '• Bullet notes…',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintStyle: TextStyle(color: theme.muted),
              ),
              maxLines: null,
              minLines: 3,
              keyboardType: TextInputType.multiline,
            ),
          ),
          // Key Terms
          if (widget.section.keyTerms.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Key Terms',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (int i = 0; i < widget.section.keyTerms.length; i++)
                    _KeyTermRow(
                      keyTerm: widget.section.keyTerms[i],
                      onChanged: (term, def) =>
                          widget.onKeyTermChanged(i, term, def),
                      onRemove: () => widget.onRemoveKeyTerm(i),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: TextButton.icon(
              onPressed: widget.onAddKeyTerm,
              icon: Icon(Icons.add, size: 16, color: theme.primary),
              label: Text(
                'Add key term',
                style: TextStyle(fontSize: 12, color: theme.primary),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Inline row editor for a single key term.
class _KeyTermRow extends StatefulWidget {
  const _KeyTermRow({
    required this.keyTerm,
    required this.onChanged,
    required this.onRemove,
  });
  final KeyTerm keyTerm;
  final void Function(String term, String definition) onChanged;
  final VoidCallback onRemove;

  @override
  State<_KeyTermRow> createState() => _KeyTermRowState();
}

class _KeyTermRowState extends State<_KeyTermRow> {
  late final TextEditingController _termCtrl;
  late final TextEditingController _defCtrl;

  @override
  void initState() {
    super.initState();
    _termCtrl = TextEditingController(text: widget.keyTerm.term);
    _defCtrl = TextEditingController(text: widget.keyTerm.definition);
    _termCtrl.addListener(_notify);
    _defCtrl.addListener(_notify);
  }

  void _notify() => widget.onChanged(_termCtrl.text, _defCtrl.text);

  @override
  void dispose() {
    _termCtrl.dispose();
    _defCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _termCtrl,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: theme.text,
                decoration: TextDecoration.none,
              ),
              decoration: InputDecoration(
                hintText: 'Term',
                isDense: true,
                hintStyle: TextStyle(color: theme.muted, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _defCtrl,
              style: TextStyle(
                fontSize: 13,
                color: theme.text,
                decoration: TextDecoration.none,
              ),
              decoration: InputDecoration(
                hintText: 'Definition',
                isDense: true,
                hintStyle: TextStyle(color: theme.muted, fontSize: 13),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 16, color: theme.muted),
            onPressed: widget.onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
