import 'package:flutter/material.dart';
import '../../services/language_service.dart';
import '../../models/questionnaire.dart';
import 'section_edit_screen.dart';

class QuestionnaireEditScreen extends StatefulWidget {
  final String facilityId;
  final Questionnaire? questionnaire;

  const QuestionnaireEditScreen({
    super.key,
    required this.facilityId,
    this.questionnaire,
  });

  @override
  State<QuestionnaireEditScreen> createState() =>
      _QuestionnaireEditScreenState();
}

class _QuestionnaireEditScreenState extends State<QuestionnaireEditScreen> {
  final LanguageService _lang = LanguageService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late List<QuestionSection> _sections;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.questionnaire?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.questionnaire?.description ?? '');
    _sections = widget.questionnaire?.sections.map((s) => s).toList() ?? [];
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
        title: Text(widget.questionnaire == null ? '新規問診票' : '問診票編集'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: Text(_lang.translate('save')),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // 基本情報入力エリア
            Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: '問診票タイトル',
                      filled: true,
                      fillColor: Colors.white,
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
                      labelText: '説明文',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            
            // セクション一覧
            Expanded(
              child: _sections.isEmpty
                  ? _buildEmptyState()
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _sections.length,
                      onReorder: _onReorder,
                      itemBuilder: (context, index) {
                        final section = _sections[index];
                        return _buildSectionCard(section, index);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSection,
        icon: const Icon(Icons.add),
        label: Text(_lang.translate('add_section')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.topic_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'セクションがありません',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '「セクション追加」ボタンから大項目を作成してください',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(QuestionSection section, int index) {
    final questionCount = section.questions.length;
    
    return Card(
      key: ValueKey(section.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.drag_handle, color: Theme.of(context).colorScheme.outline),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        title: Text(
          section.title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        subtitle: Text(
          '$questionCount項目${section.description != null ? " • ${section.description}" : ""}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editSection(index),
              tooltip: '編集',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Theme.of(context).colorScheme.error,
              onPressed: () => _deleteSection(index),
              tooltip: _lang.translate('delete'),
            ),
          ],
        ),
        children: [
          if (section.questions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'このセクションには質問がありません',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            )
          else
            ...section.questions.map((question) {
              return ListTile(
                leading: Icon(
                  _getQuestionIcon(question.type),
                  color: Theme.of(context).colorScheme.secondary,
                ),
                title: Text(question.question),
                trailing: question.isRequired
                    ? Chip(
                        label: const Text('必須'),
                        backgroundColor: Theme.of(context).colorScheme.errorContainer,
                        labelStyle: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      )
                    : null,
              );
            }),
        ],
      ),
    );
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
      final section = _sections.removeAt(oldIndex);
      _sections.insert(newIndex, section);
      
      // 順序を更新
      for (int i = 0; i < _sections.length; i++) {
        _sections[i] = QuestionSection(
          id: _sections[i].id,
          title: _sections[i].title,
          description: _sections[i].description,
          questions: _sections[i].questions,
          order: i + 1,
        );
      }
    });
  }

  void _addSection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SectionEditScreen(),
      ),
    );

    if (result != null && result is QuestionSection) {
      setState(() {
        _sections.add(result);
      });
    }
  }

  void _editSection(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SectionEditScreen(section: _sections[index]),
      ),
    );

    if (result != null && result is QuestionSection) {
      setState(() {
        _sections[index] = result;
      });
    }
  }

  void _deleteSection(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_lang.translate('delete_section')),
        content: Text('「${_sections[index].title}」を削除してもよろしいですか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _sections.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_lang.translate('section_deleted'))),
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

    if (_sections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('少なくとも1つのセクションを追加してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final questionnaire = Questionnaire(
      id: widget.questionnaire?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      facilityId: widget.facilityId,
      title: _titleController.text,
      description: _descriptionController.text,
      sections: _sections,
      createdAt: widget.questionnaire?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.pop(context, questionnaire);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_lang.translate('questionnaire_saved'))),
    );
  }
}
