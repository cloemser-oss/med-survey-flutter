/// 患者基本情報モデル
/// 
/// 複数の問診票に共通で使用される患者の基本情報を管理します。
class PatientInfo {
  final String patientId; // 患者ID
  final String name; // 氏名
  final double weight; // 体重（kg）
  final DateTime? dateOfBirth; // 生年月日
  final Map<String, String> customFields; // 自由記載項目

  PatientInfo({
    required this.patientId,
    required this.name,
    required this.weight,
    this.dateOfBirth,
    this.customFields = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'name': name,
      'weight': weight,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'customFields': customFields,
    };
  }

  factory PatientInfo.fromMap(Map<String, dynamic> map) {
    return PatientInfo(
      patientId: map['patientId'] as String,
      name: map['name'] as String,
      weight: (map['weight'] as num).toDouble(),
      dateOfBirth: map['dateOfBirth'] != null 
          ? DateTime.parse(map['dateOfBirth'] as String)
          : null,
      customFields: map['customFields'] != null
          ? Map<String, String>.from(map['customFields'] as Map)
          : {},
    );
  }

  // Firestore用
  Map<String, dynamic> toFirestore() {
    return {
      'patientId': patientId,
      'name': name,
      'weight': weight,
      'dateOfBirth': dateOfBirth,
      'customFields': customFields,
    };
  }

  factory PatientInfo.fromFirestore(Map<String, dynamic> data) {
    return PatientInfo(
      patientId: data['patientId'] as String,
      name: data['name'] as String,
      weight: (data['weight'] as num).toDouble(),
      dateOfBirth: data['dateOfBirth'] != null
          ? (data['dateOfBirth'] as dynamic).toDate() as DateTime
          : null,
      customFields: data['customFields'] != null
          ? Map<String, String>.from(data['customFields'] as Map)
          : {},
    );
  }

  @override
  String toString() {
    return 'PatientInfo(patientId: $patientId, name: $name, weight: $weight kg, dateOfBirth: $dateOfBirth)';
  }
}
