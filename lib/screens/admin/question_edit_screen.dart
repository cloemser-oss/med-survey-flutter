import 'package:flutter/material.dart';
import '../../services/language_service.dart';
import '../../models/questionnaire.dart';

class QuestionEditScreen extends StatefulWidget {
  final QuestionItem? question;

  const QuestionEditScreen({
    super.key,
    this.question,
  });

  @override
  State<QuestionEditScreen> createState() => _QuestionEditScreenState();
}

class _QuestionEditScreenState extends State<QuestionEditScreen> {
  final LanguageService _lang = LanguageService();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _questionController;
  late TextEditingController _detailPromptController;
  late QuestionType _selectedType;
  late bool _isRequired;
  late bool _showDetailOnYes;
  final List<TextEditingController> _optionControllers = [];

  @override
  void initState() {
    super.initState();
    _questionController =
        TextEditingController(text: widget.question?.question ?? '');
    _detailPromptController =
        TextEditingController(text: widget.question?.detailPrompt ?? '詳しく教えてください');
    _selectedType = widget.question?.type ?? QuestionType.yesNo;
    _isRequired = widget.question?.isRequired ?? true;
    _showDetailOnYes = widget.question?.showDetailOnYes ?? false;

    if (widget.question?.options != null) {
      for (final option in widget.question!.options!) {
        _optionControllers.add(TextEditingController(text: option));
      }
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _detailPromptController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.question == null ? '新規質問' : '質問編集'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: Text(_lang.translate('complete')),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 質問文入力
              TextFormField(
                controller: _questionController,
                decoration: InputDecoration(
                  labelText: '質問文',
                  hintText: '例: 心臓ペースメーカーを装着していますか',
                  prefixIcon: Icon(Icons.help_outline),
                ),
                maxLines: 3,
                style: const TextStyle(fontSize: 16),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '質問文を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 質問タイプ選択
              Text(
                '質問タイプ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...QuestionType.values.map((type) {
                return RadioListTile<QuestionType>(
                  value: type,
                  groupValue: _selectedType,
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value!;
                    });
                  },
                  title: Text(_getQuestionTypeLabel(type)),
                  subtitle: Text(_getQuestionTypeDescription(type)),
                  secondary: Icon(_getQuestionIcon(type)),
                );
              }),
              const SizedBox(height: 24),

              // 選択肢入力(選択式の場合のみ)
              if (_selectedType == QuestionType.singleChoice ||
                  _selectedType == QuestionType.multipleChoice) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '選択肢',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    TextButton.icon(
                      onPressed: _addOption,
                      icon: const Icon(Icons.add),
                      label: Text(_lang.translate('add')),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_optionControllers.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        '選択肢を追加してください',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  )
                else
                  ...List.generate(_optionControllers.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _optionControllers[index],
                              decoration: InputDecoration(
                                labelText: '選択肢 ${index + 1}',
                                prefixIcon: const Icon(Icons.label),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '選択肢を入力してください';
                                }
                                return null;
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Theme.of(context).colorScheme.error,
                            onPressed: () => _removeOption(index),
                          ),
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 24),
              ],

              // オプション設定
              Text(
                'オプション',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: Text(_lang.translate('required_field')),
                subtitle: Text(_lang.translate('required_answer')),
                value: _isRequired,
                onChanged: (value) {
                  setState(() {
                    _isRequired = value;
                  });
                },
              ),
              if (_selectedType == QuestionType.yesNo)
                SwitchListTile(
                  title: Text(_lang.translate('show_detail_on_yes')),
                  subtitle: Text(_lang.translate('yes_answer_detail')),
                  value: _showDetailOnYes,
                  onChanged: (value) {
                    setState(() {
                      _showDetailOnYes = value;
                    });
                  },
                ),
              
              // 詳細入力欄のコメント編集
              if (_selectedType == QuestionType.yesNo && _showDetailOnYes)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: TextFormField(
                    controller: _detailPromptController,
                    decoration: InputDecoration(
                      labelText: '詳細入力欄のプロンプト',
                      hintText: '例: 詳しく教えてください',
                      prefixIcon: Icon(Icons.comment),
                      border: OutlineInputBorder(),
                      helperText: '詳細入力欄に表示されるコメントを編集できます',
                    ),
                    maxLines: 2,
                  ),
                ),
              const SizedBox(height: 24),

              // プレビュー
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.preview,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'プレビュー',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildPreview(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (_isRequired)
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
            if (_isRequired) const SizedBox(width: 8),
            Expanded(
              child: Text(
                _questionController.text.isEmpty
                    ? '(質問文がここに表示されます)'
                    : _questionController.text,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _questionController.text.isEmpty
                          ? Theme.of(context).colorScheme.outline
                          : null,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_selectedType == QuestionType.yesNo) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.check_circle),
                  label: Text(_lang.translate('yes')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.cancel),
                  label: Text(_lang.translate('no')),
                ),
              ),
            ],
          ),
          if (_showDetailOnYes) ...[
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: _detailPromptController.text.isEmpty 
                    ? '詳しく教えてください'
                    : _detailPromptController.text,
                hintText: '詳細を入力',
                enabled: false,
              ),
              maxLines: 2,
            ),
          ],
        ] else if (_selectedType == QuestionType.singleChoice) ...[
          if (_optionControllers.isEmpty)
            Text(
              '(選択肢がありません)',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            )
          else
            ..._optionControllers.map((controller) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: OutlinedButton(
                  onPressed: () {},
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(controller.text.isEmpty ? '(選択肢)' : controller.text),
                  ),
                ),
              );
            }),
        ] else if (_selectedType == QuestionType.multipleChoice) ...[
          if (_optionControllers.isEmpty)
            Text(
              '(選択肢がありません)',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            )
          else
            ..._optionControllers.map((controller) {
              return CheckboxListTile(
                value: false,
                onChanged: null,
                title: Text(controller.text.isEmpty ? '(選択肢)' : controller.text),
                controlAffinity: ListTileControlAffinity.leading,
              );
            }),
        ] else if (_selectedType == QuestionType.freeText) ...[
          const TextField(
            decoration: InputDecoration(
              hintText: '自由に記入してください',
              enabled: false,
            ),
            maxLines: 3,
          ),
        ],
      ],
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

  String _getQuestionTypeDescription(QuestionType type) {
    switch (type) {
      case QuestionType.yesNo:
        return '「はい」または「いいえ」で回答';
      case QuestionType.singleChoice:
        return '複数の選択肢から1つを選択';
      case QuestionType.multipleChoice:
        return '複数の選択肢から複数選択可能';
      case QuestionType.freeText:
        return '自由にテキストを入力';
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

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if ((_selectedType == QuestionType.singleChoice ||
            _selectedType == QuestionType.multipleChoice) &&
        _optionControllers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('少なくとも1つの選択肢を追加してください'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final options = (_selectedType == QuestionType.singleChoice ||
            _selectedType == QuestionType.multipleChoice)
        ? _optionControllers.map((c) => c.text).toList()
        : null;

    final question = QuestionItem(
      id: widget.question?.id ??
          'q_${DateTime.now().millisecondsSinceEpoch}',
      question: _questionController.text,
      type: _selectedType,
      isRequired: _isRequired,
      options: options,
      showDetailOnYes: _selectedType == QuestionType.yesNo ? _showDetailOnYes : false,
      detailPrompt: _selectedType == QuestionType.yesNo && _showDetailOnYes && _detailPromptController.text.isNotEmpty
          ? _detailPromptController.text
          : null,
      order: widget.question?.order ?? 1,
    );

    Navigator.pop(context, question);
  }
}
