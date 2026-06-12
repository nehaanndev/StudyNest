import 'dart:async';

import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../models/study_models.dart';

// Predefined folders users can choose from.
const _kDefaultFolders = ['School', 'Personal', 'Projects', 'Robotics', 'SAT'];

// Predefined tag suggestions shown in the tag picker.
const _kTagSuggestions = [
  'school',
  'math',
  'apes',
  'robotics',
  'personal',
  'homework',
  'tests',
  'reading',
];

// Note color options mapped to display names.
const _kNoteColors = ['honey', 'matcha', 'rose', 'ink'];

class NoteEditorScreen extends StatefulWidget {
  const NoteEditorScreen({super.key, this.note});

  // When null a new note is created; otherwise the existing note is edited.
  final StudyNote? note;

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late String _colorName;
  late String _folder;
  late List<String> _tags;
  Timer? _autoSaveTimer;
  bool _saved = false;
  bool _isNew = false;
  String? _savedNoteId;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _isNew = note == null;
    _savedNoteId = note?.id;
    _titleCtrl = TextEditingController(text: note?.title ?? '');
    _bodyCtrl = TextEditingController(text: note?.body ?? '');
    _colorName = note?.colorName ?? 'honey';
    _folder = note?.folder ?? '';
    _tags = List.from(note?.tags ?? []);

    _titleCtrl.addListener(_onChanged);
    _bodyCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleCtrl.removeListener(_onChanged);
    _bodyCtrl.removeListener(_onChanged);
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  // Triggers a debounced auto-save whenever content changes.
  void _onChanged() {
    setState(() => _saved = false);
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _save);
  }

  // Persists the note immediately, creating or updating as appropriate.
  Future<void> _save() async {
    final state = StudyNestScope.read(context);
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    if (title.isEmpty && body.isEmpty) return;

    if (_isNew && _savedNoteId == null) {
      final result = await state.addNote(
        title: title.isEmpty ? 'Untitled' : title,
        body: body,
        colorName: _colorName,
        tags: _tags,
        folder: _folder,
      );
      if (result.applied && mounted) {
        // Capture the id so subsequent saves update the same note.
        final created = state.notes.firstWhere(
          (n) =>
              n.title == (title.isEmpty ? 'Untitled' : title) && n.body == body,
          orElse: () => state.notes.first,
        );
        _savedNoteId = created.id;
        _isNew = false;
      }
    } else if (_savedNoteId != null) {
      await state.updateNote(
        noteId: _savedNoteId!,
        title: title.isEmpty ? 'Untitled' : title,
        body: body,
        colorName: _colorName,
        tags: _tags,
        folder: _folder,
      );
    }
    if (mounted) setState(() => _saved = true);
  }

  // Deletes the note and closes the screen.
  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      if (_savedNoteId != null) {
        await StudyNestScope.read(context).deleteNote(_savedNoteId!);
      }
      if (mounted) Navigator.of(context).pop();
    }
  }

  // Inserts markdown formatting around current selection or at cursor.
  void _insertFormat(String prefix, [String? suffix]) {
    final sel = _bodyCtrl.selection;
    final text = _bodyCtrl.text;
    if (!sel.isValid) {
      _bodyCtrl.text = text + prefix + (suffix ?? prefix);
      return;
    }
    final selected = sel.textInside(text);
    final replacement = '$prefix$selected${suffix ?? prefix}';
    final newText = text.replaceRange(sel.start, sel.end, replacement);
    _bodyCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: sel.start + replacement.length,
      ),
    );
  }

  // Inserts a line prefix (heading, bullet, checklist) at start of current line.
  void _insertLinePrefix(String prefix) {
    final text = _bodyCtrl.text;
    final offset = _bodyCtrl.selection.baseOffset.clamp(0, text.length);
    final lineStart = text.lastIndexOf('\n', offset - 1) + 1;
    final newText =
        text.substring(0, lineStart) + prefix + text.substring(lineStart);
    _bodyCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: offset + prefix.length),
    );
  }

  // Opens a picker to add or remove tags from the note.
  void _showTagPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TagPickerSheet(
        selected: _tags,
        onChanged: (tags) {
          setState(() => _tags = tags);
          _onChanged();
        },
      ),
    );
  }

  // Opens a picker to choose the note's folder.
  void _showFolderPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _FolderPickerSheet(
        selected: _folder,
        onChanged: (folder) {
          setState(() => _folder = folder);
          _onChanged();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    final cardColor = _noteCardColor(
      _colorName,
      theme.isDark,
      theme.surfaceAlt,
    );

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: theme.primary,
          onPressed: () async {
            _autoSaveTimer?.cancel();
            await _save();
            if (!context.mounted) {
              return;
            }
            Navigator.of(context).pop();
          },
        ),
        title: _saved
            ? Text('Saved', style: TextStyle(fontSize: 13, color: theme.muted))
            : const SizedBox.shrink(),
        actions: [
          // Color picker
          PopupMenuButton<String>(
            icon: Icon(Icons.palette_outlined, color: theme.primary),
            onSelected: (color) {
              setState(() => _colorName = color);
              _onChanged();
            },
            itemBuilder: (_) => _kNoteColors
                .map(
                  (c) => PopupMenuItem(
                    value: c,
                    child: Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _noteCardColor(
                              c,
                              theme.isDark,
                              theme.surfaceAlt,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(c, style: TextStyle(color: theme.text)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          if (_savedNoteId != null)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
              onPressed: _delete,
            ),
        ],
      ),
      body: Column(
        children: [
          // Note card background
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: cardColor,
              child: Column(
                children: [
                  // Title field
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: TextField(
                      controller: _titleCtrl,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: theme.isDark
                            ? theme.text
                            : const Color(0xFF1A110A),
                        decoration: TextDecoration.none,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                      maxLines: 2,
                      minLines: 1,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  // Metadata row: folder + tags
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _showFolderPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.folder_outlined,
                                  size: 14,
                                  color: theme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _folder.isEmpty ? 'No folder' : _folder,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: _showTagPicker,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  if (_tags.isEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.primary.withValues(
                                          alpha: 0.07,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.sell_outlined,
                                            size: 13,
                                            color: theme.muted,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Add tags',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: theme.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    for (final tag in _tags) ...[
                                      Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.primary.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          tag,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: theme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: theme.primary.withValues(alpha: 0.12),
                    height: 1,
                  ),
                  // Body field
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      child: TextField(
                        controller: _bodyCtrl,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: theme.isDark
                              ? theme.text
                              : const Color(0xFF1A110A),
                          decoration: TextDecoration.none,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Start writing…',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                        ),
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        keyboardType: TextInputType.multiline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Format toolbar
          _FormatToolbar(
            onBold: () => _insertFormat('**'),
            onItalic: () => _insertFormat('_'),
            onHeading: () => _insertLinePrefix('# '),
            onBullet: () => _insertLinePrefix('- '),
            onChecklist: () => _insertLinePrefix('- [ ] '),
          ),
        ],
      ),
    );
  }

  // Returns a card background color for the given note color name.
  Color _noteCardColor(String colorName, bool isDark, Color fallback) {
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

// Toolbar shown at the bottom of the editor with markdown format shortcuts.
class _FormatToolbar extends StatelessWidget {
  const _FormatToolbar({
    required this.onBold,
    required this.onItalic,
    required this.onHeading,
    required this.onBullet,
    required this.onChecklist,
  });

  final VoidCallback onBold;
  final VoidCallback onItalic;
  final VoidCallback onHeading;
  final VoidCallback onBullet;
  final VoidCallback onChecklist;

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    return Container(
      color: theme.surface,
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 4 : 12,
      ),
      child: Row(
        children: [
          _ToolbarBtn(icon: Icons.format_bold, label: 'Bold', onTap: onBold),
          _ToolbarBtn(
            icon: Icons.format_italic,
            label: 'Italic',
            onTap: onItalic,
          ),
          _ToolbarBtn(icon: Icons.title, label: 'Heading', onTap: onHeading),
          _ToolbarBtn(
            icon: Icons.format_list_bulleted,
            label: 'Bullet',
            onTap: onBullet,
          ),
          _ToolbarBtn(
            icon: Icons.checklist,
            label: 'Checklist',
            onTap: onChecklist,
          ),
        ],
      ),
    );
  }
}

class _ToolbarBtn extends StatelessWidget {
  const _ToolbarBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: theme.primary),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: theme.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Bottom sheet for picking and removing tags.
class _TagPickerSheet extends StatefulWidget {
  const _TagPickerSheet({required this.selected, required this.onChanged});
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  State<_TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends State<_TagPickerSheet> {
  late List<String> _tags;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.selected);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Adds a custom typed tag to the list.
  void _addCustom() {
    final tag = _ctrl.text.trim().toLowerCase();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
      widget.onChanged(_tags);
    }
    _ctrl.clear();
  }

  // Toggles a suggested tag on or off.
  void _toggle(String tag) {
    setState(() {
      if (_tags.contains(tag)) {
        _tags.remove(tag);
      } else {
        _tags.add(tag);
      }
    });
    widget.onChanged(_tags);
  }

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.muted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tags',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kTagSuggestions.map((tag) {
              final selected = _tags.contains(tag);
              return GestureDetector(
                onTap: () => _toggle(tag),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.primary.withValues(alpha: 0.2)
                        : theme.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? theme.primary
                          : theme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? theme.primary : theme.muted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: const InputDecoration(
                    hintText: 'Custom tag…',
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addCustom(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addCustom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primary,
                  foregroundColor: theme.background,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
          // Show any custom tags not in suggestions
          if (_tags.any((t) => !_kTagSuggestions.contains(t))) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.where((t) => !_kTagSuggestions.contains(t)).map((
                tag,
              ) {
                return GestureDetector(
                  onTap: () => _toggle(tag),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: theme.primary),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tag,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: theme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.close, size: 12, color: theme.primary),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// Bottom sheet for picking the note's folder.
class _FolderPickerSheet extends StatelessWidget {
  const _FolderPickerSheet({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.muted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Folder',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: theme.text,
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: Icon(Icons.folder_off_outlined, color: theme.muted),
            title: Text('No folder', style: TextStyle(color: theme.text)),
            trailing: selected.isEmpty
                ? Icon(Icons.check, color: theme.primary)
                : null,
            onTap: () {
              onChanged('');
              Navigator.of(context).pop();
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          for (final folder in _kDefaultFolders)
            ListTile(
              leading: Icon(Icons.folder_outlined, color: theme.primary),
              title: Text(folder, style: TextStyle(color: theme.text)),
              trailing: selected == folder
                  ? Icon(Icons.check, color: theme.primary)
                  : null,
              onTap: () {
                onChanged(folder);
                Navigator.of(context).pop();
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
        ],
      ),
    );
  }
}
