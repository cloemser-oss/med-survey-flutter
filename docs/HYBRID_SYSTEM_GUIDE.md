# ハイブリッド型システム実装ガイド

Med Surveyアプリは、パターン③「ハイブリッド型」アーキテクチャで構築されています。

## 🎯 システム概要

```
┌──────────────────────────────────────────┐
│  iOSアプリ (WKWebView)                   │
│  ┌────────────────────────────────────┐ │
│  │  Flutter Web App (UI層)            │ │
│  │  - Gemsparkで即座に修正可能        │ │
│  │  - iOS再申請不要                   │ │
│  └────────────────────────────────────┘ │
└──────────────────────────────────────────┘
              ↕ (リアルタイム同期)
┌──────────────────────────────────────────┐
│  Firebase Backend (データ層)             │
│  ┌────────────────────────────────────┐ │
│  │  Firestore Database                │ │
│  │  - 問診票データ                    │ │
│  │  - 患者回答データ                  │ │
│  │  - 施設情報・広告設定              │ │
│  └────────────────────────────────────┘ │
└──────────────────────────────────────────┘
```

## ✅ iOS再申請なしで修正可能な項目

1. **問診票の内容**
   - 質問項目の追加・削除・修正
   - セクションの並び替え
   - 必須/任意の変更

2. **広告の表示・内容**
   - 広告テキスト
   - 画像URL
   - リンク先URL
   - 表示/非表示

3. **UI表示文言**
   - ボタンラベル
   - メッセージ
   - エラーテキスト

4. **表示ロジック**
   - レイアウト調整
   - 色・フォント
   - アニメーション

## 🔧 実装済み機能

### 1. データモデルのFirestore対応

すべてのデータモデルに `fromFirestore()` と `toFirestore()` メソッドを追加しました。

**対応モデル:**
- `Questionnaire` (問診票)
- `Facility` (施設情報)
- `PatientResponse` (患者回答)

**使用例:**
```dart
// Firestoreへの保存
await FirebaseFirestore.instance
  .collection('questionnaires')
  .doc(questionnaire.id)
  .set(questionnaire.toFirestore());

// Firestoreからの読み込み
final snapshot = await FirebaseFirestore.instance
  .collection('questionnaires')
  .doc(questionnaireId)
  .get();
final questionnaire = Questionnaire.fromFirestore(snapshot.data()!);
```

### 2. FirebaseStorageService

Firestoreを使用したストレージサービスを実装しました。

**主な機能:**
- 施設登録・取得・更新
- 問診票のCRUD操作
- 患者回答の保存・取得
- リアルタイム監視（Stream対応）

**ファイル:** `lib/services/firebase_storage_service.dart`

### 3. StorageManager (ハイブリッド切り替え)

Firebase/LocalStorageを自動切り替えするマネージャーを実装しました。

**動作:**
- Firebase設定がある場合: `FirebaseStorageService` を使用
- Firebase設定がない場合: `LocalStorageService` を使用（デモモード）

**ファイル:** `lib/services/storage_manager.dart`

## 📋 Firebase設定手順

### ステップ1: Firebase設定ファイルの追加

Firebase Consoleから以下のファイルを取得して配置してください:

1. **Android用:**
   - `google-services.json` → `android/app/google-services.json`

2. **Web用:**
   - Firebase Console → Project Settings → General → Web apps
   - `firebase_options.dart` を生成

3. **Firebase Admin SDK (バックエンド用):**
   - Firebase Console → Project Settings → Service accounts
   - `firebase-admin-sdk.json` → `/opt/flutter/firebase-admin-sdk.json`

### ステップ2: Firestore Database作成

1. Firebase Console → Build → Firestore Database
2. 「Create Database」をクリック
3. Production mode または Test mode を選択
4. ロケーションを選択（asia-northeast1 推奨）

### ステップ3: セキュリティルール設定

Firestore Databaseのセキュリティルールを以下のように設定します:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // 施設情報
    match /facilities/{facilityId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                     request.auth.token.facilityId == facilityId;
    }
    
    // 問診票
    match /questionnaires/{questionnaireId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                     resource.data.facilityId == request.auth.token.facilityId;
    }
    
    // 患者回答
    match /patient_responses/{responseId} {
      allow create: if true;
      allow read, update, delete: if request.auth != null && 
                                    resource.data.facilityId == request.auth.token.facilityId;
    }
    
    // 認証情報
    match /credentials/{email} {
      allow read, write: if request.auth != null && 
                           request.auth.token.email == email;
    }
  }
}
```

### ステップ4: Firebaseストレージへの切り替え

Firebase設定が完了したら、アプリは自動的にFirebaseStorageServiceを使用します。

**確認方法:**
```dart
final manager = StorageManager();
print('Firebase使用中: ${manager.isUsingFirebase}');
// true: Firebaseを使用
// false: ローカルストレージを使用（デモモード）
```

## 🔄 リアルタイム更新の仕組み

管理者が問診票を更新すると、患者側の画面に即座に反映されます。

### 実装例: 問診票のリアルタイム監視

```dart
StreamBuilder<List<Questionnaire>>(
  stream: FirebaseStorageService().watchQuestionnaires(facilityId),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final questionnaires = snapshot.data!;
      return QuestionnaireList(questionnaires);
    }
    return CircularProgressIndicator();
  },
);
```

### 実装例: 施設情報（広告）のリアルタイム監視

```dart
StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance
    .collection('facilities')
    .doc(facilityId)
    .snapshots(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final facility = Facility.fromFirestore(snapshot.data!.data()!);
      return AdvertisementWidget(facility.advertisement);
    }
    return SizedBox();
  },
);
```

## 📊 データ構造

詳細なデータ構造は `docs/FIREBASE_STRUCTURE.md` を参照してください。

### コレクション一覧

1. **facilities** - 施設情報
2. **questionnaires** - 問診票
3. **patient_responses** - 患者回答
4. **credentials** - 認証情報

## 🔒 オフライン対応

Firestoreのオフライン永続化機能を有効化することで、ネットワークが不安定な環境でも動作します。

**設定方法 (`lib/main.dart`):**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // オフライン永続化を有効化
  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(MyApp());
}
```

**動作:**
1. オンライン時にデータをキャッシュ
2. オフライン時はキャッシュから読み取り
3. オンライン復帰時に自動同期

## 🚀 デプロイフロー

### 開発フロー（即座に反映）

1. **問診票の内容変更**
   ```
   Firebase Console → Firestore Database
   → questionnaires コレクション
   → 該当ドキュメント編集
   → 保存
   ```
   → **即座に患者側に反映（iOS再申請不要）**

2. **広告の変更**
   ```
   Firebase Console → Firestore Database
   → facilities コレクション
   → 該当施設の advertisement フィールド編集
   → 保存
   ```
   → **即座に反映（iOS再申請不要）**

3. **UIの文言変更**
   ```
   Gemsparkでコード修正
   → Flutter build web
   → デプロイ
   ```
   → **即座に反映（iOS再申請不要）**

### iOS再申請が必要な変更

以下の変更を行う場合のみ、iOS再申請が必要です:

1. アプリアイコン変更
2. アプリ名変更
3. 新しいネイティブ権限の追加
4. アプリの基本機能の大幅変更

## 📈 運用メリット

### 1. 迅速な対応

問診内容の変更や広告の差し替えを、iOS審査を待たずに即座に実施できます。

**例: 緊急の問診項目追加**
```
1. Firebase Consoleで問診票を編集 (5分)
2. 保存 → 即座に全ユーザーに反映
```

従来: アプリ修正 → 審査待ち (数日〜数週間)

### 2. コスト削減

- iOS再申請の手間が大幅に削減
- 開発者の工数削減
- ユーザーへの影響最小化

### 3. 柔軟な運用

- A/Bテストの実施
- 季節ごとの広告変更
- 医療ガイドライン改定への迅速な対応

## 🔍 デバッグ・トラブルシューティング

### Firebase接続確認

```dart
void checkFirebaseConnection() async {
  try {
    await FirebaseFirestore.instance
      .collection('facilities')
      .limit(1)
      .get();
    print('✅ Firebase接続成功');
  } catch (e) {
    print('❌ Firebase接続失敗: $e');
  }
}
```

### ストレージモード確認

```dart
final manager = StorageManager();
if (manager.isUsingFirebase) {
  print('✅ Firebaseモード');
} else {
  print('⚠️ ローカルストレージモード（デモ）');
}
```

### デバッグログの確認

ブラウザのコンソール（F12キー）で以下のログを確認できます:

- `💾` 保存操作
- `📖` 読み込み操作
- `✅` 成功
- `⚠️` 警告
- `❌` エラー

## 📚 参考資料

- [Firebase Documentation](https://firebase.google.com/docs)
- [Firestore Security Rules](https://firebase.google.com/docs/firestore/security/get-started)
- [Flutter Firebase](https://firebase.flutter.dev/)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)

---

**次のステップ:** Firebase設定ファイルを追加して、ハイブリッド型システムを有効化してください。
