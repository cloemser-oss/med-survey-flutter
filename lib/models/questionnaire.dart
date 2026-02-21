/// 問診票モデル
class Questionnaire {
  final String id;
  final String facilityId; // 医療機関ID
  final String title;
  final String description;
  final List<QuestionSection> sections; // セクション(大項目)のリスト
  final DateTime createdAt;
  final DateTime updatedAt;

  Questionnaire({
    required this.id,
    required this.facilityId,
    required this.title,
    required this.description,
    required this.sections,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'facilityId': facilityId,
      'title': title,
      'description': description,
      'sections': sections.map((s) => s.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Questionnaire.fromMap(Map<String, dynamic> map) {
    return Questionnaire(
      id: map['id'] as String,
      facilityId: map['facilityId'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      sections: (map['sections'] as List)
          .map((s) => QuestionSection.fromMap(s as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  // Firestore用: Timestampに対応
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'facilityId': facilityId,
      'title': title,
      'description': description,
      'sections': sections.map((s) => s.toMap()).toList(),
      'isActive': true,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'version': 1,
    };
  }

  // Firestore用: Timestampから変換
  factory Questionnaire.fromFirestore(Map<String, dynamic> data) {
    return Questionnaire(
      id: data['id'] as String,
      facilityId: data['facilityId'] as String,
      title: data['title'] as String,
      description: data['description'] as String? ?? '',
      sections: (data['sections'] as List?)
              ?.map((s) => QuestionSection.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: _timestampToDateTime(data['createdAt']),
      updatedAt: _timestampToDateTime(data['updatedAt']),
    );
  }

  // Timestampを安全にDateTimeに変換
  static DateTime _timestampToDateTime(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();
    if (timestamp is DateTime) return timestamp;
    try {
      return (timestamp as dynamic).toDate() as DateTime;
    } catch (e) {
      return DateTime.now();
    }
  }
}

/// 問診セクション(大項目)
class QuestionSection {
  final String id;
  final String title; // セクションタイトル(例: 患者情報、手術歴など)
  final String? description; // セクションの説明文
  final List<QuestionItem> questions; // このセクションの質問リスト
  final int order; // セクションの表示順序

  QuestionSection({
    required this.id,
    required this.title,
    this.description,
    required this.questions,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toMap()).toList(),
      'order': order,
    };
  }

  factory QuestionSection.fromMap(Map<String, dynamic> map) {
    return QuestionSection(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      questions: (map['questions'] as List)
          .map((q) => QuestionItem.fromMap(q as Map<String, dynamic>))
          .toList(),
      order: map['order'] as int,
    );
  }
}

/// 問診項目
class QuestionItem {
  final String id;
  final String question;
  final QuestionType type;
  final bool isRequired;
  final List<String>? options; // 選択式の場合の選択肢
  final bool showDetailOnYes; // Yes選択時に詳細入力欄を表示
  final String? detailPrompt; // 詳細入力欄のプロンプト(デフォルト: 「詳しく教えてください」)
  final int order;

  QuestionItem({
    required this.id,
    required this.question,
    required this.type,
    required this.isRequired,
    this.options,
    this.showDetailOnYes = false,
    this.detailPrompt,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'type': type.name,
      'isRequired': isRequired,
      'options': options,
      'showDetailOnYes': showDetailOnYes,
      'detailPrompt': detailPrompt,
      'order': order,
    };
  }

  factory QuestionItem.fromMap(Map<String, dynamic> map) {
    return QuestionItem(
      id: map['id'] as String,
      question: map['question'] as String,
      type: QuestionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => QuestionType.yesNo,
      ),
      isRequired: map['isRequired'] as bool,
      options: map['options'] != null
          ? List<String>.from(map['options'] as List)
          : null,
      showDetailOnYes: map['showDetailOnYes'] as bool? ?? false,
      detailPrompt: map['detailPrompt'] as String?,
      order: map['order'] as int,
    );
  }
}

/// 問診タイプ
enum QuestionType {
  yesNo, // Yes/No
  singleChoice, // 単一選択
  multipleChoice, // 複数選択
  freeText, // 自由記載
}
