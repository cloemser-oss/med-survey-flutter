import 'package:flutter/material.dart';
import '../../models/patient_info.dart';
import '../../models/patient_basic_info_config.dart';
import '../../services/language_service.dart';
import '../../services/local_storage_service.dart';
import 'questionnaire_selection_screen.dart';

/// 患者基本情報入力画面
/// 
/// 設定に基づいて動的に入力フィールドを生成します。
class PatientInfoInputScreen extends StatefulWidget {
  final String facilityId;
  final String facilityName;

  const PatientInfoInputScreen({
    super.key,
    required this.facilityId,
    required this.facilityName,
  });

  @override
  State<PatientInfoInputScreen> createState() => _PatientInfoInputScreenState();
}

class _PatientInfoInputScreenState extends State<PatientInfoInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final LanguageService _lang = LanguageService();
  
  // コントローラー
  final _patientIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  DateTime? _selectedDateOfBirth;
  final Map<String, TextEditingController> _customControllers = {};
  
  // 設定
  PatientBasicInfoConfig? _config;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _lang.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _lang.removeListener(_onLanguageChanged);
    _patientIdController.dispose();
    _nameController.dispose();
    _weightController.dispose();
    for (var controller in _customControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  Future<void> _loadConfig() async {
    try {
      final storage = LocalStorageService();
      final config = await storage.getPatientBasicInfoConfig(widget.facilityId);
      
      // 既存のカスタムコントローラーを破棄
      for (var controller in _customControllers.values) {
        controller.dispose();
      }
      _customControllers.clear();
      
      // 有効なカスタムフィールドのコントローラーを初期化
      for (var field in config.customFields) {
        if (field.isEnabled) {
          _customControllers[field.id] = TextEditingController();
        }
      }
      
      setState(() {
        _config = config;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 終了確認ダイアログ
  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_lang.translate('confirm')),
        content: Text(_lang.translate('input_not_saved')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_lang.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
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

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // カスタムフィールドの値を収集（有効なもののみ）
    final customFields = <String, String>{};
    if (_config != null) {
      for (var field in _config!.customFields) {
        if (field.isEnabled && _customControllers.containsKey(field.id)) {
          final value = _customControllers[field.id]!.text.trim();
          if (value.isNotEmpty) {
            customFields[field.id] = value;
          }
        }
      }
    }

    final patientInfo = PatientInfo(
      patientId: _config!.includePatientId ? _patientIdController.text.trim() : '',
      name: _config!.includePatientName ? _nameController.text.trim() : '',
      weight: _config!.includeWeight ? double.parse(_weightController.text.trim()) : 0.0,
      dateOfBirth: _config!.includeDateOfBirth ? _selectedDateOfBirth : null,
      customFields: customFields,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuestionnaireSelectionScreen(
          facilityId: widget.facilityId,
          facilityName: widget.facilityName,
          patientInfo: patientInfo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_lang.translate('patient_access_title')),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_config == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_lang.translate('patient_access_title')),
        ),
        body: Center(
          child: Text(_lang.translate('config_not_found')),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_lang.translate('patient_access_title')),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _showExitConfirmation(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 施設名表示
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 説明
                  Text(
                    _lang.translate('patient_basic_info'),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lang.translate('patient_info_instruction'),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),

                  // 動的フィールド生成
                  ..._buildDynamicFields(),

                  const SizedBox(height: 32),

                  // 次へボタン
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _lang.translate('next'),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDynamicFields() {
    final fields = <Widget>[];

    // 患者ID
    if (_config!.includePatientId) {
      fields.addAll([
        TextFormField(
          controller: _patientIdController,
          decoration: InputDecoration(
            labelText: _lang.translate('patient_id'),
            hintText: 'P123456',
            prefixIcon: const Icon(Icons.badge),
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return _lang.translate('enter_patient_id');
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
      ]);
    }

    // 患者氏名
    if (_config!.includePatientName) {
      fields.addAll([
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: _lang.translate('patient_name'),
            hintText: _lang.translate('name_example'),
            prefixIcon: const Icon(Icons.person),
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return _lang.translate('enter_patient_name');
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
      ]);
    }

    // 生年月日
    if (_config!.includeDateOfBirth) {
      fields.addAll([
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDateOfBirth ?? DateTime(2000),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              setState(() {
                _selectedDateOfBirth = date;
              });
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: _lang.translate('date_of_birth'),
              prefixIcon: const Icon(Icons.calendar_today),
              border: const OutlineInputBorder(),
            ),
            child: Text(
              _selectedDateOfBirth != null
                  ? '${_selectedDateOfBirth!.year}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.day}'
                  : _lang.translate('select_date'),
              style: TextStyle(
                color: _selectedDateOfBirth != null ? null : Colors.grey,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ]);
    }

    // 体重
    if (_config!.includeWeight) {
      fields.addAll([
        TextFormField(
          controller: _weightController,
          decoration: InputDecoration(
            labelText: _lang.translate('weight_kg'),
            hintText: '70',
            prefixIcon: const Icon(Icons.monitor_weight),
            suffixText: 'kg',
            border: const OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return _lang.translate('enter_weight');
            }
            final weight = double.tryParse(value.trim());
            if (weight == null) {
              return _lang.translate('weight_must_be_number');
            }
            if (weight <= 0) {
              return _lang.translate('weight_must_be_positive');
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
      ]);
    }

    // カスタムフィールド（有効なもののみ）
    for (var customField in _config!.customFields) {
      if (customField.isEnabled) {
        fields.addAll(_buildCustomField(customField));
      }
    }

    return fields;
  }

  List<Widget> _buildCustomField(CustomField field) {
    // コントローラーが存在しない場合はスキップ（設定変更直後など）
    if (!_customControllers.containsKey(field.id)) {
      return [];
    }
    
    final controller = _customControllers[field.id]!;

    Widget inputWidget;

    switch (field.fieldType) {
      case 'number':
        inputWidget = TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: field.label,
            prefixIcon: const Icon(Icons.numbers),
            border: const OutlineInputBorder(),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: field.isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '${field.label}${_lang.translate('is_required')}';
                  }
                  if (double.tryParse(value.trim()) == null) {
                    return _lang.translate('must_be_number');
                  }
                  return null;
                }
              : null,
        );
        break;

      case 'date':
        DateTime? selectedDate;
        inputWidget = StatefulBuilder(
          builder: (context, setState) {
            return InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  setState(() {
                    selectedDate = date;
                    controller.text = '${date.year}/${date.month}/${date.day}';
                  });
                }
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: field.label,
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: const OutlineInputBorder(),
                ),
                child: Text(
                  controller.text.isEmpty
                      ? _lang.translate('select_date')
                      : controller.text,
                  style: TextStyle(
                    color: controller.text.isEmpty ? Colors.grey : null,
                  ),
                ),
              ),
            );
          },
        );
        break;

      case 'textarea':
        inputWidget = TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: field.label,
            prefixIcon: const Icon(Icons.notes),
            border: const OutlineInputBorder(),
          ),
          maxLines: 4,
          validator: field.isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '${field.label}${_lang.translate('is_required')}';
                  }
                  return null;
                }
              : null,
        );
        break;

      default: // text
        inputWidget = TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: field.label,
            prefixIcon: const Icon(Icons.edit),
            border: const OutlineInputBorder(),
          ),
          validator: field.isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '${field.label}${_lang.translate('is_required')}';
                  }
                  return null;
                }
              : null,
        );
    }

    return [
      inputWidget,
      const SizedBox(height: 24),
    ];
  }
}
