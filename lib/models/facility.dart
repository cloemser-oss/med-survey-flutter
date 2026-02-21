/// 医療機関モデル
class Facility {
  final String id;
  final String name;
  final String facilityCode; // 患者アクセス用の施設コード (例: A1B2C3)
  final String? address;
  final String? phone;
  final String adminEmail; // 管理者メールアドレス
  final Advertisement? advertisement;
  final DateTime createdAt;

  Facility({
    required this.id,
    required this.name,
    required this.facilityCode,
    this.address,
    this.phone,
    required this.adminEmail,
    this.advertisement,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'facilityCode': facilityCode,
      'address': address,
      'phone': phone,
      'adminEmail': adminEmail,
      'advertisement': advertisement?.toMap(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Facility.fromMap(Map<String, dynamic> map) {
    return Facility(
      id: map['id'] as String,
      name: map['name'] as String,
      facilityCode: map['facilityCode'] as String,
      address: map['address'] as String?,
      phone: map['phone'] as String?,
      adminEmail: map['adminEmail'] as String,
      advertisement: map['advertisement'] != null
          ? Advertisement.fromMap(map['advertisement'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  // Firestore用: Timestampに対応
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'facilityCode': facilityCode,
      'address': address,
      'phone': phone,
      'adminEmail': adminEmail,
      'advertisement': advertisement?.toMap(),
      'createdAt': createdAt,
      'updatedAt': DateTime.now(),
    };
  }

  // Firestore用: Timestampから変換
  factory Facility.fromFirestore(Map<String, dynamic> data) {
    return Facility(
      id: data['id'] as String,
      name: data['name'] as String,
      facilityCode: data['facilityCode'] as String,
      address: data['address'] as String?,
      phone: data['phone'] as String?,
      adminEmail: data['adminEmail'] as String,
      advertisement: data['advertisement'] != null
          ? Advertisement.fromMap(data['advertisement'] as Map<String, dynamic>)
          : null,
      createdAt: _timestampToDateTime(data['createdAt']),
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

/// 広告表示
class Advertisement {
  final bool isEnabled;
  final String? text;
  final String? imageUrl;
  final String? linkUrl;

  Advertisement({
    required this.isEnabled,
    this.text,
    this.imageUrl,
    this.linkUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'isEnabled': isEnabled,
      'text': text,
      'imageUrl': imageUrl,
      'linkUrl': linkUrl,
    };
  }

  factory Advertisement.fromMap(Map<String, dynamic> map) {
    return Advertisement(
      isEnabled: map['isEnabled'] as bool,
      text: map['text'] as String?,
      imageUrl: map['imageUrl'] as String?,
      linkUrl: map['linkUrl'] as String?,
    );
  }
}
