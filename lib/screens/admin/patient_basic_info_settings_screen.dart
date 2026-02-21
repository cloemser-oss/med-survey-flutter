import 'package:flutter/material.dart';
import '../../models/patient_basic_info_config.dart';
import '../../services/local_storage_service.dart';
import '../../services/language_service.dart';

class PatientBasicInfoSettingsScreen extends StatefulWidget {
  final String facilityId;

  const PatientBasicInfoSettingsScreen({
    super.key,
    required this.facilityId,
  });

  @override
  State<PatientBasicInfoSettingsScreen> createState() =>
      _PatientBasicInfoSettingsScreenState();
}

class _PatientBasicInfoSettingsScreenState
    extends State<PatientBasicInfoSettingsScreen> {
  final LanguageService _lang = LanguageService();
  
  bool _includePatientId = true; // 固定（常にtrue）
  bool _includePatientName = true;
  bool _includeDateOfBirth = true; // 固定（常にtrue）
  bool _includeWeight = true;
  List<CustomField> _customFields = [];
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
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  Future<void> _loadConfig() async {
    try {
      final storage = LocalStorageService();
      final config = await storage.getPatientBasicInfoConfig(widget.facilityId);
      
      setState(() {
        _includePatientId = config.includePatientId;
        _includePatientName = config.includePatientName;
        _includeDateOfBirth = config.includeDateOfBirth;
        _includeWeight = config.includeWeight;
        _customFields = config.customFields;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    try {
      final storage = LocalStorageService();
      final config = PatientBasicInfoConfig(
        facilityId: widget.facilityId,
        includePatientId: _includePatientId,
        includePatientName: _includePatientName,
        includeDateOfBirth: _includeDateOfBirth,
        includeWeight: _includeWeight,
        customFields: _customFields,
      );
      
      await storage.savePatientBasicInfoConfig(config);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_lang.translate('settings_saved')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_lang.translate('save_failed')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addCustomField() {
    showDialog(
      context: context,
      builder: (context) => _CustomFieldDialog(
        onAdd: (field) {
          setState(() {
            _customFields.add(field);
          });
        },
      ),
    );
  }

  void _editCustomField(int index) {
    showDialog(
      context: context,
      builder: (context) => _CustomFieldDialog(
        existingField: _customFields[index],
        onAdd: (field) {
          setState(() {
            _customFields[index] = field;
          });
        },
      ),
    );
  }

  void _deleteCustomField(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_lang.translate('confirm_delete')),
        content: Text(_lang.translate('confirm_delete_custom_field')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_lang.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _customFields.removeAt(index);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(_lang.translate('delete')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_lang.translate('patient_basic_info_settings')),
        actions: [
          IconButton(
            onPressed: _saveConfig,
            icon: const Icon(Icons.save),
            tooltip: _lang.translate('save'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 標準項目セクション
                _buildSectionHeader(_lang.translate('standard_fields')),
                const SizedBox(height: 8),
                // 固定項目（変更不可）
                Card(
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(
                          _lang.translate('patient_id'),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text('${_lang.translate('patient_id_hint')} (${_lang.translate('required')})'),
                        leading: const Icon(Icons.lock, color: Colors.grey),
                        trailing: const Icon(Icons.check_circle, color: Colors.green),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: Text(
                          _lang.translate('date_of_birth'),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text('${_lang.translate('date_of_birth_hint')} (${_lang.translate('required')})'),
                        leading: const Icon(Icons.lock, color: Colors.grey),
                        trailing: const Icon(Icons.check_circle, color: Colors.green),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // 切り替え可能な項目
                _buildStandardFieldCard(_lang.translate('patient_name'), 
                    _lang.translate('patient_name_hint'), _includePatientName, (value) {
                  setState(() => _includePatientName = value);
                }),
                const SizedBox(height: 8),
                _buildStandardFieldCard(_lang.translate('weight_kg'), 
                    _lang.translate('weight_hint'), _includeWeight, (value) {
                  setState(() => _includeWeight = value);
                }),
                
                const SizedBox(height: 32),
                
                // カスタム項目セクション
                _buildSectionHeader(_lang.translate('custom_fields')),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addCustomField,
                    icon: const Icon(Icons.add, size: 20),
                    label: Text(_lang.translate('add_field')),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                if (_customFields.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _lang.translate('no_custom_fields'),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _lang.translate('add_custom_field_hint'),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._customFields.asMap().entries.map((entry) {
                    final index = entry.key;
                    final field = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildCustomFieldCard(index, field),
                    );
                  }),
                const SizedBox(height: 100), // 下部に余白を追加
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildStandardFieldCard(String title, String subtitle, bool value, 
      Function(bool) onChanged) {
    return Card(
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildCustomFieldCard(int index, CustomField field) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        field.label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_getFieldTypeLabel(field.fieldType)} • ${field.isRequired ? _lang.translate('required') : _lang.translate('optional')}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: field.isEnabled,
                  onChanged: (value) {
                    setState(() {
                      _customFields[index] = CustomField(
                        id: field.id,
                        label: field.label,
                        fieldType: field.fieldType,
                        isRequired: field.isRequired,
                        isEnabled: value,
                      );
                    });
                  },
                ),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editCustomField(index),
                  icon: const Icon(Icons.edit, size: 18),
                  label: Text(_lang.translate('edit')),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _deleteCustomField(index),
                  icon: const Icon(Icons.delete, size: 18),
                  label: Text(_lang.translate('delete')),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getFieldTypeLabel(String fieldType) {
    switch (fieldType) {
      case 'text':
        return _lang.translate('text');
      case 'number':
        return _lang.translate('number');
      case 'date':
        return _lang.translate('date');
      case 'textarea':
        return _lang.translate('textarea');
      default:
        return fieldType;
    }
  }
}

class _CustomFieldDialog extends StatefulWidget {
  final CustomField? existingField;
  final Function(CustomField) onAdd;

  const _CustomFieldDialog({
    this.existingField,
    required this.onAdd,
  });

  @override
  State<_CustomFieldDialog> createState() => _CustomFieldDialogState();
}

class _CustomFieldDialogState extends State<_CustomFieldDialog> {
  final LanguageService _lang = LanguageService();
  late TextEditingController _labelController;
  late String _fieldType;
  late bool _isRequired;
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(
      text: widget.existingField?.label ?? '',
    );
    _fieldType = widget.existingField?.fieldType ?? 'text';
    _isRequired = widget.existingField?.isRequired ?? false;
    _isEnabled = widget.existingField?.isEnabled ?? true;
    _lang.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _lang.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingField == null
          ? _lang.translate('add_custom_field')
          : _lang.translate('edit_custom_field')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: _lang.translate('field_label'),
                hintText: _lang.translate('enter_field_label'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _fieldType,
              decoration: InputDecoration(
                labelText: _lang.translate('field_type'),
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: 'text',
                  child: Text(_lang.translate('text')),
                ),
                DropdownMenuItem(
                  value: 'number',
                  child: Text(_lang.translate('number')),
                ),
                DropdownMenuItem(
                  value: 'date',
                  child: Text(_lang.translate('date')),
                ),
                DropdownMenuItem(
                  value: 'textarea',
                  child: Text(_lang.translate('textarea')),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _fieldType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(_lang.translate('required')),
              value: _isRequired,
              onChanged: (value) {
                setState(() {
                  _isRequired = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_lang.translate('cancel')),
        ),
        ElevatedButton(
          onPressed: () {
            if (_labelController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_lang.translate('enter_field_label')),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            final field = CustomField(
              id: widget.existingField?.id ?? 
                  DateTime.now().millisecondsSinceEpoch.toString(),
              label: _labelController.text.trim(),
              fieldType: _fieldType,
              isRequired: _isRequired,
              isEnabled: _isEnabled,
            );

            widget.onAdd(field);
            Navigator.pop(context);
          },
          child: Text(_lang.translate('save')),
        ),
      ],
    );
  }
}
