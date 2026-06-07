import 'dart:convert';

import 'package:flutter/material.dart';

// ─── Study Guide ────────────────────────────────────────────────────────────

class StudyGuideContent {
  const StudyGuideContent({required this.sections});
  final List<StudyGuideSection> sections;

  // Encodes the content to a JSON string for storage in StudyNote.contentJson.
  String toJson() => jsonEncode({
        'sections': sections.map((s) => s.toMap()).toList(),
      });

  // Decodes a StudyGuideContent from a JSON string.
  factory StudyGuideContent.fromJson(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    return StudyGuideContent(
      sections: (map['sections'] as List<dynamic>? ?? [])
          .map((s) => StudyGuideSection.fromMap(s as Map<String, dynamic>))
          .toList(),
    );
  }

  // Returns an empty study guide with one blank section.
  factory StudyGuideContent.empty() =>
      const StudyGuideContent(sections: []);
}

class StudyGuideSection {
  const StudyGuideSection({
    required this.title,
    required this.notes,
    required this.keyTerms,
  });

  final String title;
  final String notes;
  final List<KeyTerm> keyTerms;

  // Converts this section to a JSON-safe map.
  Map<String, dynamic> toMap() => {
        'title': title,
        'notes': notes,
        'keyTerms': keyTerms.map((k) => k.toMap()).toList(),
      };

  // Rebuilds a section from a JSON-safe map.
  factory StudyGuideSection.fromMap(Map<String, dynamic> map) =>
      StudyGuideSection(
        title: map['title'] as String? ?? '',
        notes: map['notes'] as String? ?? '',
        keyTerms: (map['keyTerms'] as List<dynamic>? ?? [])
            .map((k) => KeyTerm.fromMap(k as Map<String, dynamic>))
            .toList(),
      );

  // Returns an empty section.
  factory StudyGuideSection.blank() =>
      const StudyGuideSection(title: '', notes: '', keyTerms: []);

  // Creates a copy with replaced fields.
  StudyGuideSection copyWith({String? title, String? notes, List<KeyTerm>? keyTerms}) =>
      StudyGuideSection(
        title: title ?? this.title,
        notes: notes ?? this.notes,
        keyTerms: keyTerms ?? this.keyTerms,
      );
}

class KeyTerm {
  const KeyTerm({required this.term, required this.definition});
  final String term;
  final String definition;

  // Converts this key term to a JSON-safe map.
  Map<String, dynamic> toMap() => {'term': term, 'definition': definition};

  // Rebuilds a key term from a JSON-safe map.
  factory KeyTerm.fromMap(Map<String, dynamic> map) => KeyTerm(
        term: map['term'] as String? ?? '',
        definition: map['definition'] as String? ?? '',
      );

  // Creates a copy with replaced fields.
  KeyTerm copyWith({String? term, String? definition}) =>
      KeyTerm(term: term ?? this.term, definition: definition ?? this.definition);
}

// ─── Flashcards ─────────────────────────────────────────────────────────────

class FlashcardSetContent {
  const FlashcardSetContent({required this.cards});
  final List<Flashcard> cards;

  // Encodes the flashcard set to a JSON string.
  String toJson() => jsonEncode({
        'cards': cards.map((c) => c.toMap()).toList(),
      });

  // Decodes a FlashcardSetContent from a JSON string.
  factory FlashcardSetContent.fromJson(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    return FlashcardSetContent(
      cards: (map['cards'] as List<dynamic>? ?? [])
          .map((c) => Flashcard.fromMap(c as Map<String, dynamic>))
          .toList(),
    );
  }

  // Returns an empty flashcard set.
  factory FlashcardSetContent.empty() =>
      const FlashcardSetContent(cards: []);
}

class Flashcard {
  const Flashcard({required this.front, required this.back});
  final String front;
  final String back;

  // Converts this card to a JSON-safe map.
  Map<String, dynamic> toMap() => {'front': front, 'back': back};

  // Rebuilds a card from a JSON-safe map.
  factory Flashcard.fromMap(Map<String, dynamic> map) => Flashcard(
        front: map['front'] as String? ?? '',
        back: map['back'] as String? ?? '',
      );

  // Creates a copy with replaced fields.
  Flashcard copyWith({String? front, String? back}) =>
      Flashcard(front: front ?? this.front, back: back ?? this.back);
}

// ─── Quiz ────────────────────────────────────────────────────────────────────

class QuizContent {
  const QuizContent({required this.questions});
  final List<QuizQuestion> questions;

  // Encodes the quiz to a JSON string.
  String toJson() => jsonEncode({
        'questions': questions.map((q) => q.toMap()).toList(),
      });

  // Decodes a QuizContent from a JSON string.
  factory QuizContent.fromJson(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    return QuizContent(
      questions: (map['questions'] as List<dynamic>? ?? [])
          .map((q) => QuizQuestion.fromMap(q as Map<String, dynamic>))
          .toList(),
    );
  }

  // Returns an empty quiz.
  factory QuizContent.empty() => const QuizContent(questions: []);
}

class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.choices,
    required this.correctIndex,
  });

  final String question;
  final List<String> choices;
  final int correctIndex;

  // Converts this question to a JSON-safe map.
  Map<String, dynamic> toMap() => {
        'question': question,
        'choices': choices,
        'correctIndex': correctIndex,
      };

  // Rebuilds a question from a JSON-safe map.
  factory QuizQuestion.fromMap(Map<String, dynamic> map) => QuizQuestion(
        question: map['question'] as String? ?? '',
        choices: (map['choices'] as List<dynamic>? ?? []).cast<String>(),
        correctIndex: map['correctIndex'] as int? ?? 0,
      );

  // Creates a copy with replaced fields.
  QuizQuestion copyWith({String? question, List<String>? choices, int? correctIndex}) =>
      QuizQuestion(
        question: question ?? this.question,
        choices: choices ?? this.choices,
        correctIndex: correctIndex ?? this.correctIndex,
      );

  // Returns a blank question with 4 empty choices.
  factory QuizQuestion.blank() => const QuizQuestion(
        question: '',
        choices: ['', '', '', ''],
        correctIndex: 0,
      );
}

// ─── Formula Sheet ───────────────────────────────────────────────────────────

class FormulaSheetContent {
  const FormulaSheetContent({required this.formulas});
  final List<FormulaEntry> formulas;

  // Encodes the formula sheet to a JSON string.
  String toJson() => jsonEncode({
        'formulas': formulas.map((f) => f.toMap()).toList(),
      });

  // Decodes a FormulaSheetContent from a JSON string.
  factory FormulaSheetContent.fromJson(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    return FormulaSheetContent(
      formulas: (map['formulas'] as List<dynamic>? ?? [])
          .map((f) => FormulaEntry.fromMap(f as Map<String, dynamic>))
          .toList(),
    );
  }

  // Returns an empty formula sheet.
  factory FormulaSheetContent.empty() =>
      const FormulaSheetContent(formulas: []);
}

class FormulaEntry {
  const FormulaEntry({
    required this.name,
    required this.formula,
    required this.explanation,
  });

  final String name;
  final String formula;
  final String explanation;

  // Converts this entry to a JSON-safe map.
  Map<String, dynamic> toMap() => {
        'name': name,
        'formula': formula,
        'explanation': explanation,
      };

  // Rebuilds an entry from a JSON-safe map.
  factory FormulaEntry.fromMap(Map<String, dynamic> map) => FormulaEntry(
        name: map['name'] as String? ?? '',
        formula: map['formula'] as String? ?? '',
        explanation: map['explanation'] as String? ?? '',
      );

  // Creates a copy with replaced fields.
  FormulaEntry copyWith({String? name, String? formula, String? explanation}) =>
      FormulaEntry(
        name: name ?? this.name,
        formula: formula ?? this.formula,
        explanation: explanation ?? this.explanation,
      );
}

// ─── Note type constants ─────────────────────────────────────────────────────

class NoteType {
  NoteType._();
  static const note = 'note';
  static const studyGuide = 'studyGuide';
  static const flashcards = 'flashcards';
  static const quiz = 'quiz';
  static const formula = 'formula';

  // Returns all registered note types.
  static const all = [note, studyGuide, flashcards, quiz, formula];

  // Returns the display label for a note type.
  static String label(String type) => switch (type) {
        studyGuide => 'Study Guide',
        flashcards => 'Flashcards',
        quiz => 'Quiz',
        formula => 'Formulas',
        _ => 'Note',
      };

  // Returns the emoji icon for a note type.
  static String emoji(String type) => switch (type) {
        studyGuide => '📖',
        flashcards => '🃏',
        quiz => '❓',
        formula => '🔢',
        _ => '📝',
      };

  // Returns the Material icon for a note type.
  static IconData icon(String type) => switch (type) {
        studyGuide => Icons.menu_book_outlined,
        flashcards => Icons.style_outlined,
        quiz => Icons.quiz_outlined,
        formula => Icons.functions_outlined,
        _ => Icons.note_alt_outlined,
      };
}
