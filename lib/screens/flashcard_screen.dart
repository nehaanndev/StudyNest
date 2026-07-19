import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app/study_nest_scope.dart';
import '../models/study_content_models.dart';
import '../models/study_models.dart';

// Full-screen editor and review mode for a Flashcard Set.
class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key, this.note});

  // Existing note to edit, or null to create a new set.
  final StudyNote? note;

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  late final TextEditingController _titleCtrl;
  late List<Flashcard> _cards;
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
    _cards = json != null
        ? FlashcardSetContent.fromJson(json).cards.toList()
        : [const Flashcard(front: '', back: '')];

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

  // Persists the flashcard set.
  Future<void> _save() async {
    final state = StudyNestScope.read(context);
    final title = _titleCtrl.text.trim();
    if (title.isEmpty &&
        _cards.every((c) => c.front.isEmpty && c.back.isEmpty)) {
      return;
    }

    final content = FlashcardSetContent(cards: _cards).toJson();

    if (_noteId == null) {
      final result = await state.addNote(
        title: title.isEmpty ? 'Flashcard Set' : title,
        body: '',
        colorName: 'rose',
        tags: _tags,
        noteType: NoteType.flashcards,
        contentJson: content,
      );
      if (result.applied && mounted) {
        final created = state.notes.firstWhere(
          (n) => n.noteType == NoteType.flashcards && n.contentJson == content,
          orElse: () => state.notes.first,
        );
        _noteId = created.id;
      }
    } else {
      await state.updateNote(
        noteId: _noteId!,
        title: title.isEmpty ? 'Flashcard Set' : title,
        body: '',
        colorName: 'rose',
        tags: _tags,
        contentJson: content,
      );
    }
    if (mounted) setState(() => _saved = true);
  }

  // Adds a blank card.
  void _addCard() {
    setState(() => _cards.add(const Flashcard(front: '', back: '')));
    _scheduleAutoSave();
  }

  // Removes a card by index.
  void _removeCard(int index) {
    if (_cards.length <= 1) return;
    setState(() => _cards.removeAt(index));
    _scheduleAutoSave();
  }

  // Updates a card's front or back text.
  void _updateCard(int index, {String? front, String? back}) {
    _cards[index] = _cards[index].copyWith(front: front, back: back);
    _scheduleAutoSave();
  }

  // Opens the review mode with the current cards.
  void _startReview() async {
    _saveTimer?.cancel();
    await _save();
    if (!mounted) return;
    final validCards = _cards.where((c) => c.front.isNotEmpty).toList();
    if (validCards.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FlashcardReviewScreen(cards: validCards),
      ),
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
            if (!context.mounted) return;
            Navigator.of(context).pop();
          },
        ),
        title: Row(
          children: [
            const Text('🃏 ', style: TextStyle(fontSize: 18)),
            Text(
              'Flashcards',
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
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'Saved',
                style: TextStyle(fontSize: 13, color: theme.muted),
              ),
            ),
          if (_cards.any((c) => c.front.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: _startReview,
                style: TextButton.styleFrom(
                  backgroundColor: theme.primary.withValues(alpha: 0.12),
                  foregroundColor: theme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Review'),
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
              hintText: 'Set title…',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              hintStyle: TextStyle(color: theme.muted),
            ),
          ),
          Text(
            '${_cards.length} card${_cards.length == 1 ? '' : 's'}',
            style: TextStyle(fontSize: 13, color: theme.muted),
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < _cards.length; i++)
            _CardEditor(
              index: i,
              card: _cards[i],
              onFrontChanged: (v) => _updateCard(i, front: v),
              onBackChanged: (v) => _updateCard(i, back: v),
              onRemove: _cards.length > 1 ? () => _removeCard(i) : null,
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addCard,
            icon: const Icon(Icons.add),
            label: const Text('Add Card'),
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

// Inline editor for a single flashcard (front + back fields).
class _CardEditor extends StatefulWidget {
  const _CardEditor({
    required this.index,
    required this.card,
    required this.onFrontChanged,
    required this.onBackChanged,
    this.onRemove,
  });

  final int index;
  final Flashcard card;
  final ValueChanged<String> onFrontChanged;
  final ValueChanged<String> onBackChanged;
  final VoidCallback? onRemove;

  @override
  State<_CardEditor> createState() => _CardEditorState();
}

class _CardEditorState extends State<_CardEditor> {
  late final TextEditingController _frontCtrl;
  late final TextEditingController _backCtrl;

  @override
  void initState() {
    super.initState();
    _frontCtrl = TextEditingController(text: widget.card.front);
    _backCtrl = TextEditingController(text: widget.card.back);
    _frontCtrl.addListener(() => widget.onFrontChanged(_frontCtrl.text));
    _backCtrl.addListener(() => widget.onBackChanged(_backCtrl.text));
  }

  @override
  void dispose() {
    _frontCtrl.dispose();
    _backCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
            child: Row(
              children: [
                Text(
                  'Card ${widget.index + 1}',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _frontCtrl,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.text,
                decoration: TextDecoration.none,
              ),
              decoration: InputDecoration(
                hintText: 'Front (question or term)…',
                prefixText: 'Q  ',
                prefixStyle: TextStyle(
                  color: theme.primary,
                  fontWeight: FontWeight.w900,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintStyle: TextStyle(color: theme.muted),
              ),
            ),
          ),
          Divider(color: theme.primary.withValues(alpha: 0.08), height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: TextField(
              controller: _backCtrl,
              style: TextStyle(
                fontSize: 14,
                color: theme.text,
                decoration: TextDecoration.none,
              ),
              decoration: InputDecoration(
                hintText: 'Back (answer or definition)…',
                prefixText: 'A  ',
                prefixStyle: TextStyle(
                  color: theme.accent,
                  fontWeight: FontWeight.w900,
                ),
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
        ],
      ),
    );
  }
}

// Review mode — flip cards one by one with a tap-to-reveal animation.
class _FlashcardReviewScreen extends StatefulWidget {
  const _FlashcardReviewScreen({required this.cards});
  final List<Flashcard> cards;

  @override
  State<_FlashcardReviewScreen> createState() => _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends State<_FlashcardReviewScreen>
    with SingleTickerProviderStateMixin {
  late List<Flashcard> _deck;
  int _index = 0;
  bool _showBack = false;
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _deck = [...widget.cards]..shuffle(Random());
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _flipAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  // Flips the current card to reveal the back.
  void _flip() {
    if (_showBack) return;
    setState(() => _showBack = true);
    _flipCtrl.forward();
  }

  // Advances to the next card, resetting the flip state.
  void _next() {
    if (_index < _deck.length - 1) {
      setState(() {
        _index++;
        _showBack = false;
      });
      _flipCtrl.reset();
    }
  }

  // Goes back to the previous card.
  void _prev() {
    if (_index > 0) {
      setState(() {
        _index--;
        _showBack = false;
      });
      _flipCtrl.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = StudyNestScope.watch(context).selectedTheme;
    final card = _deck[_index];
    final isLast = _index == _deck.length - 1;

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
          '${_index + 1} / ${_deck.length}',
          style: TextStyle(color: theme.muted, fontSize: 14),
        ),
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (_index + 1) / _deck.length,
            backgroundColor: theme.primary.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
          ),
          const Spacer(),
          // Flip card
          GestureDetector(
            onTap: _flip,
            child: AnimatedBuilder(
              animation: _flipAnim,
              builder: (_, animation) {
                final angle = _flipAnim.value * pi;
                final showFront = angle < pi / 2;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(angle),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 28),
                    padding: const EdgeInsets.all(28),
                    constraints: const BoxConstraints(minHeight: 220),
                    decoration: BoxDecoration(
                      color: showFront
                          ? theme.surface
                          : const Color(0xFF2A1F08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.primary.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(showFront ? 0 : pi),
                        child: Text(
                          showFront ? card.front : card.back,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: theme.text,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (!_showBack) ...[
            const SizedBox(height: 16),
            Text(
              'Tap to reveal',
              style: TextStyle(color: theme.muted, fontSize: 13),
            ),
          ],
          const Spacer(),
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _index > 0 ? _prev : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.primary,
                      side: BorderSide(
                        color: theme.primary.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('← Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _showBack
                        ? (isLast ? () => Navigator.of(context).pop() : _next)
                        : _flip,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primary,
                      foregroundColor: theme.background,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _showBack ? (isLast ? 'Done ✓' : 'Next →') : 'Reveal',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
