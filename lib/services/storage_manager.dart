import 'storage_service.dart';
import 'local_storage_service.dart';
import 'firebase_storage_service.dart';
import '../models/questionnaire.dart';
import '../models/patient_response.dart';
import '../models/facility.dart';

/// ストレージマネージャー（ハイブリッド型）
/// 
/// Firebase設定が利用可能な場合はFirebaseStorageServiceを使用し、
/// 利用できない場合はLocalStorageServiceにフォールバックします。
/// 
/// これにより、開発時はローカルストレージ、本番環境はFirebaseと
/// 自動的に切り替わります。
class StorageManager implements StorageService {
  static final StorageManager _instance = StorageManager._internal();
  factory StorageManager() => _instance;
  StorageManager._internal() {
    _selectService();
  }

  late final StorageService _service;
  bool _useFirebase = false;

  /// Firebase利用可否を判定してサービスを選択
  void _selectService() {
    try {
      // Firebase設定の存在確認
      // 本番環境ではFirebaseが初期化されているかチェック
      _service = FirebaseStorageService();
      _useFirebase = true;
      print('✅ Firebaseストレージを使用します');
    } catch (e) {
      // Firebase未設定の場合はローカルストレージを使用
      _service = LocalStorageService();
      _useFirebase = false;
      print('⚠️ ローカルストレージを使用します（デモモード）');
    }
  }

  /// 現在Firebaseを使用しているか
  bool get isUsingFirebase => _useFirebase;

  @override
  Future<Facility?> getFacilityByCode(String facilityCode) {
    return _service.getFacilityByCode(facilityCode);
  }

  @override
  Future<Facility?> getFacility(String facilityId) {
    return _service.getFacility(facilityId);
  }

  @override
  Future<void> updateFacility(Facility facility) {
    return _service.updateFacility(facility);
  }

  @override
  Future<void> registerFacility(
    Facility facility,
    String email,
    String password,
  ) {
    return _service.registerFacility(facility, email, password);
  }

  @override
  Future<Facility?> login(String email, String password) {
    return _service.login(email, password);
  }

  @override
  Future<List<Questionnaire>> getQuestionnaires(String facilityId) {
    return _service.getQuestionnaires(facilityId);
  }

  @override
  Future<void> saveQuestionnaire(Questionnaire questionnaire) {
    return _service.saveQuestionnaire(questionnaire);
  }

  @override
  Future<void> deleteQuestionnaire(String facilityId, String questionnaireId) {
    return _service.deleteQuestionnaire(facilityId, questionnaireId);
  }

  @override
  Future<void> savePatientResponse(PatientResponse response) {
    return _service.savePatientResponse(response);
  }

  @override
  Future<List<PatientResponse>> getPatientResponses(String facilityId) {
    return _service.getPatientResponses(facilityId);
  }

  @override
  List<Facility> getAllFacilities() {
    return _service.getAllFacilities();
  }

  /// Firebaseストレージへの切り替え（手動）
  void switchToFirebase() {
    if (!_useFirebase) {
      _service = FirebaseStorageService();
      _useFirebase = true;
      print('✅ Firebaseストレージに切り替えました');
    }
  }

  /// ローカルストレージへの切り替え（デバッグ用）
  void switchToLocal() {
    if (_useFirebase) {
      _service = LocalStorageService();
      _useFirebase = false;
      print('⚠️ ローカルストレージに切り替えました');
    }
  }
}
