import '../models/questionnaire.dart';
import '../models/patient_response.dart';
import '../models/facility.dart';

/// ストレージサービスの抽象化インターフェース
/// 
/// LocalStorageServiceとFirebaseStorageServiceを統一的に扱うための
/// 抽象クラスです。これにより、ビジネスロジック層はストレージの
/// 実装詳細を知る必要がなくなります。
abstract class StorageService {
  /// 施設コードから施設情報を取得
  Future<Facility?> getFacilityByCode(String facilityCode);

  /// 施設IDから施設情報を取得
  Future<Facility?> getFacility(String facilityId);

  /// 施設情報を更新
  Future<void> updateFacility(Facility facility);

  /// 施設を登録
  Future<void> registerFacility(
    Facility facility,
    String email,
    String password,
  );

  /// ログイン認証
  Future<Facility?> login(String email, String password);

  /// 施設の問診票一覧を取得
  Future<List<Questionnaire>> getQuestionnaires(String facilityId);

  /// 問診票を保存
  Future<void> saveQuestionnaire(Questionnaire questionnaire);

  /// 問診票を削除
  Future<void> deleteQuestionnaire(String facilityId, String questionnaireId);

  /// 患者回答を保存
  Future<void> savePatientResponse(PatientResponse response);

  /// 施設の患者回答一覧を取得
  Future<List<PatientResponse>> getPatientResponses(String facilityId);

  /// 全施設一覧を取得（スーパー管理者用）
  List<Facility> getAllFacilities();
}
