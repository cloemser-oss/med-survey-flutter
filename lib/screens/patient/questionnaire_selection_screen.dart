import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/language_service.dart';
import '../../models/questionnaire.dart';
import '../../models/patient_info.dart';
import '../../services/local_storage_service.dart';
import 'patient_questionnaire_screen.dart';

/// 問診票選択画面
/// 
/// 患者情報入力後、回答する問診票を選択します。
/// 複数の問診票がある場合、一覧から選択できます。
class QuestionnaireSelectionScreen extends StatefulWidget {
  final String facilityId;
  final String facilityName;
  final PatientInfo patientInfo;

  const QuestionnaireSelectionScreen({
    super.key,
    required this.facilityId,
    required this.facilityName,
    required this.patientInfo,
  });

  @override
  State<QuestionnaireSelectionScreen> createState() =>
      _QuestionnaireSelectionScreenState();
}

class _QuestionnaireSelectionScreenState extends State<QuestionnaireSelectionScreen> {
  final LanguageService _lang = LanguageService();
  List<Questionnaire> _questionnaires = [];
  Set<String> _submittedQuestionnaireIds = {}; // 送信済み問診票のID
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestionnaires();
  }

  Future<void> _loadQuestionnaires() async {
    try {
      final storage = LocalStorageService();
      final questionnaires = await storage.getQuestionnaires(widget.facilityId);
      
      // 送信済みの問診票IDを取得（患者ID+生年月日で識別）
      final submittedIds = await storage.getSubmittedQuestionnaireIds(
        widget.facilityId,
        widget.patientInfo.patientId,
        widget.patientInfo.dateOfBirth?.toIso8601String(),
      );

      if (mounted) {
        setState(() {
          _questionnaires = questionnaires;
          _submittedQuestionnaireIds = submittedIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('問診票の読み込みに失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 戻る確認ダイアログ
  void _showBackConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('患者情報入力に戻りますか？'),
        content: const Text('問診票選択画面から戻ります。\n入力した患者情報は保持されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // ダイアログを閉じる
              Navigator.pop(context); // 画面を閉じる
            },
            child: const Text('戻る'),
          ),
        ],
      ),
    );
  }

  /// 保存して終了確認ダイアログ
  void _showSaveAndExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.check_circle_outline,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('入力内容を保存して終了しますか？'),
        content: const Text(
          '患者基本情報が保存されました。\n\n'
          '問診票への回答は、いつでも再開できます。\n'
          '再度同じ患者ID・生年月日でアクセスすると、送信済み状態が表示されます。',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // ダイアログを閉じる
              // 患者アクセス画面まで戻る（施設選択画面）
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.save, size: 20),
            label: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _selectQuestionnaire(Questionnaire questionnaire) async {
    // 送信済みチェック
    if (_submittedQuestionnaireIds.contains(questionnaire.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_lang.translate('already_submitted')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 問診票画面へ遷移
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientQuestionnaireScreen(
          facilityId: widget.facilityId,
          questionnaireId: questionnaire.id,
          patientInfo: widget.patientInfo,
        ),
      ),
    );

    // 画面から戻ってきたら送信済みリストを再読み込み
    _loadQuestionnaires();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_lang.translate('questionnaire_selection')),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),  // 戻るアイコン
          tooltip: '患者情報入力に戻る',
          onPressed: () => _showBackConfirmation(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),  // 保存して終了アイコン
            tooltip: '保存して終了',
            onPressed: () => _showSaveAndExitConfirmation(context),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _questionnaires.isEmpty
                ? _buildEmptyState()
                : _buildQuestionnaireList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 100,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              '問診票がありません',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '医療機関に問診票が登録されていません。\n医療機関にお問い合わせください。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionnaireList() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 施設名・患者情報表示
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.local_hospital,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.facilityName,
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    // 患者IDと生年月日のみ表示
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.badge, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '患者ID: ${widget.patientInfo.patientId}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    if (widget.patientInfo.dateOfBirth != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '生年月日: ${DateFormat('yyyy/MM/dd').format(widget.patientInfo.dateOfBirth!)}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 説明
            Text(
              _lang.translate('select_questionnaire_message'),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'お問い合わせ内容を選択してください',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),

            // 問診票一覧
            ...List.generate(_questionnaires.length, (index) {
              final questionnaire = _questionnaires[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildQuestionnaireCard(questionnaire, index + 1),
              );
            }),

            const SizedBox(height: 16),

            // 注意事項
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.shade200,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '各問診票は個別に回答できます。',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionnaireCard(Questionnaire questionnaire, int number) {
    final isSubmitted = _submittedQuestionnaireIds.contains(questionnaire.id);
    
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: isSubmitted ? null : () => _selectQuestionnaire(questionnaire),
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isSubmitted ? 0.6 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // 番号バッジまたは送信済みバッジ
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSubmitted
                        ? Colors.green
                        : Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: isSubmitted
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 32,
                          )
                        : Text(
                            '$number',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),

                // 問診票情報
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        questionnaire.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        questionnaire.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.checklist,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${questionnaire.sections.length}セクション',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (isSubmitted) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '送信済み',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // 矢印アイコンまたは完了アイコン
                Icon(
                  isSubmitted ? Icons.check_circle : Icons.arrow_forward_ios,
                  color: isSubmitted
                      ? Colors.green
                      : Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
