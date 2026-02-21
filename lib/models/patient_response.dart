/// 患者回答モデル
class PatientResponse {
  final String id;
  final String questionnaireId;
  final String facilityId;
  final String patientId; // 患者ID (必須)
  final String patientName; // 氏名 (必須)
  final double weight; // 体重 (必須)
  final DateTime? dateOfBirth; // 生年月日 (任意)
  final Map<String, Answer> answers; // 問診項目IDごとの回答
  final bool hasAgreed; // 同意チェック
  final DateTime submittedAt;
  final bool isConfirmed; // 管理者による確認済みフラグ
  final String? staffMemo; // 医療従事者メモ

  PatientResponse({
    required this.id,
    required this.questionnaireId,
    required this.facilityId,
    required this.patientId,
    required this.patientName,
    required this.weight,
    this.dateOfBirth,
    required this.answers,
    required this.hasAgreed,
    required this.submittedAt,
    this.isConfirmed = false,
    this.staffMemo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionnaireId': questionnaireId,
      'facilityId': facilityId,
      'patientId': patientId,
      'patientName': patientName,
      'weight': weight,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'answers': answers.map((key, value) => MapEntry(key, value.toMap())),
      'hasAgreed': hasAgreed,
      'submittedAt': submittedAt.toIso8601String(),
      'isConfirmed': isConfirmed,
      'staffMemo': staffMemo,
    };
  }

  factory PatientResponse.fromMap(Map<String, dynamic> map) {
    return PatientResponse(
      id: map['id'] as String,
      questionnaireId: map['questionnaireId'] as String,
      facilityId: map['facilityId'] as String,
      patientId: map['patientId'] as String,
      patientName: map['patientName'] as String,
      weight: (map['weight'] as num).toDouble(),
      dateOfBirth: map['dateOfBirth'] != null 
          ? DateTime.parse(map['dateOfBirth'] as String)
          : null,
      answers: (map['answers'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          Answer.fromMap(value as Map<String, dynamic>),
        ),
      ),
      hasAgreed: map['hasAgreed'] as bool,
      submittedAt: DateTime.parse(map['submittedAt'] as String),
      isConfirmed: map['isConfirmed'] as bool? ?? false,
      staffMemo: map['staffMemo'] as String?,
    );
  }

  // Firestore用: Timestampに対応
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'questionnaireId': questionnaireId,
      'facilityId': facilityId,
      'patientId': patientId,
      'patientName': patientName,
      'weight': weight,
      'dateOfBirth': dateOfBirth,
      'answers': answers.map((key, value) => MapEntry(key, value.toMap())),
      'hasAgreed': hasAgreed,
      'submittedAt': submittedAt,
      'isConfirmed': isConfirmed,
      'staffMemo': staffMemo,
    };
  }

  // Firestore用: Timestampから変換
  factory PatientResponse.fromFirestore(Map<String, dynamic> data) {
    return PatientResponse(
      id: data['id'] as String,
      questionnaireId: data['questionnaireId'] as String,
      facilityId: data['facilityId'] as String,
      patientId: data['patientId'] as String,
      patientName: data['patientName'] as String,
      weight: (data['weight'] as num).toDouble(),
      dateOfBirth: data['dateOfBirth'] != null 
          ? _timestampToDateTime(data['dateOfBirth'])
          : null,
      answers: (data['answers'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          Answer.fromMap(value as Map<String, dynamic>),
        ),
      ),
      hasAgreed: data['hasAgreed'] as bool? ?? false,
      submittedAt: _timestampToDateTime(data['submittedAt']),
      isConfirmed: data['isConfirmed'] as bool? ?? false,
      staffMemo: data['staffMemo'] as String?,
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

  /// Yes回答がある項目のリストを取得
  List<String> getYesAnswers() {
    return answers.entries
        .where((entry) => entry.value.value == 'yes')
        .map((entry) => entry.key)
        .toList();
  }
}

/// 回答
class Answer {
  final String questionId;
  final String value; // "yes", "no", 選択肢、または自由記述
  final String? detail; // 詳細記載

  Answer({
    required this.questionId,
    required this.value,
    this.detail,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'value': value,
      'detail': detail,
    };
  }

  factory Answer.fromMap(Map<String, dynamic> map) {
    return Answer(
      questionId: map['questionId'] as String,
      value: map['value'] as String,
      detail: map['detail'] as String?,
    );
  }
}
