import 'dart:async';

import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../models/study_content_models.dart';
import '../models/study_models.dart';

// Full-screen editor for a Formula Sheet.
class FormulaSheetScreen extends StatefulWidget {
  const FormulaSheetScreen({super.key, this.note});

  // Existing note to edit, or null to create a new sheet.
  final StudyNote? note;

  @override
  State<FormulaSheetScreen> createState() => _FormulaSheetScreenState();
}

class _FormulaSheetScreenState extends State<FormulaSheetScreen> {
  late final TextEditingController _titleCtrl;
  late List<FormulaEntry> _formulas;
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
    _formulas = json != null
        ? FormulaSheetContent.fromJson(json).formulas.toList()
        : [const FormulaEntry(name: '', formula: '', explanation: '')];

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

  // Persists the formula sheet to app state.
  Future<void> _save() async {
    final state = StudyNestScope.read(context);
    final title = _titleCtrl.text.trim();
    if (title.isEmpty &&
        _formulas.every((f) => f.name.isEmpty && f.formula.isEmpty)) {
      return;
    }

    final content = FormulaSheetContent(formulas: _formulas).toJson();

    if (_noteId == null) {
      final result = await state.addNote(
        title: title.isEmpty ? 'Formula Sheet' : title,
        body: '',
        colorName: 'honey',
        tags: _tags,
        noteType: NoteType.formula,
        contentJson: content,
      );
      if (result.applied && mounted) {
        final created = state.notes.firstWhere(
          (n) => n.noteType == NoteType.formula && n.contentJson == content,
          orElse: () => state.notes.first,
        );
        _noteId = created.id;
      }
    } else {
      await state.updateNote(
        noteId: _noteId!,
        title: title.isEmpty ? 'Formula Sheet' : title,
        body: '',
        colorName: 'honey',
        tags: _tags,
        contentJson: content,
      );
    }
    if (mounted) setState(() => _saved = true);
  }

  // Adds a blank formula entry.
  void _addFormula() {
    setState(
      () => _formulas.add(
        const FormulaEntry(name: '', formula: '', explanation: ''),
      ),
    );
    _scheduleAutoSave();
  }

  // Removes a formula entry by index.
  void _removeFormula(int index) {
    if (_formulas.length <= 1) return;
    setState(() => _formulas.removeAt(index));
    _scheduleAutoSave();
  }

  // Updates a formula entry field.
  void _updateFormula(int index, FormulaEntry updated) {
    setState(() => _formulas[index] = updated);
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
            if (!context.mounted) return;
            Navigator.of(context).pop();
          },
        ),
        title: Row(
          children: [
            const Text('🔢 ', style: TextStyle(fontSize: 18)),
            Text(
              'Formula Sheet',
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
          TextField(
            controller: _titleCtrl,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: theme.text,
              decoration: TextDecoration.none,
            ),
            decoration: InputDecoration(
              hintText: 'Sheet title…',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              hintStyle: TextStyle(color: theme.muted),
            ),
          ),
          Text(
            '${_formulas.length} formula${_formulas.length == 1 ? '' : 's'}',
            style: TextStyle(fontSize: 13, color: theme.muted),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < _formulas.length; i++)
            _FormulaCard(
              index: i,
              entry: _formulas[i],
              onChanged: (updated) => _updateFormula(i, updated),
              onRemove: _formulas.length > 1 ? () => _removeFormula(i) : null,
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addFormula,
            icon: const Icon(Icons.add),
            label: const Text('Add Formula'),
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

// Card editor for a single formula entry with name, formula, and explanation.
class _FormulaCard extends StatefulWidget {
  const _FormulaCard({
    required this.index,
    required this.entry,
    required this.onChanged,
    this.onRemove,
  });

  final int index;
  final FormulaEntry entry;
  final ValueChanged<FormulaEntry> onChanged;
  final VoidCallback? onRemove;

  @override
  State<_FormulaCard> createState() => _FormulaCardState();
}

class _FormulaCardState extends State<_FormulaCard> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _formulaCtrl;
  late final TextEditingController _explanationCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.entry.name);
    _formulaCtrl = TextEditingController(text: widget.entry.formula);
    _explanationCtrl = TextEditingController(text: widget.entry.explanation);
    _nameCtrl.addListener(_notify);
    _formulaCtrl.addListener(_notify);
    _explanationCtrl.addListener(_notify);
  }

  // Emits updated entry to parent.
  void _notify() {
    widget.onChanged(
      widget.entry.copyWith(
        name: _nameCtrl.text,
        formula: _formulaCtrl.text,
        explanation: _explanationCtrl.text,
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _formulaCtrl.dispose();
    _explanationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
            child: Row(
              children: [
                Text(
                  '#${widget.index + 1}',
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
                      size: 18,
                      color: theme.muted,
                    ),
                    onPressed: widget.onRemove,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          // Name field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _nameCtrl,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: theme.text,
                decoration: TextDecoration.none,
              ),
              decoration: InputDecoration(
                hintText: 'Formula name (e.g. Quadratic Formula)',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintStyle: TextStyle(color: theme.muted, fontSize: 13),
              ),
            ),
          ),
          // Formula box
          Container(
            margin: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
            ),
            child: TextField(
              controller: _formulaCtrl,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                color: theme.primary,
                decoration: TextDecoration.none,
              ),
              decoration: InputDecoration(
                hintText: 'x = (-b ± √(b²-4ac)) / 2a',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintStyle: TextStyle(color: theme.muted, fontSize: 13),
              ),
            ),
          ),
          // Explanation field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: TextField(
              controller: _explanationCtrl,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: theme.text,
                decoration: TextDecoration.none,
              ),
              decoration: InputDecoration(
                hintText: 'Explanation or example…',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintStyle: TextStyle(color: theme.muted, fontSize: 13),
              ),
              maxLines: 3,
              minLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
