import '../models/questionnaire.dart';
import '../models/patient_response.dart';
import '../models/facility.dart';
import '../models/patient_basic_info_config.dart';
import 'storage_service.dart';

/// ローカルストレージサービス(デモ版)
/// 実際のアプリではFirestoreを使用しますが、
/// デモ版ではメモリ内にデータを保持します
class LocalStorageService implements StorageService {
  // シングルトンパターン
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  // メモリ内データストア
  final Map<String, Facility> _facilities = {};
  final Map<String, List<Questionnaire>> _questionnaires = {};
  final Map<String, List<PatientResponse>> _patientResponses = {};
  final Map<String, Map<String, String>> _credentials = {}; // email -> {password, facilityId}
  final Map<String, String> _facilityCodes = {}; // facilityCode -> facilityId
  // 患者ID+生年月日をキーとした送信済み問診票管理: "facilityId:patientId:dateOfBirth" -> Set<questionnaireId>
  final Map<String, Set<String>> _submittedQuestionnaires = {};
  final Map<String, PatientBasicInfoConfig> _patientBasicInfoConfigs = {}; // facilityId -> Config

  /// 6桁の施設コードを生成
  String _generateFacilityCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 紛らわしい文字を除外
    final random = DateTime.now().millisecondsSinceEpoch;
    var code = '';
    var seed = random;
    
    for (var i = 0; i < 6; i++) {
      code += chars[seed % chars.length];
      seed = seed ~/ chars.length + i;
    }
    
    // 既に存在する場合は再生成
    if (_facilityCodes.containsKey(code)) {
      return _generateFacilityCode();
    }
    
    return code;
  }

  /// 問診票を登録
  @override
  Future<void> registerFacility(
    Facility facility,
    String email,
    String password,
  ) async {
    _facilities[facility.id] = facility;
    _credentials[email] = {
      'password': password,
      'facilityId': facility.id,
    };
    _facilityCodes[facility.facilityCode] = facility.id;

    // 初期テンプレート(MRI問診票)を自動作成
    final initialQuestionnaire = _createInitialQuestionnaire(facility.id);
    _questionnaires[facility.id] = [initialQuestionnaire];
    _patientResponses[facility.id] = [];
  }

  /// 施設コードから施設情報を取得
  Future<Facility?> getFacilityByCode(String facilityCode) async {
    final facilityId = _facilityCodes[facilityCode.toUpperCase()];
    if (facilityId == null) {
      return null;
    }
    return _facilities[facilityId];
  }

  /// ログイン認証
  Future<Facility?> login(String email, String password) async {
    final credential = _credentials[email];
    if (credential == null) {
      return null;
    }

    if (credential['password'] != password) {
      return null;
    }

    final facilityId = credential['facilityId']!;
    return _facilities[facilityId];
  }

  /// 施設情報を取得
  Future<Facility?> getFacility(String facilityId) async {
    return _facilities[facilityId];
  }

  /// 施設情報を更新
  Future<void> updateFacility(Facility facility) async {
    _facilities[facility.id] = facility;
  }

  /// 施設の問診票一覧を取得
  Future<List<Questionnaire>> getQuestionnaires(String facilityId) async {
    print('📖 問診票一覧取得: facilityId=$facilityId');
    final list = _questionnaires[facilityId] ?? [];
    print('📖 取得した問診票数: ${list.length}');
    for (var i = 0; i < list.length; i++) {
      print('📖 [$i] ID: ${list[i].id}, タイトル: ${list[i].title}, 更新日時: ${list[i].updatedAt}');
    }
    return list;
  }

  /// 問診票を保存
  Future<void> saveQuestionnaire(Questionnaire questionnaire) async {
    final facilityId = questionnaire.facilityId;
    
    print('💾 問診票保存開始');
    print('💾 facilityId: $facilityId');
    print('💾 questionnaireId: ${questionnaire.id}');
    print('💾 タイトル: ${questionnaire.title}');
    print('💾 セクション数: ${questionnaire.sections.length}');
    
    if (!_questionnaires.containsKey(facilityId)) {
      _questionnaires[facilityId] = [];
      print('💾 新規施設のため問診票リストを作成');
    }

    final index = _questionnaires[facilityId]!
        .indexWhere((q) => q.id == questionnaire.id);

    if (index != -1) {
      // 更新
      print('💾 既存の問診票を更新: index=$index');
      _questionnaires[facilityId]![index] = questionnaire;
    } else {
      // 新規追加
      print('💾 新規問診票として追加');
      _questionnaires[facilityId]!.add(questionnaire);
    }
    
    print('💾 現在の問診票数: ${_questionnaires[facilityId]!.length}');
    print('💾 保存完了');
  }

  /// 問診票を削除
  Future<void> deleteQuestionnaire(String facilityId, String questionnaireId) async {
    if (_questionnaires.containsKey(facilityId)) {
      _questionnaires[facilityId]!
          .removeWhere((q) => q.id == questionnaireId);
    }
  }

  /// 患者回答を保存
  Future<void> savePatientResponse(PatientResponse response) async {
    final facilityId = response.facilityId;
    
    if (!_patientResponses.containsKey(facilityId)) {
      _patientResponses[facilityId] = [];
    }

    _patientResponses[facilityId]!.add(response);
  }

  /// 施設の患者回答一覧を取得
  Future<List<PatientResponse>> getPatientResponses(String facilityId) async {
    return _patientResponses[facilityId] ?? [];
  }

  /// 登録済み施設の一覧を取得(デバッグ用)
  @override
  List<Facility> getAllFacilities() {
    return _facilities.values.toList();
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
      // セクション1: 手術歴・体内埋込物
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
        order: 1,
      ),
      // セクション2: 閉所恐怖症・過去の検査
      QuestionSection(
        id: 'section_phobia',
        title: '閉所恐怖症・過去の検査',
        description: 'MRI検査環境に関する確認事項です',
        questions: [
          QuestionItem(
            id: 'q_mri_experience',
            question: 'MRI検査の経験はありますか',
            type: QuestionType.yesNo,
            isRequired: true,
            showDetailOnYes: true,
            order: 1,
          ),
          QuestionItem(
            id: 'q_claustrophobia',
            question: '閉所が苦手ですか',
            type: QuestionType.yesNo,
            isRequired: true,
            showDetailOnYes: true,
            order: 2,
          ),
          QuestionItem(
            id: 'q_past_mri',
            question: '過去のMRI検査で体調不良や中断経験がありますか',
            type: QuestionType.yesNo,
            isRequired: true,
            showDetailOnYes: true,
            order: 3,
          ),
        ],
        order: 2,
      ),
      // セクション3: その他の確認事項
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
        order: 3,
      ),
    ];
  }

  /// 患者識別キーを生成（facilityId:patientId:dateOfBirth）
  String _generatePatientKey(String facilityId, String patientId, String? dateOfBirth) {
    return '$facilityId:$patientId:${dateOfBirth ?? ""}';
  }

  /// 送信済み問診票を記録（患者ID+生年月日で識別）
  Future<void> markQuestionnaireAsSubmitted(String facilityId, String patientId, String? dateOfBirth, String questionnaireId) async {
    final key = _generatePatientKey(facilityId, patientId, dateOfBirth);
    if (!_submittedQuestionnaires.containsKey(key)) {
      _submittedQuestionnaires[key] = {};
    }
    _submittedQuestionnaires[key]!.add(questionnaireId);
  }

  /// 送信済み状態を解除
  Future<void> clearSubmittedStatus(String facilityId, String patientId, String? dateOfBirth, String questionnaireId) async {
    final key = _generatePatientKey(facilityId, patientId, dateOfBirth);
    if (_submittedQuestionnaires.containsKey(key)) {
      _submittedQuestionnaires[key]!.remove(questionnaireId);
    }
  }

  /// 送信済みかチェック（患者ID+生年月日で識別）
  Future<bool> isQuestionnaireSubmitted(String facilityId, String patientId, String? dateOfBirth, String questionnaireId) async {
    final key = _generatePatientKey(facilityId, patientId, dateOfBirth);
    return _submittedQuestionnaires[key]?.contains(questionnaireId) ?? false;
  }

  /// 送信済み問診票IDのリストを取得（患者ID+生年月日で識別）
  Future<Set<String>> getSubmittedQuestionnaireIds(String facilityId, String patientId, String? dateOfBirth) async {
    final key = _generatePatientKey(facilityId, patientId, dateOfBirth);
    return _submittedQuestionnaires[key] ?? {};
  }

  /// 回答を確認済みにする
  Future<void> markResponseAsConfirmed(String facilityId, String responseId) async {
    final responses = _patientResponses[facilityId] ?? [];
    final index = responses.indexWhere((r) => r.id == responseId);
    
    if (index != -1) {
      // 新しいインスタンスを作成（isConfirmedをtrueに）
      final updatedResponse = PatientResponse(
        id: responses[index].id,
        questionnaireId: responses[index].questionnaireId,
        facilityId: responses[index].facilityId,
        patientId: responses[index].patientId,
        patientName: responses[index].patientName,
        weight: responses[index].weight,
        answers: responses[index].answers,
        hasAgreed: responses[index].hasAgreed,
        submittedAt: responses[index].submittedAt,
        isConfirmed: true,
        staffMemo: responses[index].staffMemo,
      );
      
      responses[index] = updatedResponse;
      _patientResponses[facilityId] = responses;
    }
  }

  /// 回答の確認済み状態を解除
  Future<void> unmarkResponseAsConfirmed(String facilityId, String responseId) async {
    final responses = _patientResponses[facilityId] ?? [];
    final index = responses.indexWhere((r) => r.id == responseId);
    
    if (index != -1) {
      // 新しいインスタンスを作成（isConfirmedをfalseに）
      final updatedResponse = PatientResponse(
        id: responses[index].id,
        questionnaireId: responses[index].questionnaireId,
        facilityId: responses[index].facilityId,
        patientId: responses[index].patientId,
        patientName: responses[index].patientName,
        weight: responses[index].weight,
        answers: responses[index].answers,
        hasAgreed: responses[index].hasAgreed,
        submittedAt: responses[index].submittedAt,
        isConfirmed: false,
        staffMemo: responses[index].staffMemo,
      );
      
      responses[index] = updatedResponse;
      _patientResponses[facilityId] = responses;
    }
  }

  /// 医療従事者メモを更新
  Future<void> updateStaffMemo(String facilityId, String responseId, String memo) async {
    final responses = _patientResponses[facilityId] ?? [];
    final index = responses.indexWhere((r) => r.id == responseId);
    
    if (index != -1) {
      // 新しいインスタンスを作成（staffMemoを更新）
      final updatedResponse = PatientResponse(
        id: responses[index].id,
        questionnaireId: responses[index].questionnaireId,
        facilityId: responses[index].facilityId,
        patientId: responses[index].patientId,
        patientName: responses[index].patientName,
        weight: responses[index].weight,
        answers: responses[index].answers,
        hasAgreed: responses[index].hasAgreed,
        submittedAt: responses[index].submittedAt,
        isConfirmed: responses[index].isConfirmed,
        staffMemo: memo.isEmpty ? null : memo,
      );
      
      responses[index] = updatedResponse;
      _patientResponses[facilityId] = responses;
    }
  }

  /// 患者基本情報を更新
  Future<void> updatePatientBasicInfo({
    required String facilityId,
    required String responseId,
    required String patientId,
    required String patientName,
    required double weight,
    DateTime? dateOfBirth,
  }) async {
    final responses = _patientResponses[facilityId] ?? [];
    final index = responses.indexWhere((r) => r.id == responseId);
    
    if (index != -1) {
      // 新しいインスタンスを作成（患者基本情報を更新）
      final updatedResponse = PatientResponse(
        id: responses[index].id,
        questionnaireId: responses[index].questionnaireId,
        facilityId: responses[index].facilityId,
        patientId: patientId,
        patientName: patientName,
        weight: weight,
        dateOfBirth: dateOfBirth,
        answers: responses[index].answers,
        hasAgreed: responses[index].hasAgreed,
        submittedAt: responses[index].submittedAt,
        isConfirmed: responses[index].isConfirmed,
        staffMemo: responses[index].staffMemo,
      );
      
      responses[index] = updatedResponse;
      _patientResponses[facilityId] = responses;
    }
  }

  /// 患者回答を更新
  Future<void> updatePatientAnswer({
    required String facilityId,
    required String responseId,
    required String questionId,
    required String value,
    String? detail,
  }) async {
    final responses = _patientResponses[facilityId] ?? [];
    final index = responses.indexWhere((r) => r.id == responseId);
    
    if (index != -1) {
      // 回答を更新
      final updatedAnswers = Map<String, Answer>.from(responses[index].answers);
      updatedAnswers[questionId] = Answer(
        questionId: questionId,
        value: value,
        detail: detail,
      );
      
      // 新しいインスタンスを作成
      final updatedResponse = PatientResponse(
        id: responses[index].id,
        questionnaireId: responses[index].questionnaireId,
        facilityId: responses[index].facilityId,
        patientId: responses[index].patientId,
        patientName: responses[index].patientName,
        weight: responses[index].weight,
        answers: updatedAnswers,
        hasAgreed: responses[index].hasAgreed,
        submittedAt: responses[index].submittedAt,
        isConfirmed: responses[index].isConfirmed,
        staffMemo: responses[index].staffMemo,
      );
      
      responses[index] = updatedResponse;
      _patientResponses[facilityId] = responses;
    }
  }

  /// 患者基本情報設定を取得
  Future<PatientBasicInfoConfig> getPatientBasicInfoConfig(String facilityId) async {
    if (_patientBasicInfoConfigs.containsKey(facilityId)) {
      return _patientBasicInfoConfigs[facilityId]!;
    }
    // デフォルト設定を返す
    return PatientBasicInfoConfig.defaultConfig(facilityId);
  }

  /// 患者基本情報設定を保存
  Future<void> savePatientBasicInfoConfig(PatientBasicInfoConfig config) async {
    _patientBasicInfoConfigs[config.facilityId] = config;
  }
}
