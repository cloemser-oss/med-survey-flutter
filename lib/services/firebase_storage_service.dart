import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/questionnaire.dart';
import '../models/patient_response.dart';
import '../models/facility.dart';
import 'storage_service.dart';

/// Firebaseストレージサービス (ハイブリッド型アーキテクチャ)
/// 
/// このサービスは、Med SurveyアプリのデータをFirestore Databaseで管理します。
/// これにより、iOS再申請なしで問診内容や広告設定を変更できます。
class FirebaseStorageService implements StorageService {
  // Firestoreインスタンス
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // コレクション名
  static const String _facilitiesCollection = 'facilities';
  static const String _questionnairesCollection = 'questionnaires';
  static const String _responsesCollection = 'patient_responses';
  static const String _credentialsCollection = 'credentials';

  /// 施設コードから施設情報を取得
  Future<Facility?> getFacilityByCode(String facilityCode) async {
    try {
      print('🔍 施設コード検索: $facilityCode');
      
      final querySnapshot = await _firestore
          .collection(_facilitiesCollection)
          .where('facilityCode', isEqualTo: facilityCode.toUpperCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('⚠️ 施設が見つかりません');
        return null;
      }

      final data = querySnapshot.docs.first.data();
      print('✅ 施設発見: ${data['name']}');
      return Facility.fromFirestore(data);
    } catch (e) {
      print('❌ エラー: $e');
      rethrow;
    }
  }

  /// 施設IDから施設情報を取得
  Future<Facility?> getFacility(String facilityId) async {
    try {
      print('🔍 施設取得: $facilityId');
      
      final docSnapshot = await _firestore
          .collection(_facilitiesCollection)
          .doc(facilityId)
          .get();

      if (!docSnapshot.exists) {
        print('⚠️ 施設が見つかりません');
        return null;
      }

      print('✅ 施設取得成功');
      return Facility.fromFirestore(docSnapshot.data()!);
    } catch (e) {
      print('❌ エラー: $e');
      rethrow;
    }
  }

  /// 施設情報を更新
  Future<void> updateFacility(Facility facility) async {
    try {
      print('💾 施設更新: ${facility.id}');
      
      await _firestore
          .collection(_facilitiesCollection)
          .doc(facility.id)
          .set(facility.toFirestore(), SetOptions(merge: true));
      
      print('✅ 施設更新完了');
    } catch (e) {
      print('❌ エラー: $e');
      rethrow;
    }
  }

  /// 施設を登録
  Future<void> registerFacility(
    Facility facility,
    String email,
    String password,
  ) async {
    try {
      print('💾 施設登録開始: ${facility.name}');

      // Firestoreトランザクションで施設登録
      await _firestore.runTransaction((transaction) async {
        // 施設情報を保存
        final facilityRef = _firestore
            .collection(_facilitiesCollection)
            .doc(facility.id);
        transaction.set(facilityRef, facility.toFirestore());

        // 認証情報を保存
        final credentialRef = _firestore
            .collection(_credentialsCollection)
            .doc(email);
        transaction.set(credentialRef, {
          'email': email,
          'password': password, // 本番環境ではハッシュ化が必要
          'facilityId': facility.id,
          'role': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      // 初期テンプレート(MRI問診票)を自動作成
      final initialQuestionnaire = _createInitialQuestionnaire(facility.id);
      await saveQuestionnaire(initialQuestionnaire);

      print('✅ 施設登録完了');
    } catch (e) {
      print('❌ エラー: $e');
      rethrow;
    }
  }

  /// ログイン認証
  Future<Facility?> login(String email, String password) async {
    try {
      print('🔐 ログイン試行: $email');

      // 認証情報を確認
      final credentialDoc = await _firestore
          .collection(_credentialsCollection)
          .doc(email)
          .get();

      if (!credentialDoc.exists) {
        print('⚠️ ユーザーが見つかりません');
        return null;
      }

      final data = credentialDoc.data()!;
      if (data['password'] != password) {
        print('⚠️ パスワードが違います');
        return null;
      }

      // 施設情報を取得
      final facilityId = data['facilityId'] as String;
      print('✅ 認証成功、施設ID: $facilityId');
      
      return await getFacility(facilityId);
    } catch (e) {
      print('❌ エラー: $e');
      rethrow;
    }
  }

  /// 施設の問診票一覧を取得
  Future<List<Questionnaire>> getQuestionnaires(String facilityId) async {
    try {
      print('📖 問診票一覧取得: facilityId=$facilityId');

      final querySnapshot = await _firestore
          .collection(_questionnairesCollection)
          .where('facilityId', isEqualTo: facilityId)
          .where('isActive', isEqualTo: true)
          .orderBy('updatedAt', descending: true)
          .get();

      final list = querySnapshot.docs
          .map((doc) => Questionnaire.fromFirestore(doc.data()))
          .toList();

      print('📖 取得した問診票数: ${list.length}');
      for (var i = 0; i < list.length; i++) {
        print('📖 [$i] ID: ${list[i].id}, タイトル: ${list[i].title}, 更新日時: ${list[i].updatedAt}');
      }

      return list;
    } catch (e) {
      print('❌ エラー: $e');
      rethrow;
    }
  }

  /// 問診票をリアルタイム監視
  Stream<List<Questionnaire>> watchQuestionnaires(String facilityId) {
    return _firestore
        .collection(_questionnairesCollection)
        .where('facilityId', isEqualTo: facilityId)
        .where('isActive', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Questionnaire.fromFirestore(doc.data()))
          .toList();
    });
  }

  /// 問診票を保存
  Future<void> saveQuestionnaire(Questionnaire questionnaire) async {
    try {
      print('💾 問診票保存開始');
      print('💾 facilityId: ${questionnaire.facilityId}');
      print('💾 questionnaireId: ${questionnaire.id}');
      print('💾 タイトル: ${questionnaire.title}');
      print('💾 セクション数: ${questionnaire.sections.length}');

      await _firestore
          .collection(_questionnairesCollection)
          .doc(questionnaire.id)
          .set(questionnaire.toFirestore(), SetOptions(merge: true));

      print('💾 保存完了');
    } catch (e) {
      print('❌ エラー: $e');
      rethrow;
    }
  }

  /// 問診票を削除
  @override
  Future<void> deleteQuestionnaire(String facilityId, String questionnaireId) async {
    try {
      print('🗑️ 問診票削除: $questionnaireId');

      // 論理削除（isActive = false）
      await _firestore
          .collection(_questionnairesCollection)
          .doc(questionnaireId)
          .update({'isActive': false});

      print('✅ 削除完了');
    } catch (e) {
      print('❌ エラー: $e');
      rethrow;
    }
  }

  /// 患者回答を保存
  Future<void> savePatientResponse(PatientResponse response) async {
    try {
      print('💾 患者回答保存: ${response.id}');

      await _firestore
          .collection(_responsesCollection)
          .doc(response.id)
          .set(response.toFirestore());

      print('✅ 保存完了');
    } catch (e) {
      print('❌ エラー: $e');
      rethrow;
    }
  }

  /// 施設の患者回答一覧を取得
  Future<List<PatientResponse>> getPatientResponses(String facilityId) async {
    try {
      print('📖 患者回答取得: facilityId=$facilityId');

      final querySnapshot = await _firestore
          .collection(_responsesCollection)
          .where('facilityId', isEqualTo: facilityId)
          .orderBy('submittedAt', descending: true)
          .get();

      final list = querySnapshot.docs
          .map((doc) => PatientResponse.fromFirestore(doc.data()))
          .toList();

      print('📖 取得した回答数: ${list.length}');
      return list;
    } catch (e) {
      print('❌ エラー: $e');
      rethrow;
    }
  }

  /// 全施設一覧を取得（スーパー管理者用）
  @override
  List<Facility> getAllFacilities() {
    // 同期メソッドとして実装するため、非同期版を使用することを推奨
    throw UnimplementedError('Use getAllFacilitiesAsync() instead');
  }

  /// 全施設一覧を取得（非同期版）
  Future<List<Facility>> getAllFacilitiesAsync() async {
    try {
      print('📖 全施設取得');

      final querySnapshot = await _firestore
          .collection(_facilitiesCollection)
          .orderBy('createdAt', descending: true)
          .get();

      final list = querySnapshot.docs
          .map((doc) => Facility.fromFirestore(doc.data()))
          .toList();

      print('📖 取得した施設数: ${list.length}');
      return list;
    } catch (e) {
      print('❌ エラー: $e');
      rethrow;
    }
  }

  /// 初期テンプレート(MRI問診票)を作成
  Questionnaire _createInitialQuestionnaire(String facilityId) {
    return Questionnaire(
      id: 'mri_template_${DateTime.now().millisecondsSinceEpoch}',
      facilityId: facilityId,
      title: 'MRI検査前問診',
      description: 'MRI検査を安全に実施するための確認事項です。正確にご回答ください。',
      sections: _getMRISections(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  List<QuestionSection> _getMRISections() {
    return [
      // セクション1: 患者基本情報
      QuestionSection(
        id: 'section_basic',
        title: '患者基本情報',
        description: '基本的な情報をご入力ください',
        questions: [
          QuestionItem(
            id: 'q_patient_id',
            question: '患者ID',
            type: QuestionType.freeText,
            isRequired: false,
            order: 1,
          ),
          QuestionItem(
            id: 'q_weight',
            question: '現在の体重（kg）',
            type: QuestionType.freeText,
            isRequired: false,
            order: 2,
          ),
          QuestionItem(
            id: 'q_mri_experience',
            question: 'MRI検査の経験はありますか',
            type: QuestionType.yesNo,
            isRequired: true,
            showDetailOnYes: true,
            order: 3,
          ),
        ],
        order: 1,
      ),
      // セクション2: 手術歴・体内埋込物
      QuestionSection(
        id: 'section_implants',
        title: '手術歴・体内埋込物',
        description: '体内に埋め込まれている医療機器や金属についてお答えください',
        questions: [
          QuestionItem(
            id: 'q_pacemaker',
            question: '心臓ペースメーカー、ICD、CRT-Dを装着していますか',
            type: QuestionType.yesNo,
            isRequired: true,
            showDetailOnYes: true,
            order: 1,
          ),
          QuestionItem(
            id: 'q_cochlear',
            question: '人工内耳を装着していますか',
            type: QuestionType.yesNo,
            isRequired: true,
            showDetailOnYes: true,
            order: 2,
          ),
          QuestionItem(
            id: 'q_clip',
            question: '脳動脈クリップがありますか',
            type: QuestionType.yesNo,
            isRequired: true,
            showDetailOnYes: true,
            order: 3,
          ),
          QuestionItem(
            id: 'q_valve',
            question: '心臓人工弁がありますか',
            type: QuestionType.yesNo,
            isRequired: true,
            showDetailOnYes: true,
            order: 4,
          ),
          QuestionItem(
            id: 'q_stent',
            question: '血管ステント留置後間もないですか',
            type: QuestionType.yesNo,
            isRequired: true,
            showDetailOnYes: true,
            order: 5,
          ),
          QuestionItem(
            id: 'q_metal',
            question: '体内に金属(手術金属・破片など)がありますか',
            type: QuestionType.yesNo,
            isRequired: true,
            showDetailOnYes: true,
            order: 6,
          ),
          QuestionItem(
            id: 'q_hearing_aid',
            question: '補聴器・義歯・装着型医療機器を使用していますか',
            type: QuestionType.yesNo,
            isRequired: true,
            showDetailOnYes: true,
            order: 7,
          ),
        ],
        order: 2,
      ),
      // セクション3: 閉所恐怖症・過去の検査
      QuestionSection(
        id: 'section_phobia',
        title: '閉所恐怖症・過去の検査',
        description: 'MRI検査環境に関する確認事項です',
        questions: [
          QuestionItem(
            id: 'q_claustrophobia',
            question: '閉所が苦手ですか',
            type: QuestionType.yesNo,
            isRequired: true,
            showDetailOnYes: true,
            order: 1,
          ),
          QuestionItem(
            id: 'q_past_mri',
            question: '過去のMRI検査で体調不良や中断経験がありますか',
            type: QuestionType.yesNo,
            isRequired: true,
            showDetailOnYes: true,
            order: 2,
          ),
        ],
        order: 3,
      ),
      // セクション4: その他の確認事項
      QuestionSection(
        id: 'section_others',
        title: 'その他の確認事項',
        description: '追加の確認事項をお答えください',
        questions: [
          QuestionItem(
            id: 'q_tattoo',
            question: '入れ墨(タトゥー)がありますか',
            type: QuestionType.yesNo,
            isRequired: true,
            showDetailOnYes: true,
            order: 1,
          ),
          QuestionItem(
            id: 'q_pregnancy',
            question: '妊娠中、または妊娠の可能性がありますか',
            type: QuestionType.yesNo,
            isRequired: true,
            showDetailOnYes: true,
            order: 2,
          ),
          QuestionItem(
            id: 'q_concern',
            question: '現在の体調で不安な点はありますか',
            type: QuestionType.freeText,
            isRequired: false,
            order: 3,
          ),
          QuestionItem(
            id: 'q_message',
            question: '医療従事者に伝えておきたいこと',
            type: QuestionType.freeText,
            isRequired: false,
            order: 4,
          ),
        ],
        order: 4,
      ),
    ];
  }
}
