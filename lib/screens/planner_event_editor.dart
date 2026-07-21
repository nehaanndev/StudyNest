import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../models/study_models.dart';
import '../utils/date_labels.dart';

/// Opens the shared create/edit sheet used by calendar overview and Plan Mode.
Future<void> showPlannerEventEditor(
  BuildContext context, {
  required DateTime selectedDay,
  PlannerEvent? event,
  DateTime? suggestedStart,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _PlannerEventEditor(
      selectedDay: selectedDay,
      event: event,
      suggestedStart: suggestedStart,
    ),
  );
}

class _PlannerEventEditor extends StatefulWidget {
  const _PlannerEventEditor({
    required this.selectedDay,
    this.event,
    this.suggestedStart,
  });

  final DateTime selectedDay;
  final PlannerEvent? event;
  final DateTime? suggestedStart;

  // Creates the state that owns temporary form values and validation.
  @override
  State<_PlannerEventEditor> createState() => _PlannerEventEditorState();
}

class _PlannerEventEditorState extends State<_PlannerEventEditor> {
  late final TextEditingController _titleController;
  late String _category;
  late DateTime _startsAt;
  late DateTime _endsAt;
  String? _titleError;
  bool _isSaving = false;

  // Seeds the editor with the event values or a useful next-hour suggestion.
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final defaultStart =
        widget.suggestedStart ??
        DateTime(
          widget.selectedDay.year,
          widget.selectedDay.month,
          widget.selectedDay.day,
          now.hour + 1,
        );
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _category = widget.event?.category ?? 'Study';
    _startsAt = widget.event?.startsAt ?? defaultStart;
    _endsAt =
        widget.event?.endsAt ?? defaultStart.add(const Duration(hours: 1));
  }

  // Releases the text controller after the sheet leaves the widget tree.
  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  // Builds a compact, keyboard-safe editor with the main actions always close.
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final editing = widget.event != null;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(20, 4, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              editing ? 'Edit study block' : 'Plan a study block',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              editing
                  ? 'Adjust the details or move this block on the timeline.'
                  : 'Give this time a clear purpose. You can drag it later.',
              style: TextStyle(
                color: StudyNestScope.watch(context).selectedTheme.muted,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _titleController,
              autofocus: !editing,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'What are you working on?',
                hintText: 'Review biology notes',
                errorText: _titleError,
              ),
              onSubmitted: (_) => _save(),
              onChanged: (_) {
                if (_titleError != null) setState(() => _titleError = null);
              },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(value: 'Study', child: Text('Study')),
                DropdownMenuItem(value: 'Review', child: Text('Review')),
                DropdownMenuItem(value: 'Break', child: Text('Break')),
                DropdownMenuItem(value: 'Plan', child: Text('Plan')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined, size: 21),
              title: const Text('Date'),
              subtitle: Text(compactDate(_startsAt)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule_outlined, size: 21),
              title: const Text('Time'),
              subtitle: Text(timeRange(_startsAt, _endsAt)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pickTimeRange,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (editing)
                  IconButton(
                    tooltip: 'Delete block',
                    onPressed: _isSaving ? null : _confirmDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isSaving ? null : _save,
                  icon: _isSaving
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: Text(editing ? 'Save changes' : 'Add to plan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Changes the event date while keeping its existing time and duration.
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      initialDate: _startsAt,
    );
    if (picked == null || !mounted) return;
    final duration = _endsAt.difference(_startsAt);
    setState(() {
      _startsAt = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _startsAt.hour,
        _startsAt.minute,
      );
      _endsAt = _startsAt.add(duration);
    });
  }

  // Collects start and end times, preserving a positive event duration.
  Future<void> _pickTimeRange() async {
    final start = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt),
      helpText: 'Choose start time',
    );
    if (start == null || !mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endsAt),
      helpText: 'Choose end time',
    );
    if (end == null || !mounted) return;
    setState(() {
      _startsAt = DateTime(
        _startsAt.year,
        _startsAt.month,
        _startsAt.day,
        start.hour,
        start.minute,
      );
      _endsAt = DateTime(
        _startsAt.year,
        _startsAt.month,
        _startsAt.day,
        end.hour,
        end.minute,
      );
      if (!_endsAt.isAfter(_startsAt)) {
        _endsAt = _startsAt.add(const Duration(hours: 1));
      }
    });
  }

  // Validates and persists a newly created or edited study block.
  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Add a short title for this block.');
      return;
    }
    setState(() => _isSaving = true);
    final state = StudyNestScope.read(context);
    final event = widget.event;
    final result = event == null
        ? await state.addPlannerEvent(
            title: title,
            startsAt: _startsAt,
            endsAt: _endsAt,
            category: _category,
          )
        : null;
    if (event != null) {
      await state.updatePlannerEvent(
        eventId: event.id,
        title: title,
        startsAt: _startsAt,
        endsAt: _endsAt,
        category: _category,
      );
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    final message = result?.message ?? 'Block updated.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    if (result != null && !result.applied) return;
    Navigator.pop(context);
  }

  // Confirms deletion so an accidental tap cannot remove a planned block.
  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this block?'),
        content: Text(
          '“${widget.event!.title}” will be removed from your plan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;
    await StudyNestScope.read(context).deletePlannerEvent(widget.event!.id);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Block deleted.')));
  }
}
