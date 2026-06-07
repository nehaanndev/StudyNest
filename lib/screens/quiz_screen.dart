import 'dart:async';

import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../models/study_content_models.dart';
import '../models/study_models.dart';

// Full-screen editor and runner for a Quiz.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, this.note});

  // Existing note to edit, or null to create a new quiz.
  final StudyNote? note;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late final TextEditingController _titleCtrl;
  late List<QuizQuestion> _questions;
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
    _questions = json != null
        ? QuizContent.fromJson(json).questions.toList()
        : [QuizQuestion.blank()];

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

  // Persists the quiz to app state.
  Future<void> _save() async {
    final state = StudyNestScope.read(context);
    final title = _titleCtrl.text.trim();
    if (title.isEmpty && _questions.every((q) => q.question.isEmpty)) return;

    final content = QuizContent(questions: _questions).toJson();

    if (_noteId == null) {
      final result = await state.addNote(
        title: title.isEmpty ? 'Quiz' : title,
        body: '',
        colorName: 'ink',
        tags: _tags,
        noteType: NoteType.quiz,
        contentJson: content,
      );
      if (result.applied && mounted) {
        final created = state.notes.firstWhere(
          (n) => n.noteType == NoteType.quiz && n.contentJson == content,
          orElse: () => state.notes.first,
        );
        _noteId = created.id;
      }
    } else {
      await state.updateNote(
        noteId: _noteId!,
        title: title.isEmpty ? 'Quiz' : title,
        body: '',
        colorName: 'ink',
        tags: _tags,
        contentJson: content,
      );
    }
    if (mounted) setState(() => _saved = true);
  }

  // Adds a blank question.
  void _addQuestion() {
    setState(() => _questions.add(QuizQuestion.blank()));
    _scheduleAutoSave();
  }

  // Removes a question by index.
  void _removeQuestion(int index) {
    if (_questions.length <= 1) return;
    setState(() => _questions.removeAt(index));
    _scheduleAutoSave();
  }

  // Updates a question field.
  void _updateQuestion(int index, QuizQuestion updated) {
    setState(() => _questions[index] = updated);
    _scheduleAutoSave();
  }

  // Launches the quiz runner with current questions.
  void _startQuiz() async {
    _saveTimer?.cancel();
    await _save();
    if (!mounted) return;
    final valid = _questions.where((q) => q.question.isNotEmpty && q.choices.any((c) => c.isNotEmpty)).toList();
    if (valid.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _QuizRunnerScreen(questions: valid)),
    );
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
            if (mounted) Navigator.of(context).pop();
          },
        ),
        title: Row(children: [
          const Text('❓ ', style: TextStyle(fontSize: 18)),
          Text('Quiz', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.text)),
        ]),
        actions: [
          if (_saved)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text('Saved', style: TextStyle(fontSize: 13, color: theme.muted)),
            ),
          if (_questions.any((q) => q.question.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: _startQuiz,
                style: TextButton.styleFrom(
                  backgroundColor: theme.primary.withValues(alpha: 0.12),
                  foregroundColor: theme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Take Quiz'),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
        children: [
          TextField(
            controller: _titleCtrl,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: theme.text, decoration: TextDecoration.none),
            decoration: InputDecoration(
              hintText: 'Quiz title…',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              hintStyle: TextStyle(color: theme.muted),
            ),
          ),
          Text('${_questions.length} question${_questions.length == 1 ? '' : 's'}',
              style: TextStyle(fontSize: 13, color: theme.muted)),
          const SizedBox(height: 14),
          for (int i = 0; i < _questions.length; i++)
            _QuestionEditor(
              index: i,
              question: _questions[i],
              onChanged: (q) => _updateQuestion(i, q),
              onRemove: _questions.length > 1 ? () => _removeQuestion(i) : null,
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addQuestion,
            icon: const Icon(Icons.add),
            label: const Text('Add Question'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.primary,
              side: BorderSide(color: theme.primary.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}

// Editor for a single quiz question with choices and correct answer selector.
class _QuestionEditor extends StatefulWidget {
  const _QuestionEditor({
    required this.index,
    required this.question,
    required this.onChanged,
    this.onRemove,
  });

  final int index;
  final QuizQuestion question;
  final ValueChanged<QuizQuestion> onChanged;
  final VoidCallback? onRemove;

  @override
  State<_QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<_QuestionEditor> {
  late final TextEditingController _qCtrl;
  late final List<TextEditingController> _choiceCtrl;

  @override
  void initState() {
    super.initState();
    _qCtrl = TextEditingController(text: widget.question.question);
    _choiceCtrl = List.generate(4, (i) =>
      TextEditingController(text: widget.question.choices.length > i ? widget.question.choices[i] : ''));
    _qCtrl.addListener(_notify);
    for (final c in _choiceCtrl) c.addListener(_notify);
  }

  // Emits updated question to parent.
  void _notify() {
    widget.onChanged(widget.question.copyWith(
      question: _qCtrl.text,
      choices: _choiceCtrl.map((c) => c.text).toList(),
    ));
  }

  // Sets the correct answer index.
  void _setCorrect(int index) {
    widget.onChanged(widget.question.copyWith(correctIndex: index));
  }

  @override
  void dispose() {
    _qCtrl.dispose();
    for (final c in _choiceCtrl) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    const labels = ['A', 'B', 'C', 'D'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                Text('Q${widget.index + 1}', style: TextStyle(fontSize: 11, color: theme.muted, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (widget.onRemove != null)
                  IconButton(
                    icon: Icon(Icons.remove_circle_outline, size: 18, color: theme.muted),
                    onPressed: widget.onRemove,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _qCtrl,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: theme.text, decoration: TextDecoration.none),
              decoration: InputDecoration(
                hintText: 'Question…',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintStyle: TextStyle(color: theme.muted),
              ),
              maxLines: 2,
              minLines: 1,
            ),
          ),
          Divider(color: theme.primary.withValues(alpha: 0.08), height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choices — tap letter to mark correct', style: TextStyle(fontSize: 11, color: theme.muted)),
                const SizedBox(height: 8),
                for (int i = 0; i < 4; i++)
                  _ChoiceRow(
                    label: labels[i],
                    controller: _choiceCtrl[i],
                    isCorrect: widget.question.correctIndex == i,
                    onTapLabel: () => _setCorrect(i),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Single choice row with a letter badge and text field.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.controller,
    required this.isCorrect,
    required this.onTapLabel,
  });

  final String label;
  final TextEditingController controller;
  final bool isCorrect;
  final VoidCallback onTapLabel;

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: onTapLabel,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isCorrect ? Colors.green.withValues(alpha: 0.2) : theme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCorrect ? Colors.green : theme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Text(label, style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: isCorrect ? Colors.green : theme.muted,
                )),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              style: TextStyle(fontSize: 14, color: theme.text, decoration: TextDecoration.none),
              decoration: InputDecoration(
                hintText: 'Choice $label…',
                isDense: true,
                hintStyle: TextStyle(color: theme.muted, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Quiz runner screen — presents questions one at a time and scores at the end.
class _QuizRunnerScreen extends StatefulWidget {
  const _QuizRunnerScreen({required this.questions});
  final List<QuizQuestion> questions;

  @override
  State<_QuizRunnerScreen> createState() => _QuizRunnerScreenState();
}

class _QuizRunnerScreenState extends State<_QuizRunnerScreen> {
  int _current = 0;
  int? _selected;
  int _score = 0;
  bool _answered = false;
  bool _finished = false;

  // Handles a choice selection, revealing correct/wrong feedback.
  void _select(int index) {
    if (_answered) return;
    final correct = widget.questions[_current].correctIndex;
    setState(() {
      _selected = index;
      _answered = true;
      if (index == correct) _score++;
    });
  }

  // Advances to the next question or shows the results screen.
  void _next() {
    if (_current < widget.questions.length - 1) {
      setState(() {
        _current++;
        _selected = null;
        _answered = false;
      });
    } else {
      setState(() => _finished = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;

    if (_finished) {
      return _ResultsScreen(
        score: _score,
        total: widget.questions.length,
        onClose: () => Navigator.of(context).pop(),
      );
    }

    final q = widget.questions[_current];
    const labels = ['A', 'B', 'C', 'D'];

    return Scaffold(
      backgroundColor: theme.background,
      appBar: AppBar(
        backgroundColor: theme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          color: theme.primary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Question ${_current + 1} / ${widget.questions.length}',
            style: TextStyle(color: theme.muted, fontSize: 14)),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_current + 1) / widget.questions.length,
            backgroundColor: theme.primary.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      q.question,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.text, decoration: TextDecoration.none),
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (int i = 0; i < q.choices.length; i++)
                    if (q.choices[i].isNotEmpty)
                      _AnswerTile(
                        label: labels[i],
                        text: q.choices[i],
                        state: _answered
                            ? (i == q.correctIndex
                                ? _AnswerState.correct
                                : (i == _selected ? _AnswerState.wrong : _AnswerState.neutral))
                            : _AnswerState.neutral,
                        onTap: () => _select(i),
                      ),
                  const Spacer(),
                  if (_answered)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          foregroundColor: theme.background,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(_current < widget.questions.length - 1 ? 'Next →' : 'See Results'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _AnswerState { neutral, correct, wrong }

// A single answer choice tile with color feedback.
class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.label,
    required this.text,
    required this.state,
    required this.onTap,
  });

  final String label;
  final String text;
  final _AnswerState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    final Color bg;
    final Color border;
    switch (state) {
      case _AnswerState.correct:
        bg = Colors.green.withValues(alpha: 0.15);
        border = Colors.green;
      case _AnswerState.wrong:
        bg = Colors.red.withValues(alpha: 0.15);
        border = Colors.red;
      case _AnswerState.neutral:
        bg = theme.surface;
        border = theme.primary.withValues(alpha: 0.2);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(shape: BoxShape.circle, color: border.withValues(alpha: 0.15)),
              child: Center(
                child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: border)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: TextStyle(fontSize: 15, color: theme.text, decoration: TextDecoration.none))),
          ],
        ),
      ),
    );
  }
}

// Results screen shown after finishing the quiz.
class _ResultsScreen extends StatelessWidget {
  const _ResultsScreen({required this.score, required this.total, required this.onClose});
  final int score;
  final int total;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    final pct = total > 0 ? (score / total * 100).round() : 0;
    final emoji = pct >= 80 ? '🎉' : pct >= 60 ? '👍' : '📚';

    return Scaffold(
      backgroundColor: theme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 20),
              Text('$score / $total', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: theme.primary, decoration: TextDecoration.none)),
              const SizedBox(height: 8),
              Text('$pct% correct', style: TextStyle(fontSize: 18, color: theme.muted, decoration: TextDecoration.none)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: theme.background,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
