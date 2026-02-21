# Firestore データ構造設計書

## ハイブリッド型システムアーキテクチャ

Med Surveyアプリは、Flutter Webアプリ（UI層）とFirebase（データ層）を分離したハイブリッド型で構築されています。

### メリット

1. **即座の修正対応**: 問診項目や表示内容をFirestoreで管理することで、iOS再申請なしで変更可能
2. **リアルタイム同期**: 管理者の変更が患者側に即座に反映
3. **スケーラビリティ**: クラウドベースで自動スケール
4. **データ永続化**: ローカルストレージではなくクラウドに保存

---

## コレクション構造

### 1. facilities (施設情報)

**パス**: `/facilities/{facilityId}`

```json
{
  "id": "facility_1234567890",
  "name": "○○総合病院",
  "facilityCode": "AB12CD",
  "address": "東京都渋谷区...",
  "phone": "03-1234-5678",
  "adminEmail": "admin@hospital.com",
  "advertisement": {
    "isEnabled": true,
    "text": "次回の検診予約はこちら",
    "imageUrl": "https://...",
    "linkUrl": "https://..."
  },
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-15T12:30:00Z"
}
```

**インデックス**:
- `facilityCode` (一意性制約)
- `adminEmail`
- `createdAt`

---

### 2. questionnaires (問診票)

**パス**: `/questionnaires/{questionnaireId}`

```json
{
  "id": "mri_template_1234567890",
  "facilityId": "facility_1234567890",
  "title": "MRI検査前問診",
  "description": "MRI検査を安全に実施するための確認事項です。",
  "sections": [
    {
      "id": "section_basic",
      "title": "患者基本情報",
      "description": "基本的な情報をご入力ください",
      "order": 1,
      "questions": [
        {
          "id": "q_patient_id",
          "question": "患者ID",
          "type": "freeText",
          "isRequired": false,
          "order": 1
        },
        {
          "id": "q_weight",
          "question": "現在の体重（kg）",
          "type": "freeText",
          "isRequired": false,
          "order": 2
        },
        {
          "id": "q_mri_experience",
          "question": "MRI検査の経験はありますか",
          "type": "yesNo",
          "isRequired": true,
          "showDetailOnYes": true,
          "order": 3
        }
      ]
    }
  ],
  "isActive": true,
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-15T12:30:00Z",
  "version": 2
}
```

**インデックス**:
- `facilityId`
- `isActive`
- `updatedAt`

**クエリ例**:
```dart
// 施設の有効な問診票を取得
questionnaires
  .where('facilityId', isEqualTo: facilityId)
  .where('isActive', isEqualTo: true)
  .orderBy('updatedAt', descending: true)
```

---

### 3. patient_responses (患者回答)

**パス**: `/patient_responses/{responseId}`

```json
{
  "id": "response_1234567890",
  "questionnaireId": "mri_template_1234567890",
  "facilityId": "facility_1234567890",
  "patientName": "山田太郎",
  "birthDate": "1980-05-15",
  "gender": "男性",
  "appointmentDate": "2024-02-01",
  "answers": {
    "q_patient_id": {
      "questionId": "q_patient_id",
      "value": "P123456"
    },
    "q_weight": {
      "questionId": "q_weight",
      "value": "70"
    },
    "q_mri_experience": {
      "questionId": "q_mri_experience",
      "value": "yes",
      "detail": "3回受けたことがあります"
    }
  },
  "hasAgreed": true,
  "submittedAt": "2024-01-20T10:30:00Z"
}
```

**インデックス**:
- `facilityId` + `submittedAt`
- `questionnaireId`
- `patientName`
- `appointmentDate`

**クエリ例**:
```dart
// 施設の回答を日付でソート
patient_responses
  .where('facilityId', isEqualTo: facilityId)
  .orderBy('submittedAt', descending: true)
```

---

### 4. credentials (認証情報)

**パス**: `/credentials/{email}`

```json
{
  "email": "admin@hospital.com",
  "passwordHash": "hashed_password",
  "facilityId": "facility_1234567890",
  "role": "admin",
  "lastLoginAt": "2024-01-20T09:00:00Z",
  "createdAt": "2024-01-01T00:00:00Z"
}
```

**セキュリティルール**:
```javascript
match /credentials/{email} {
  allow read, write: if request.auth != null && request.auth.token.email == email;
}
```

---

### 5. app_settings (アプリ設定)

**パス**: `/app_settings/global`

```json
{
  "maintenanceMode": false,
  "superAdminPassword": "hashed_password",
  "version": "1.0.0",
  "updatedAt": "2024-01-20T12:00:00Z"
}
```

---

## セキュリティルール

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // 施設情報: 認証済みユーザーのみ読み取り可、自施設のみ更新可
    match /facilities/{facilityId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                     request.auth.token.facilityId == facilityId;
    }
    
    // 問診票: 認証済みユーザーのみ読み取り可、自施設のみ更新可
    match /questionnaires/{questionnaireId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                     resource.data.facilityId == request.auth.token.facilityId;
    }
    
    // 患者回答: 誰でも作成可、自施設のみ読み取り・更新可
    match /patient_responses/{responseId} {
      allow create: if true;
      allow read, update, delete: if request.auth != null && 
                                    resource.data.facilityId == request.auth.token.facilityId;
    }
    
    // 認証情報: 本人のみアクセス可
    match /credentials/{email} {
      allow read, write: if request.auth != null && 
                           request.auth.token.email == email;
    }
    
    // アプリ設定: スーパー管理者のみアクセス可
    match /app_settings/{document=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                     request.auth.token.role == 'super_admin';
    }
  }
}
```

---

## リアルタイム更新の仕組み

### 問診票の自動同期

管理者が問診票を更新すると、Firestoreの`onSnapshot`リスナーが変更を検知し、患者側の画面に自動反映されます。

```dart
// 問診票のリアルタイム監視
FirebaseFirestore.instance
  .collection('questionnaires')
  .doc(questionnaireId)
  .snapshots()
  .listen((snapshot) {
    if (snapshot.exists) {
      setState(() {
        _questionnaire = Questionnaire.fromFirestore(snapshot.data()!);
      });
    }
  });
```

### 広告のリアルタイム更新

スーパー管理者が広告設定を変更すると、患者側の画面に即座に反映されます。

```dart
// 施設情報（広告含む）のリアルタイム監視
FirebaseFirestore.instance
  .collection('facilities')
  .doc(facilityId)
  .snapshots()
  .listen((snapshot) {
    if (snapshot.exists) {
      setState(() {
        _facility = Facility.fromFirestore(snapshot.data()!);
      });
    }
  });
```

---

## オフライン対応

Firestoreのオフライン永続化機能を有効化することで、ネットワークが不安定な環境でも動作します。

```dart
// main.dartで設定
FirebaseFirestore.instance.settings = Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

**動作:**
1. オンライン時にデータをキャッシュ
2. オフライン時はキャッシュから読み取り
3. オンライン復帰時に自動同期

---

## 移行戦略

### フェーズ1: Firebase統合準備
- Firebase設定ファイル追加
- Firestore Database作成
- セキュリティルール設定

### フェーズ2: データモデル拡張
- `fromFirestore` / `toFirestore` メソッド追加
- バリデーション強化

### フェーズ3: サービス層実装
- `FirebaseStorageService` 作成
- CRUD操作実装
- エラーハンドリング

### フェーズ4: UI層統合
- LocalStorageService → FirebaseStorageService に切り替え
- リアルタイム更新機能追加
- ローディング状態管理

### フェーズ5: テスト・最適化
- 単体テスト
- 統合テスト
- パフォーマンス最適化

---

## 修正可能範囲まとめ

### ✅ iOS再申請不要で変更可能

1. **問診票の内容変更**
   - 質問項目の追加・削除・修正
   - セクションの並び替え
   - 必須/任意の変更

2. **表示文言の変更**
   - ボタンラベル
   - メッセージ
   - エラーテキスト

3. **広告の変更**
   - 広告テキスト
   - 画像URL
   - リンク先URL
   - 表示/非表示

4. **施設情報の変更**
   - 施設名
   - 住所
   - 電話番号

5. **UI表示ロジック**
   - レイアウト調整
   - 色・フォント
   - アニメーション

### ❌ iOS再申請が必要な変更

1. アプリアイコン変更
2. アプリ名変更
3. 新しいネイティブ権限追加
4. アプリの基本機能の大幅変更

---

## 結論

このハイブリッド型アーキテクチャにより、**医療現場で求められる柔軟な運用**が可能になります。問診内容の変更や広告の差し替えなど、日常的な修正をiOS再申請なしで即座に行えます。
