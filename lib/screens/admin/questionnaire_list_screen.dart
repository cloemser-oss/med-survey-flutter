import 'package:flutter/material.dart';
import '../../services/language_service.dart';
import '../../models/questionnaire.dart';
import '../../services/local_storage_service.dart';
import 'questionnaire_edit_screen.dart';
import 'patient_basic_info_settings_screen.dart';

class QuestionnaireListScreen extends StatefulWidget {
  final String facilityId;

  const QuestionnaireListScreen({
    super.key,
    required this.facilityId,
  });

  @override
  State<QuestionnaireListScreen> createState() =>
      _QuestionnaireListScreenState();
}

class _QuestionnaireListScreenState extends State<QuestionnaireListScreen> {
  final LanguageService _lang = LanguageService();
  // デモ用データ: MRI検査前問診テンプレート
  late List<Questionnaire> _questionnaires;

  @override
  void initState() {
    super.initState();
    _loadQuestionnaires();
  }

  void _loadQuestionnaires() async {
    // ローカルストレージから施設の問診票を読み込む
    final storage = LocalStorageService();
    final questionnaires = await storage.getQuestionnaires(widget.facilityId);
    
    setState(() {
      _questionnaires = questionnaires;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_lang.translate('questionnaire_management')),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PatientBasicInfoSettingsScreen(
                    facilityId: widget.facilityId,
                  ),
                ),
              );
            },
            tooltip: _lang.translate('patient_basic_info_settings'),
          ),
        ],
      ),
      body: _questionnaires.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _questionnaires.length,
              itemBuilder: (context, index) {
                final questionnaire = _questionnaires[index];
                return _buildQuestionnaireCard(questionnaire);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewQuestionnaire,
        icon: const Icon(Icons.add),
        label: Text(_lang.translate('create_new_questionnaire')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '問診票がありません',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '新規作成ボタンから問診票を作成してください',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionnaireCard(Questionnaire questionnaire) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _editQuestionnaire(questionnaire),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      questionnaire.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _editQuestionnaire(questionnaire),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                questionnaire.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.topic_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${questionnaire.sections.length}セクション',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.quiz_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_getTotalQuestions(questionnaire)}項目',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '更新: ${_formatDate(questionnaire.updatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  int _getTotalQuestions(Questionnaire questionnaire) {
    return questionnaire.sections.fold(
      0,
      (sum, section) => sum + section.questions.length,
    );
  }

  void _createNewQuestionnaire() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionnaireEditScreen(
          facilityId: widget.facilityId,
        ),
      ),
    );

    if (result != null && result is Questionnaire) {
      // ローカルストレージに保存
      final storage = LocalStorageService();
      await storage.saveQuestionnaire(result);
      
      // リストを再読み込み
      _loadQuestionnaires();
    }
  }

  void _editQuestionnaire(Questionnaire questionnaire) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionnaireEditScreen(
          facilityId: widget.facilityId,
          questionnaire: questionnaire,
        ),
      ),
    );

    if (result != null && result is Questionnaire) {
      // ローカルストレージに保存
      final storage = LocalStorageService();
      await storage.saveQuestionnaire(result);
      
      // リストを再読み込み
      _loadQuestionnaires();
    }
  }
}
