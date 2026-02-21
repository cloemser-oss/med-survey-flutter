import 'package:flutter/material.dart';
import '../../services/language_service.dart';
import '../../models/questionnaire.dart';
import '../../models/patient_response.dart';
import '../../models/patient_info.dart';
import '../../services/local_storage_service.dart';

class PatientQuestionnaireScreen extends StatefulWidget {
  final String facilityId;
  final String questionnaireId;
  final PatientInfo patientInfo;

  const PatientQuestionnaireScreen({
    super.key,
    required this.facilityId,
    required this.questionnaireId,
    required this.patientInfo,
  });

  @override
  State<PatientQuestionnaireScreen> createState() =>
      _PatientQuestionnaireScreenState();
}

class _PatientQuestionnaireScreenState extends State<PatientQuestionnaireScreen> {
  final LanguageService _lang = LanguageService();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // 問診回答
  final Map<String, Answer> _answers = {};

  // 同意チェック
  bool _hasAgreed = false;

  // デモ用MRI問診票
  late Questionnaire _questionnaire;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuestionnaire();
  }

  Future<void> _loadQuestionnaire() async {
    try {
      final storage = LocalStorageService();
      final questionnaires = await storage.getQuestionnaires(widget.facilityId);
      
      // デバッグ用ログ
      print('📋 問診票読み込み: facilityId=${widget.facilityId}');
      print('📋 取得した問診票数: ${questionnaires.length}');
      print('📋 探しているID: ${widget.questionnaireId}');
      
      if (questionnaires.isEmpty) {
        print('⚠️ 問診票が見つかりません');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_lang.translate('questionnaire_not_found')),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // 指定されたIDの問診票を探す
      Questionnaire? targetQuestionnaire;
      for (final q in questionnaires) {
        print('📋 問診票ID: ${q.id}, タイトル: ${q.title}, 最終更新: ${q.updatedAt}');
        if (q.id == widget.questionnaireId) {
          targetQuestionnaire = q;
          print('✅ 一致する問診票を発見');
          break;
        }
      }
      
      // 見つからない場合は最初の問診票を使用
      if (targetQuestionnaire == null) {
        print('⚠️ 指定されたIDの問診票が見つかりませんでした。最初の問診票を使用します');
        targetQuestionnaire = questionnaires.first;
      }
      
      print('📋 使用する問診票: ${targetQuestionnaire.title}');
      print('📋 セクション数: ${targetQuestionnaire.sections.length}');
      
      if (mounted) {
        setState(() {
          _questionnaire = targetQuestionnaire!;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ エラー: $e');
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

  // 総ページ数: セクション数 + 同意ページ
  int get _totalPages => _questionnaire.sections.length + 1;

  /// 終了確認ダイアログ
  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_lang.translate('interrupt_questionnaire')),
        content: Text(_lang.translate('input_not_saved')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // ダイアログを閉じる
              Navigator.pop(context); // 問診票画面を閉じる
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(_lang.translate('back')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_lang.translate('loading_questionnaires')),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_questionnaire.title),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _showExitConfirmation(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: '終了',
            onPressed: () {
              _showExitConfirmation(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // プログレスバー
            LinearProgressIndicator(
              value: (_currentPage + 1) / _totalPages,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '${_currentPage + 1} / $_totalPages',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            // ページコンテンツ
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _totalPages,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  if (index < _questionnaire.sections.length) {
                    return _buildSectionPage(_questionnaire.sections[index]);
                  } else {
                    return _buildConsentPage();
                  }
                },
              ),
            ),
            // ナビゲーションボタン
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionPage(QuestionSection section) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // セクションタイトル
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  section.title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (section.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    section.description!,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 質問リスト
          ...section.questions.asMap().entries.map((entry) {
            final index = entry.key;
            final question = entry.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (index > 0) const SizedBox(height: 24),
                _buildQuestionCard(question),
              ],
            );
          }),
          const SizedBox(height: 100), // 下部に余白を追加
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuestionItem question) {
    final answer = _answers[question.id];

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 質問文
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (question.isRequired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '必須',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (question.isRequired) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question.question,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 回答入力
            if (question.type == QuestionType.yesNo) ...[
              _buildYesNoButtons(question),
              if (question.showDetailOnYes && answer?.value == 'yes') ...[
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: question.detailPrompt ?? '詳しく教えてください',
                    hintText: '詳細を入力',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 2,
                  style: const TextStyle(fontSize: 16),
                  onChanged: (value) {
                    setState(() {
                      _answers[question.id] = Answer(
                        questionId: question.id,
                        value: 'yes',
                        detail: value,
                      );
                    });
                  },
                ),
              ],
            ] else if (question.type == QuestionType.freeText) ...[
              TextField(
                decoration: InputDecoration(
                  hintText: '自由に記入してください',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                style: const TextStyle(fontSize: 16),
                onChanged: (value) {
                  setState(() {
                    _answers[question.id] = Answer(
                      questionId: question.id,
                      value: value,
                    );
                  });
                },
              ),
            ] else if (question.type == QuestionType.singleChoice && question.options != null) ...[
              ...question.options!.map((option) {
                final isSelected = answer?.value == option;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _answers[question.id] = Answer(
                          questionId: question.id,
                          value: option,
                        );
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      side: BorderSide(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }),
            ] else if (question.type == QuestionType.multipleChoice && question.options != null) ...[
              ...question.options!.map((option) {
                // 複数選択の場合、valueをカンマ区切りで保存
                final selectedOptions = answer?.value.split(',').map((e) => e.trim()).toList() ?? [];
                final isSelected = selectedOptions.contains(option);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: CheckboxListTile(
                    title: Text(
                      option,
                      style: const TextStyle(fontSize: 16),
                    ),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        List<String> newSelectedOptions = List.from(selectedOptions);
                        if (value == true) {
                          newSelectedOptions.add(option);
                        } else {
                          newSelectedOptions.remove(option);
                        }
                        _answers[question.id] = Answer(
                          questionId: question.id,
                          value: newSelectedOptions.join(', '),
                        );
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildYesNoButtons(QuestionItem question) {
    final answer = _answers[question.id];
    final isYesSelected = answer?.value == 'yes';
    final isNoSelected = answer?.value == 'no';

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _answers[question.id] = Answer(
                  questionId: question.id,
                  value: 'yes',
                );
              });
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: isYesSelected
                  ? Theme.of(context).colorScheme.errorContainer
                  : null,
              side: BorderSide(
                color: isYesSelected
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.outline,
                width: isYesSelected ? 2 : 1,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: Icon(
              Icons.check_circle,
              color: isYesSelected
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.outline,
            ),
            label: Text(
              _lang.translate('yes'),
              style: TextStyle(
                color: isYesSelected
                    ? Theme.of(context).colorScheme.error
                    : null,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _answers[question.id] = Answer(
                  questionId: question.id,
                  value: 'no',
                );
              });
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: isNoSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              side: BorderSide(
                color: isNoSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                width: isNoSelected ? 2 : 1,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: Icon(
              Icons.cancel,
              color: isNoSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
            ),
            label: Text(
              _lang.translate('no'),
              style: TextStyle(
                color: isNoSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConsentPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          Icon(
            Icons.assignment_turned_in_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            '最後の確認',
            style: Theme.of(context).textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(height: 16),
                Text(
                  '重要な注意事項',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  '本問診は診断や検査可否を判断するものではありません。\n\n'
                  '入力内容は医療従事者が確認し、必要に応じて追加確認を行います。\n\n'
                  '内容を理解し、正確に入力しました。',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Card(
            color: _hasAgreed
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: InkWell(
              onTap: () {
                setState(() {
                  _hasAgreed = !_hasAgreed;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    Icon(
                      _hasAgreed
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      size: 32,
                      color: _hasAgreed
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '上記の内容を理解し、同意します',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: _hasAgreed
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final isFirstPage = _currentPage == 0;
    final isLastPage = _currentPage == _totalPages - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (!isFirstPage)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: Text(_lang.translate('back')),
                ),
              ),
            if (!isFirstPage) const SizedBox(width: 16),
            Expanded(
              flex: isFirstPage ? 1 : 1,
              child: ElevatedButton.icon(
                onPressed: isLastPage
                    ? _canSubmit()
                        ? _showSubmitConfirmation
                        : null
                    : _canGoNext()
                        ? _next
                        : null,
                icon: Icon(isLastPage ? Icons.send : Icons.arrow_forward),
                label: Text(isLastPage ? '送信' : '次へ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canGoNext() {
    if (_currentPage >= _questionnaire.sections.length) {
      return true;
    }

    final section = _questionnaire.sections[_currentPage];
    for (final question in section.questions) {
      if (question.isRequired) {
        final answer = _answers[question.id];
        if (answer == null || answer.value.isEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  void _next() {
    if (!_canGoNext()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('必須項目をすべて入力してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _canSubmit() {
    if (!_hasAgreed) return false;

    // 必須項目のチェック
    for (final section in _questionnaire.sections) {
      for (final question in section.questions) {
        if (question.isRequired) {
          final answer = _answers[question.id];
          if (answer == null || answer.value.isEmpty) {
            return false;
          }
        }
      }
    }

    return true;
  }

  /// 送信確認ダイアログ
  void _showSubmitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.send,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(_lang.translate('submit_confirmation')),
        content: const Text(
          '問診票を送信してもよろしいですか？\n\n'
          '送信後は内容を変更できません。',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_lang.translate('no')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // ダイアログを閉じる
              _submit(); // 送信処理を実行
            },
            child: Text(_lang.translate('yes')),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    // 送信処理
    try {
      final response = PatientResponse(
        id: 'response_${DateTime.now().millisecondsSinceEpoch}',
        questionnaireId: widget.questionnaireId,
        facilityId: widget.facilityId,
        patientId: widget.patientInfo.patientId,
        patientName: widget.patientInfo.name,
        weight: widget.patientInfo.weight,
        dateOfBirth: widget.patientInfo.dateOfBirth,
        answers: _answers,
        hasAgreed: _hasAgreed,
        submittedAt: DateTime.now(),
      );

      // ローカルストレージに保存
      final storage = LocalStorageService();
      await storage.savePatientResponse(response);
      
      // 送信済み状態を記録（患者ID+生年月日で識別）
      await storage.markQuestionnaireAsSubmitted(
        widget.facilityId,
        widget.patientInfo.patientId,
        widget.patientInfo.dateOfBirth?.toIso8601String(),
        widget.questionnaireId,
      );

      print('✅ 患者回答を保存しました');
      print('   患者ID: ${response.patientId}');
      print('   氏名: ${response.patientName}');
      print('   体重: ${response.weight} kg');
      print('   回答数: ${response.answers.length}');
    } catch (e) {
      print('❌ 回答保存エラー: $e');
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: Icon(
            Icons.check_circle,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(_lang.translate('submit_success')),
          content: const Text(
            'ご回答ありがとうございました。\n\n'
            '医療従事者が内容を確認いたします。',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                // 完全に終了（患者アクセス画面まで戻る）
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text(_lang.translate('exit')),
            ),
            ElevatedButton(
              onPressed: () {
                // 問診票選択画面に戻る
                Navigator.of(context).pop(); // ダイアログを閉じる
                Navigator.of(context).pop(); // 問診票画面を閉じる
              },
              child: Text(_lang.translate('back_to_selection')),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
