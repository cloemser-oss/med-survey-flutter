import 'package:flutter/material.dart';
import '../../services/language_service.dart';
import '../../models/questionnaire.dart';
import 'question_edit_screen.dart';

class SectionEditScreen extends StatefulWidget {
  final QuestionSection? section;

  const SectionEditScreen({
    super.key,
    this.section,
  });

  @override
  State<SectionEditScreen> createState() => _SectionEditScreenState();
}

class _SectionEditScreenState extends State<SectionEditScreen> {
  final LanguageService _lang = LanguageService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late List<QuestionItem> _questions;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.section?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.section?.description ?? '');
    _questions = widget.section?.questions.map((q) => q).toList() ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.section == null ? '新規セクション' : 'セクション編集'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: Text(_lang.translate('complete')),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // セクション情報入力
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'セクションタイトル',
                      hintText: '例: 患者基本情報、手術歴など',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.title),
                    ),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'タイトルを入力してください';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'セクション説明(任意)',
                      hintText: '例: 基本的な情報をご入力ください',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            
            // 質問リストヘッダー
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '質問項目 (${_questions.length})',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),

            // 質問リスト
            Expanded(
              child: _questions.isEmpty
                  ? _buildEmptyState()
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _questions.length,
                      onReorder: _onReorder,
                      itemBuilder: (context, index) {
                        final question = _questions[index];
                        return _buildQuestionCard(question, index);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addQuestion,
        icon: const Icon(Icons.add),
        label: Text(_lang.translate('add_question')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '質問がありません',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '「質問追加」ボタンから質問を作成してください',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuestionItem question, int index) {
    return Card(
      key: ValueKey(question.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.drag_handle, color: Theme.of(context).colorScheme.outline),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              radius: 16,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        title: Text(
          question.question,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Row(
          children: [
            Chip(
              label: Text(_getQuestionTypeLabel(question.type)),
              avatar: Icon(_getQuestionIcon(question.type), size: 16),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            if (question.isRequired)
              Chip(
                label: const Text('必須'),
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 11,
                ),
                visualDensity: VisualDensity.compact,
              ),
            if (question.showDetailOnYes)
              Chip(
                label: Text(_lang.translate('detail_input_label')),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editQuestion(index),
              tooltip: '編集',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Theme.of(context).colorScheme.error,
              onPressed: () => _deleteQuestion(index),
              tooltip: _lang.translate('delete'),
            ),
          ],
        ),
      ),
    );
  }

  String _getQuestionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.yesNo:
        return 'Yes/No';
      case QuestionType.singleChoice:
        return '単一選択';
      case QuestionType.multipleChoice:
        return '複数選択';
      case QuestionType.freeText:
        return '自由記載';
    }
  }

  IconData _getQuestionIcon(QuestionType type) {
    switch (type) {
      case QuestionType.yesNo:
        return Icons.toggle_on;
      case QuestionType.singleChoice:
        return Icons.radio_button_checked;
      case QuestionType.multipleChoice:
        return Icons.check_box;
      case QuestionType.freeText:
        return Icons.notes;
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final question = _questions.removeAt(oldIndex);
      _questions.insert(newIndex, question);

      // 順序を更新
      for (int i = 0; i < _questions.length; i++) {
        _questions[i] = QuestionItem(
          id: _questions[i].id,
          question: _questions[i].question,
          type: _questions[i].type,
          isRequired: _questions[i].isRequired,
          options: _questions[i].options,
          showDetailOnYes: _questions[i].showDetailOnYes,
          order: i + 1,
        );
      }
    });
  }

  void _addQuestion() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuestionEditScreen(),
      ),
    );

    if (result != null && result is QuestionItem) {
      setState(() {
        _questions.add(result);
      });
    }
  }

  void _editQuestion(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionEditScreen(question: _questions[index]),
      ),
    );

    if (result != null && result is QuestionItem) {
      setState(() {
        _questions[index] = result;
      });
    }
  }

  void _deleteQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_lang.translate('delete_question')),
        content: Text('「${_questions[index].question}」を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _questions.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('質問を削除しました')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(_lang.translate('delete')),
          ),
        ],
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('少なくとも1つの質問を追加してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final section = QuestionSection(
      id: widget.section?.id ??
          'section_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      questions: _questions,
      order: widget.section?.order ?? 1,
    );

    Navigator.pop(context, section);
  }
}
