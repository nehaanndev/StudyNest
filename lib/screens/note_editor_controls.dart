part of 'note_editor_screen.dart';

// Displays note-formatting shortcuts above the keyboard.
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

  // Builds the formatting shortcut row.
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

// Renders one action in the editor's formatting toolbar.
class _ToolbarBtn extends StatelessWidget {
  const _ToolbarBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  // Builds the tappable icon-and-label control.
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

  // Creates the local mutable selection state for the tag picker.
  @override
  State<_TagPickerSheet> createState() => _TagPickerSheetState();
}

class _TagPickerSheetState extends State<_TagPickerSheet> {
  late List<String> _tags;
  final _ctrl = TextEditingController();

  // Initializes a locally editable copy of the caller's selected tags.
  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.selected);
  }

  // Releases the controller used to enter a custom tag.
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

  // Builds the tag selection sheet and custom-tag controls.
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
          if (_tags.any((tag) => !_kTagSuggestions.contains(tag))) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags
                  .where((tag) => !_kTagSuggestions.contains(tag))
                  .map((tag) {
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
                  })
                  .toList(),
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

  // Builds the selectable folder list and closes after a selection.
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
