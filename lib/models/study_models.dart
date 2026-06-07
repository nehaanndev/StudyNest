class StudyTask {
  const StudyTask({
    required this.id,
    required this.title,
    required this.details,
    required this.dueAt,
    required this.reward,
    required this.completedAt,
    required this.rewardCollected,
    this.priority = 'Medium',
  });

  final String id;
  final String title;
  final String details;
  final DateTime dueAt;
  final int reward;
  final DateTime? completedAt;
  final bool rewardCollected;
  final String priority;

  // Converts this task into JSON-safe values for local persistence.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'details': details,
      'dueAt': dueAt.toIso8601String(),
      'reward': reward,
      'completedAt': completedAt?.toIso8601String(),
      'rewardCollected': rewardCollected,
      'priority': priority,
    };
  }

  // Rebuilds a task from JSON-safe values loaded from local persistence.
  factory StudyTask.fromJson(Map<String, dynamic> json) {
    return StudyTask(
      id: json['id'] as String,
      title: json['title'] as String,
      details: json['details'] as String? ?? '',
      dueAt: DateTime.parse(json['dueAt'] as String),
      reward: json['reward'] as int? ?? 10,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      rewardCollected: json['rewardCollected'] as bool? ?? false,
      priority: json['priority'] as String? ?? 'Medium',
    );
  }

  // Creates a task copy while replacing only the fields that changed.
  StudyTask copyWith({
    String? title,
    String? details,
    DateTime? dueAt,
    int? reward,
    DateTime? completedAt,
    bool? clearCompletedAt,
    bool? rewardCollected,
    String? priority,
  }) {
    return StudyTask(
      id: id,
      title: title ?? this.title,
      details: details ?? this.details,
      dueAt: dueAt ?? this.dueAt,
      reward: reward ?? this.reward,
      completedAt: clearCompletedAt == true
          ? null
          : completedAt ?? this.completedAt,
      rewardCollected: rewardCollected ?? this.rewardCollected,
      priority: priority ?? this.priority,
    );
  }
}

class StudyNote {
  const StudyNote({
    required this.id,
    required this.title,
    required this.body,
    required this.colorName,
    required this.tags,
    required this.updatedAt,
    this.folder = '',
    this.createdAt,
    this.noteType = 'note',
    this.contentJson,
  });

  final String id;
  final String title;
  final String body;
  final String colorName;
  final List<String> tags;
  final DateTime updatedAt;
  final String folder;
  final DateTime? createdAt;
  // Type discriminator: 'note' | 'studyGuide' | 'flashcards' | 'quiz' | 'formula'
  final String noteType;
  // JSON-encoded structured content for non-plain-text types.
  final String? contentJson;

  // Converts this note into JSON-safe values for local persistence.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'colorName': colorName,
      'tags': tags,
      'folder': folder,
      'createdAt': (createdAt ?? updatedAt).toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'noteType': noteType,
      if (contentJson != null) 'contentJson': contentJson,
    };
  }

  // Rebuilds a note from JSON-safe values loaded from local persistence.
  factory StudyNote.fromJson(Map<String, dynamic> json) {
    return StudyNote(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String? ?? '',
      colorName: json['colorName'] as String? ?? 'honey',
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((tag) => tag as String)
          .toList(),
      folder: json['folder'] as String? ?? '',
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'] as String),
      noteType: json['noteType'] as String? ?? 'note',
      contentJson: json['contentJson'] as String?,
    );
  }

  // Creates a note copy while replacing only the fields that changed.
  StudyNote copyWith({
    String? title,
    String? body,
    String? colorName,
    List<String>? tags,
    String? folder,
    DateTime? updatedAt,
    String? noteType,
    String? contentJson,
    bool clearContentJson = false,
  }) {
    return StudyNote(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      colorName: colorName ?? this.colorName,
      tags: tags ?? this.tags,
      folder: folder ?? this.folder,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt,
      noteType: noteType ?? this.noteType,
      contentJson: clearContentJson ? null : contentJson ?? this.contentJson,
    );
  }
}

class PlannerEvent {
  const PlannerEvent({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    required this.category,
  });

  final String id;
  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final String category;

  // Converts this planner event into JSON-safe values for local persistence.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startsAt': startsAt.toIso8601String(),
      'endsAt': endsAt.toIso8601String(),
      'category': category,
    };
  }

  // Rebuilds a planner event from JSON-safe values loaded from local persistence.
  factory PlannerEvent.fromJson(Map<String, dynamic> json) {
    return PlannerEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
      category: json['category'] as String? ?? 'Study',
    );
  }

  // Creates an event copy while replacing only changed fields.
  PlannerEvent copyWith({
    String? title,
    DateTime? startsAt,
    DateTime? endsAt,
    String? category,
  }) {
    return PlannerEvent(
      id: id,
      title: title ?? this.title,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      category: category ?? this.category,
    );
  }
}

class CoinTransaction {
  const CoinTransaction({
    required this.id,
    required this.label,
    required this.amount,
    required this.createdAt,
    required this.sourceId,
  });

  final String id;
  final String label;
  final int amount;
  final DateTime createdAt;
  final String sourceId;

  // Converts this coin transaction into JSON-safe values for local persistence.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
      'sourceId': sourceId,
    };
  }

  // Rebuilds a coin transaction from JSON-safe values loaded from persistence.
  factory CoinTransaction.fromJson(Map<String, dynamic> json) {
    return CoinTransaction(
      id: json['id'] as String,
      label: json['label'] as String,
      amount: json['amount'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      sourceId: json['sourceId'] as String? ?? '',
    );
  }
}

class ShopItem {
  const ShopItem({
    required this.id,
    required this.title,
    required this.description,
    required this.cost,
    required this.themeId,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final int cost;
  final String themeId;
  final String icon;

  // Converts this shop item into JSON-safe values for local persistence.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'cost': cost,
      'themeId': themeId,
      'icon': icon,
    };
  }

  // Rebuilds a shop item from JSON-safe values loaded from local persistence.
  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      cost: json['cost'] as int? ?? 100,
      themeId: json['themeId'] as String? ?? 'cozyCafe',
      icon: json['icon'] as String? ?? '☕',
    );
  }
}

class StudySessionGoal {
  const StudySessionGoal({
    required this.title,
    required this.reward,
    required this.completedAt,
    required this.updatedAt,
  });

  final String title;
  final int reward;
  final DateTime? completedAt;
  final DateTime updatedAt;

  // Converts this study session goal into JSON-safe values for persistence.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'reward': reward,
      'completedAt': completedAt?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Rebuilds a study session goal from JSON-safe values loaded from persistence.
  factory StudySessionGoal.fromJson(Map<String, dynamic> json) {
    return StudySessionGoal(
      title: json['title'] as String? ?? 'Finish one focused study block',
      reward: json['reward'] as int? ?? 25,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // Creates a session goal copy while replacing only the fields that changed.
  StudySessionGoal copyWith({
    String? title,
    int? reward,
    DateTime? completedAt,
    bool? clearCompletedAt,
    DateTime? updatedAt,
  }) {
    return StudySessionGoal(
      title: title ?? this.title,
      reward: reward ?? this.reward,
      completedAt: clearCompletedAt == true
          ? null
          : completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Reports whether this goal has already been completed on the provided day.
  bool isCompleteOn(DateTime day) {
    final completed = completedAt;
    if (completed == null) {
      return false;
    }
    return completed.year == day.year &&
        completed.month == day.month &&
        completed.day == day.day;
  }
}

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class StudyHabit {
  const StudyHabit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.streak,
    required this.completions,
  });

  final String id;
  final String name;
  final String emoji;
  final int streak;
  final List<String> completions; // ISO date strings of completed days

  bool isCompletedOn(DateTime day) =>
      completions.any((c) => isSameDay(DateTime.parse(c), day));

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'streak': streak,
        'completions': completions,
      };

  factory StudyHabit.fromJson(Map<String, dynamic> j) => StudyHabit(
        id: j['id'] as String,
        name: j['name'] as String,
        emoji: j['emoji'] as String? ?? '✅',
        streak: j['streak'] as int? ?? 0,
        completions: (j['completions'] as List?)?.cast<String>() ?? [],
      );

  StudyHabit copyWith({
    String? name,
    String? emoji,
    int? streak,
    List<String>? completions,
  }) =>
      StudyHabit(
        id: id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        streak: streak ?? this.streak,
        completions: completions ?? this.completions,
      );
}
