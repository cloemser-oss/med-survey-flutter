/// 患者基本情報設定モデル
class PatientBasicInfoConfig {
  final String facilityId;
  final bool includePatientId;
  final bool includePatientName;
  final bool includeDateOfBirth;
  final bool includeWeight;
  final List<CustomField> customFields; // 自由記載項目

  PatientBasicInfoConfig({
    required this.facilityId,
    this.includePatientId = true,
    this.includePatientName = true,
    this.includeDateOfBirth = false,
    this.includeWeight = true,
    this.customFields = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'facilityId': facilityId,
      'includePatientId': includePatientId,
      'includePatientName': includePatientName,
      'includeDateOfBirth': includeDateOfBirth,
      'includeWeight': includeWeight,
      'customFields': customFields.map((f) => f.toMap()).toList(),
    };
  }

  factory PatientBasicInfoConfig.fromMap(Map<String, dynamic> map) {
    return PatientBasicInfoConfig(
      facilityId: map['facilityId'] as String,
      includePatientId: map['includePatientId'] as bool? ?? true,
      includePatientName: map['includePatientName'] as bool? ?? true,
      includeDateOfBirth: map['includeDateOfBirth'] as bool? ?? false,
      includeWeight: map['includeWeight'] as bool? ?? true,
      customFields: (map['customFields'] as List<dynamic>?)
              ?.map((f) => CustomField.fromMap(f as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  // デフォルト設定を作成
  factory PatientBasicInfoConfig.defaultConfig(String facilityId) {
    return PatientBasicInfoConfig(
      facilityId: facilityId,
      includePatientId: true,
      includePatientName: true,
      includeDateOfBirth: true, // 固定項目：常にtrue
      includeWeight: true,
      customFields: [],
    );
  }
}

/// 自由記載項目
class CustomField {
  final String id;
  final String label;
  final String fieldType; // 'text', 'number', 'date', 'textarea'
  final bool isRequired;
  final bool isEnabled; // ON/OFF状態

  CustomField({
    required this.id,
    required this.label,
    this.fieldType = 'text',
    this.isRequired = false,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'fieldType': fieldType,
      'isRequired': isRequired,
      'isEnabled': isEnabled,
    };
  }

  factory CustomField.fromMap(Map<String, dynamic> map) {
    return CustomField(
      id: map['id'] as String,
      label: map['label'] as String,
      fieldType: map['fieldType'] as String? ?? 'text',
      isRequired: map['isRequired'] as bool? ?? false,
      isEnabled: map['isEnabled'] as bool? ?? true,
    );
  }
}
