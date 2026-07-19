part of 'quiz_screen.dart';

// Presents quiz questions one at a time and tracks the score.
class _QuizRunnerScreen extends StatefulWidget {
  const _QuizRunnerScreen({required this.questions});

  final List<QuizQuestion> questions;

  // Creates state that tracks the learner's answers and progress.
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

  // Builds the active question or the final score summary.
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

    final question = widget.questions[_current];
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
        title: Text(
          'Question ${_current + 1} / ${widget.questions.length}',
          style: TextStyle(color: theme.muted, fontSize: 14),
        ),
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
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      question.question,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: theme.text,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (var index = 0; index < question.choices.length; index++)
                    if (question.choices[index].isNotEmpty)
                      _AnswerTile(
                        label: labels[index],
                        text: question.choices[index],
                        state: _answered
                            ? (index == question.correctIndex
                                  ? _AnswerState.correct
                                  : (index == _selected
                                        ? _AnswerState.wrong
                                        : _AnswerState.neutral))
                            : _AnswerState.neutral,
                        onTap: () => _select(index),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          _current < widget.questions.length - 1
                              ? 'Next →'
                              : 'See Results',
                        ),
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

  // Builds an answer button with its current correctness feedback.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    final Color background;
    final Color border;
    switch (state) {
      case _AnswerState.correct:
        background = Colors.green.withValues(alpha: 0.15);
        border = Colors.green;
      case _AnswerState.wrong:
        background = Colors.red.withValues(alpha: 0.15);
        border = Colors.red;
      case _AnswerState.neutral:
        background = theme.surface;
        border = theme.primary.withValues(alpha: 0.2);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: border.withValues(alpha: 0.15),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: border,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  color: theme.text,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Results screen shown after finishing the quiz.
class _ResultsScreen extends StatelessWidget {
  const _ResultsScreen({
    required this.score,
    required this.total,
    required this.onClose,
  });

  final int score;
  final int total;
  final VoidCallback onClose;

  // Builds the final score summary and exit control.
  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    final percentage = total > 0 ? (score / total * 100).round() : 0;
    final emoji = percentage >= 80
        ? '🎉'
        : percentage >= 60
        ? '👍'
        : '📚';

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
              Text(
                '$score / $total',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: theme.primary,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$percentage% correct',
                style: TextStyle(
                  fontSize: 18,
                  color: theme.muted,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onClose,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primary,
                    foregroundColor: theme.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
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
