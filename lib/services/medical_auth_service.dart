import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firebase認証サービス（医療アプリ向け）
/// 
/// カスタムクレームを使用した厳格なアクセス制御を実装
class MedicalAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 現在のユーザー
  User? get currentUser => _auth.currentUser;

  /// 認証状態のストリーム
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // =========================================
  // カスタムクレーム取得
  // =========================================

  /// ユーザーのカスタムクレームを取得
  Future<Map<String, dynamic>> getUserClaims() async {
    final user = currentUser;
    if (user == null) return {};

    // トークンを強制更新してクレームを取得
    final idTokenResult = await user.getIdTokenResult(true);
    return idTokenResult.claims ?? {};
  }

  /// ロールを取得
  Future<String?> getUserRole() async {
    final claims = await getUserClaims();
    return claims['role'] as String?;
  }

  /// 施設IDを取得
  Future<String?> getFacilityId() async {
    final claims = await getUserClaims();
    return claims['facilityId'] as String?;
  }

  /// 患者IDを取得
  Future<String?> getPatientId() async {
    final claims = await getUserClaims();
    return claims['patientId'] as String?;
  }

  /// 医療スタッフかチェック
  Future<bool> isMedicalStaff() async {
    final role = await getUserRole();
    return role == 'medical_staff' || role == 'admin';
  }

  /// 管理者かチェック
  Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == 'admin';
  }

  /// 患者かチェック
  Future<bool> isPatient() async {
    final role = await getUserRole();
    return role == 'patient';
  }

  // =========================================
  // 認証操作
  // =========================================

  /// メールアドレスとパスワードでログイン
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // カスタムクレームを取得して確認
      await _logUserRole(credential.user);

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// 新規ユーザー登録（医療スタッフ用）
  Future<UserCredential> registerMedicalStaff({
    required String email,
    required String password,
    required String facilityId,
    String role = 'medical_staff',
  }) async {
    try {
      // ユーザー作成
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestoreにユーザー情報を保存
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'role': role,
        'facilityId': facilityId,
        'type': 'staff',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // カスタムクレームはサーバー側で設定する必要があります
      // （Cloud FunctionsまたはAdmin SDKを使用）

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// 患者アカウント作成（匿名認証 + カスタムクレーム）
  Future<UserCredential> createPatientAccount({
    required String facilityId,
    required String patientId,
    required String dateOfBirth,
  }) async {
    try {
      // 匿名認証でユーザー作成
      final credential = await _auth.signInAnonymously();

      // Firestoreにユーザー情報を保存
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'role': 'patient',
        'facilityId': facilityId,
        'patientId': patientId,
        'dateOfBirth': dateOfBirth,
        'type': 'patient',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // カスタムクレームはサーバー側で設定する必要があります
      // Cloud Functionsトリガーで自動設定することを推奨

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// ログアウト
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// パスワードリセットメール送信
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // =========================================
  // ヘルパー関数
  // =========================================

  /// ユーザーロールをログ出力
  Future<void> _logUserRole(User? user) async {
    if (user == null) return;

    final claims = await getUserClaims();
    print('🔐 ログイン成功: ${user.email}');
    print('   UID: ${user.uid}');
    print('   Role: ${claims['role']}');
    print('   FacilityID: ${claims['facilityId']}');
    print('   PatientID: ${claims['patientId']}');
  }

  /// Firebase認証エラーハンドリング
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'ユーザーが見つかりません';
      case 'wrong-password':
        return 'パスワードが間違っています';
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています';
      case 'weak-password':
        return 'パスワードが弱すぎます（6文字以上を推奨）';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません';
      case 'user-disabled':
        return 'このアカウントは無効化されています';
      case 'operation-not-allowed':
        return 'この操作は許可されていません';
      default:
        return '認証エラー: ${e.message}';
    }
  }

  // =========================================
  // アクセス権チェック（UI表示制御用）
  // =========================================

  /// 施設データへのアクセス権チェック
  Future<bool> canAccessFacility(String facilityId) async {
    final userFacilityId = await getFacilityId();
    return userFacilityId == facilityId;
  }

  /// 患者データへのアクセス権チェック
  Future<bool> canAccessPatientData({
    required String facilityId,
    required String patientId,
    required String dateOfBirth,
  }) async {
    // 医療スタッフで同じ施設の場合
    if (await isMedicalStaff()) {
      return await canAccessFacility(facilityId);
    }

    // 患者本人の場合
    if (await isPatient()) {
      final userPatientId = await getPatientId();
      final claims = await getUserClaims();
      final userDateOfBirth = claims['dateOfBirth'] as String?;

      return userPatientId == patientId && 
             userDateOfBirth == dateOfBirth;
    }

    return false;
  }
}

// =========================================
// 使用例
// =========================================

/*
void main() async {
  final authService = MedicalAuthService();

  // 1. 医療スタッフログイン
  try {
    await authService.signInWithEmailAndPassword(
      email: 'doctor@hospital.com',
      password: 'secure_password',
    );
    
    // ロール確認
    if (await authService.isMedicalStaff()) {
      print('医療スタッフとしてログイン成功');
      final facilityId = await authService.getFacilityId();
      print('施設ID: $facilityId');
    }
  } catch (e) {
    print('ログインエラー: $e');
  }

  // 2. 患者アカウント作成
  try {
    await authService.createPatientAccount(
      facilityId: 'facility_001',
      patientId: 'P00123',
      dateOfBirth: '1990-01-15T00:00:00.000Z',
    );
    print('患者アカウント作成成功');
  } catch (e) {
    print('患者アカウント作成エラー: $e');
  }

  // 3. データアクセス権チェック
  final canAccess = await authService.canAccessPatientData(
    facilityId: 'facility_001',
    patientId: 'P00123',
    dateOfBirth: '1990-01-15T00:00:00.000Z',
  );
  
  if (canAccess) {
    // 患者データを表示
  } else {
    // アクセス拒否メッセージ表示
  }

  // 4. ログアウト
  await authService.signOut();
}
*/
