import 'dart:convert';
import 'dart:html' as html;
import '../../services/language_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/patient_response.dart';
import '../../models/questionnaire.dart';
import '../../services/local_storage_service.dart';

class ResponseListScreen extends StatefulWidget {
  final String facilityId;

  const ResponseListScreen({
    super.key,
    required this.facilityId,
  });

  @override
  State<ResponseListScreen> createState() => _ResponseListScreenState();
}

class _ResponseListScreenState extends State<ResponseListScreen> {
  final LanguageService _lang = LanguageService();
  List<PatientResponse> _allResponses = [];
  List<PatientResponse> _filteredResponses = [];
  bool _isLoading = true;
  
  // 検索フィルター
  final _nameSearchController = TextEditingController();
  final _patientIdController = TextEditingController();
  DateTime? _dateOfBirthFilter; // 生年月日フィルター
  DateTime? _startDate;
  DateTime? _endDate;
  bool _showOnlyYesAnswers = false;
  String? _selectedQuestionnaireId; // 問診票フィルタ
  List<Questionnaire> _questionnaires = []; // 問診票リスト
  
  // 選択機能
  Set<String> _selectedResponseIds = {};
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadResponses();
  }

  @override
  void dispose() {
    _nameSearchController.dispose();
    _patientIdController.dispose();
    super.dispose();
  }

  Future<void> _loadResponses() async {
    setState(() {
      _isLoading = true;
    });

    final storage = LocalStorageService();
    final responses = await storage.getPatientResponses(widget.facilityId);
    final questionnaires = await storage.getQuestionnaires(widget.facilityId);

    setState(() {
      _allResponses = responses;
      _filteredResponses = responses;
      _questionnaires = questionnaires;
      _isLoading = false;
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredResponses = _allResponses.where((response) {
        // 患者ID専用フィルター
        if (_patientIdController.text.isNotEmpty) {
          final searchText = _patientIdController.text.toLowerCase();
          final patientId = response.patientId.toLowerCase();
          if (!patientId.contains(searchText)) {
            return false;
          }
        }

        // 名前フィルター
        if (_nameSearchController.text.isNotEmpty) {
          final searchText = _nameSearchController.text.toLowerCase();
          final name = response.patientName.toLowerCase();
          if (!name.contains(searchText)) {
            return false;
          }
        }

        // 生年月日フィルター
        if (_dateOfBirthFilter != null && response.dateOfBirth != null) {
          final filterDate = DateTime(
            _dateOfBirthFilter!.year,
            _dateOfBirthFilter!.month,
            _dateOfBirthFilter!.day,
          );
          final responseDate = DateTime(
            response.dateOfBirth!.year,
            response.dateOfBirth!.month,
            response.dateOfBirth!.day,
          );
          if (filterDate != responseDate) {
            return false;
          }
        }

        // 回答日付フィルター
        if (_startDate != null) {
          if (response.submittedAt.isBefore(_startDate!)) {
            return false;
          }
        }
        if (_endDate != null) {
          final endOfDay = DateTime(
            _endDate!.year,
            _endDate!.month,
            _endDate!.day,
            23,
            59,
            59,
          );
          if (response.submittedAt.isAfter(endOfDay)) {
            return false;
          }
        }

        // Yes回答のみ表示
        if (_showOnlyYesAnswers) {
          if (response.getYesAnswers().isEmpty) {
            return false;
          }
        }

        // 問診票フィルター
        if (_selectedQuestionnaireId != null) {
          if (response.questionnaireId != _selectedQuestionnaireId) {
            return false;
          }
        }

        return true;
      }).toList();

      // 新しい順にソート
      _filteredResponses.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    });
  }

  void _clearFilters() {
    setState(() {
      _nameSearchController.clear();
      _patientIdController.clear();
      _dateOfBirthFilter = null;
      _startDate = null;
      _endDate = null;
      _showOnlyYesAnswers = false;
      _selectedQuestionnaireId = null;
      _filteredResponses = _allResponses;
    });
  }

  /// 当日を選択
  void _selectToday() {
    setState(() {
      final now = DateTime.now();
      _startDate = DateTime(now.year, now.month, now.day);
      _endDate = DateTime(now.year, now.month, now.day);
    });
    _applyFilters();
  }

  /// 過去一週間を選択
  void _selectLastWeek() {
    setState(() {
      final now = DateTime.now();
      _endDate = DateTime(now.year, now.month, now.day);
      _startDate = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
    });
    _applyFilters();
  }

  /// 過去一か月を選択
  void _selectLastMonth() {
    setState(() {
      final now = DateTime.now();
      _endDate = DateTime(now.year, now.month, now.day);
      _startDate = DateTime(now.year, now.month - 1, now.day);
    });
    _applyFilters();
  }

  Future<void> _exportToPDF(PatientResponse response) async {
    // 単一PDF出力（既存機能維持）
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PDF出力機能は今後実装予定です'),
      ),
    );
  }

  Future<void> _exportAllToCSV() async {
    try {
      // 全件CSV出力
      final csvData = _generateCSVData(_filteredResponses);
      
      // ダウンロードリンクを作成（Web用）
      _downloadCSV(csvData, 'questionnaire_responses_all.csv');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_filteredResponses.length}件の回答をCSV出力しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV出力に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportSelectedToCSV() async {
    try {
      final selectedResponses = _filteredResponses
          .where((r) => _selectedResponseIds.contains(r.id))
          .toList();
      
      if (selectedResponses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('回答を選択してください')),
        );
        return;
      }
      
      final csvData = _generateCSVData(selectedResponses);
      _downloadCSV(csvData, 'questionnaire_responses_selected.csv');
      
      if (mounted) {
        setState(() {
          _isSelectionMode = false;
          _selectedResponseIds.clear();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedResponses.length}件の回答をCSV出力しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV出力に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _exportSelectedToPDF() async {
    try {
      final selectedResponses = _filteredResponses
          .where((r) => _selectedResponseIds.contains(r.id))
          .toList();
      
      if (selectedResponses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('回答を選択してください')),
        );
        return;
      }
      
      // TODO: PDF一括出力実装
      if (mounted) {
        setState(() {
          _isSelectionMode = false;
          _selectedResponseIds.clear();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedResponses.length}件の回答をPDF出力しました（実装予定）'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF出力に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _generateCSVData(List<PatientResponse> responses) {
    final buffer = StringBuffer();
    
    // CSVヘッダー
    buffer.writeln('患者ID,氏名,体重(kg),回答日時,確認済み,問診票ID,Yes回答数');
    
    // データ行
    for (final response in responses) {
      final yesCount = response.getYesAnswers().length;
      buffer.writeln([
        response.patientId,
        response.patientName,
        response.weight,
        DateFormat('yyyy-MM-dd HH:mm:ss').format(response.submittedAt),
        response.isConfirmed ? _lang.translate('yes') : _lang.translate('no'),
        response.questionnaireId,
        yesCount,
      ].join(','));
    }
    
    return buffer.toString();
  }

  void _downloadCSV(String csvData, String filename) {
    // Web用ダウンロード処理
    // ignore: avoid_web_libraries_in_flutter
    try {
      final bytes = utf8.encode(csvData);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      if (kDebugMode) {
        print('CSV download error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 検索フィルターエリア
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '検索・フィルター',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      if (_nameSearchController.text.isNotEmpty ||
                          _startDate != null ||
                          _endDate != null ||
                          _showOnlyYesAnswers ||
                          _selectedQuestionnaireId != null)
                        TextButton.icon(
                          onPressed: _clearFilters,
                          icon: const Icon(Icons.clear),
                          label: const Text('クリア'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 患者ID検索
                  TextField(
                    controller: _patientIdController,
                    decoration: InputDecoration(
                      labelText: '患者IDで検索',
                      hintText: '例: P12345',
                      prefixIcon: const Icon(Icons.badge),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _applyFilters,
                      ),
                    ),
                    onSubmitted: (_) => _applyFilters(),
                  ),
                  const SizedBox(height: 16),
                  
                  // 患者名検索
                  TextField(
                    controller: _nameSearchController,
                    decoration: InputDecoration(
                      labelText: '患者名で検索',
                      hintText: '例: 山田太郎',
                      prefixIcon: const Icon(Icons.person_search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _applyFilters,
                      ),
                    ),
                    onSubmitted: (_) => _applyFilters(),
                  ),
                  const SizedBox(height: 16),
                  
                  // 生年月日検索
                  OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _dateOfBirthFilter ?? DateTime(1990),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _dateOfBirthFilter = date;
                        });
                        _applyFilters();
                      }
                    },
                    icon: const Icon(Icons.cake),
                    label: Text(
                      _dateOfBirthFilter == null
                          ? '生年月日で検索'
                          : '生年月日: ${DateFormat('yyyy/MM/dd').format(_dateOfBirthFilter!)}',
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 回答日付範囲
                  Text(
                    '回答日付範囲',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _startDate = date;
                              });
                              _applyFilters();
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _startDate == null
                                ? _lang.translate('start_date')
                                : DateFormat('yyyy/MM/dd').format(_startDate!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('〜'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() {
                                _endDate = date;
                              });
                              _applyFilters();
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            _endDate == null
                                ? _lang.translate('end_date')
                                : DateFormat('yyyy/MM/dd').format(_endDate!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // 日付クイック選択
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectToday,
                          icon: const Icon(Icons.today, size: 18),
                          label: Text(_lang.translate('today'), style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectLastWeek,
                          icon: const Icon(Icons.date_range, size: 18),
                          label: const Text('過去一週間', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _selectLastMonth,
                          icon: const Icon(Icons.calendar_month, size: 18),
                          label: const Text('過去一か月', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // 問診票選択
                  if (_questionnaires.isNotEmpty)
                    DropdownButtonFormField<String?>(
                      value: _selectedQuestionnaireId,
                      decoration: InputDecoration(
                        labelText: _lang.translate('filter_by_questionnaire'),
                        prefixIcon: Icon(Icons.assignment),
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(_lang.translate('all_questionnaires')),
                        ),
                        ..._questionnaires.map((q) => DropdownMenuItem<String?>(
                          value: q.id,
                          child: Text(q.title),
                        )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedQuestionnaireId = value;
                        });
                        _applyFilters();
                      },
                    ),
                  const SizedBox(height: 16),
                  
                  // Yes回答のみ表示
                  CheckboxListTile(
                    title: const Text('Yes回答がある回答のみ表示'),
                    subtitle: Text(_lang.translate('prioritize_important')),
                    value: _showOnlyYesAnswers,
                    onChanged: (value) {
                      setState(() {
                        _showOnlyYesAnswers = value ?? false;
                      });
                      _applyFilters();
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
          ),
          
          // 一括エクスポートボタン（常に表示）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (_isSelectionMode)
                  Text(
                    '${_selectedResponseIds.length}件選択中',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                else
                  Text(
                    '${_filteredResponses.length}件の回答',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                const Spacer(),
                if (_isSelectionMode) ...[
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSelectionMode = false;
                        _selectedResponseIds.clear();
                      });
                    },
                    child: Text(_lang.translate('cancel')),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _selectedResponseIds.isEmpty ? null : _exportSelectedToCSV,
                    icon: const Icon(Icons.file_download),
                    label: Text(_lang.translate('export_csv')),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _selectedResponseIds.isEmpty ? null : _exportSelectedToPDF,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: Text(_lang.translate('export_pdf')),
                  ),
                ] else ...[
                  OutlinedButton.icon(
                    onPressed: _filteredResponses.isEmpty 
                        ? null 
                        : () {
                            setState(() {
                              _isSelectionMode = true;
                            });
                          },
                    icon: const Icon(Icons.checklist),
                    label: Text(_lang.translate('selection_mode')),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _filteredResponses.isEmpty ? null : _exportAllToCSV,
                    icon: const Icon(Icons.download),
                    label: Text(_lang.translate('export_all_csv')),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // 回答リスト
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredResponses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 80,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _allResponses.isEmpty
                                  ? _lang.translate('no_responses')
                                  : _lang.translate('no_matching_responses'),
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _allResponses.isEmpty
                                  ? '患者が問診票に回答すると、ここに表示されます'
                                  : '別の検索条件をお試しください',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredResponses.length,
                        itemBuilder: (context, index) {
                          final response = _filteredResponses[index];
                          final yesAnswers = response.getYesAnswers();
                          final hasYesAnswers = yesAnswers.isNotEmpty;

                          return Card(
                            elevation: hasYesAnswers ? 4 : 1,
                            color: hasYesAnswers
                                ? Colors.orange.shade50
                                : null,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              onTap: _isSelectionMode 
                                  ? () {
                                      setState(() {
                                        if (_selectedResponseIds.contains(response.id)) {
                                          _selectedResponseIds.remove(response.id);
                                        } else {
                                          _selectedResponseIds.add(response.id);
                                        }
                                      });
                                    }
                                  : () => _showResponseDetail(response),
                              leading: _isSelectionMode
                                  ? Checkbox(
                                      value: _selectedResponseIds.contains(response.id),
                                      onChanged: (checked) {
                                        setState(() {
                                          if (checked == true) {
                                            _selectedResponseIds.add(response.id);
                                          } else {
                                            _selectedResponseIds.remove(response.id);
                                          }
                                        });
                                      },
                                    )
                                  : CircleAvatar(
                                      backgroundColor: hasYesAnswers
                                          ? Colors.orange
                                          : Theme.of(context).colorScheme.primary,
                                      child: Icon(
                                        hasYesAnswers
                                            ? Icons.warning
                                            : Icons.check_circle,
                                        color: Colors.white,
                                      ),
                                    ),
                              title: Text(
                                response.patientName,
                                style: TextStyle(
                                  fontWeight: hasYesAnswers
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '患者ID: ${response.patientId} | 体重: ${response.weight} kg',
                                  ),
                                  Text(
                                    '回答日時: ${DateFormat('yyyy/MM/dd HH:mm').format(response.submittedAt)}',
                                  ),
                                  Row(
                                    children: [
                                      if (hasYesAnswers)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '⚠️ Yes回答: ${yesAnswers.length}件',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      if (hasYesAnswers && response.isConfirmed) const SizedBox(width: 8),
                                      if (response.isConfirmed)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.check_circle, size: 14, color: Colors.white),
                                              SizedBox(width: 4),
                                              Text(
                                                _lang.translate('confirmed'),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  // メモ表示
                                  if (response.staffMemo != null && response.staffMemo!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.note, size: 14, color: Colors.blue),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              '📝 ${response.staffMemo}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue,
                                                fontStyle: FontStyle.italic,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.picture_as_pdf),
                                tooltip: _lang.translate('export_pdf'),
                                onPressed: () => _exportToPDF(response),
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showResponseDetail(PatientResponse response) async {
    // 問診票データを取得して質問IDと質問内容をマッピング
    final storage = LocalStorageService();
    final questionnaires = await storage.getQuestionnaires(widget.facilityId);
    final questionnaire = questionnaires.firstWhere(
      (q) => q.id == response.questionnaireId,
      orElse: () => questionnaires.first,
    );

    // 質問IDから質問内容へのマッピングを作成
    final questionMap = <String, String>{};
    for (final section in questionnaire.sections) {
      for (final question in section.questions) {
        questionMap[question.id] = question.question;
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(response.patientName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _lang.translate('patient_basic_info'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _showEditBasicInfoDialog(response);
                    },
                    icon: const Icon(Icons.edit),
                    tooltip: _lang.translate('edit_basic_info'),
                    color: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildDetailRow(_lang.translate('patient_id'), response.patientId),
              _buildDetailRow(_lang.translate('patient_name'), response.patientName),
              if (response.dateOfBirth != null)
                _buildDetailRow(_lang.translate('date_of_birth'), DateFormat('yyyy/MM/dd').format(response.dateOfBirth!)),
              _buildDetailRow(_lang.translate('weight_kg'), '${response.weight} kg'),
              _buildDetailRow(_lang.translate('submission_time'), DateFormat('yyyy/MM/dd HH:mm').format(response.submittedAt)),
              const Divider(),
              Text(
                _lang.translate('answer_content'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...response.answers.entries.map((entry) {
                final answer = entry.value;
                final questionText = questionMap[entry.key] ?? entry.key;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                questionText,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () async {
                                Navigator.pop(context);
                                await _showEditAnswerDialog(response, entry.key, questionText, answer);
                              },
                              tooltip: _lang.translate('edit_answer'),
                              color: Colors.blue,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('${_lang.translate('answer')}: ${answer.value}'),
                        if (answer.detail != null && answer.detail!.isNotEmpty)
                          Text('${_lang.translate('detail')}: ${answer.detail}'),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_lang.translate('close')),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              await _showMemoDialog(response);
            },
            icon: const Icon(Icons.edit_note),
            label: Text(_lang.translate('memo')),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _toggleConfirmStatus(response);
            },
            icon: Icon(response.isConfirmed ? Icons.check_circle : Icons.check_circle_outline),
            label: Text(response.isConfirmed ? _lang.translate('confirmed') : _lang.translate('confirm')),
            style: OutlinedButton.styleFrom(
              foregroundColor: response.isConfirmed ? Colors.green : Colors.blue,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _exportToPDF(response);
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(_lang.translate('export_pdf')),
          ),
        ],
      ),
    );
  }

  /// 送信済み状態を解除
  Future<void> _clearSubmittedStatus(PatientResponse response) async {
    try {
      final storage = LocalStorageService();
      await storage.clearSubmittedStatus(
        widget.facilityId,
        response.patientId,
        response.dateOfBirth?.toIso8601String(),
        response.questionnaireId,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${response.patientName}さんの送信済み状態を解除しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('送信済み解除に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 確認状態をトグル（送信済み解除も同時実行）
  Future<void> _toggleConfirmStatus(PatientResponse response) async {
    try {
      final storage = LocalStorageService();
      if (response.isConfirmed) {
        await storage.unmarkResponseAsConfirmed(widget.facilityId, response.id);
      } else {
        await storage.markResponseAsConfirmed(widget.facilityId, response.id);
        // 確認済みにする際、送信済み状態も解除
        await storage.clearSubmittedStatus(
        widget.facilityId,
        response.patientId,
        response.dateOfBirth?.toIso8601String(),
        response.questionnaireId,
      );
      }
      
      // リストを再読み込み
      await _loadResponses();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.isConfirmed
                  ? '${response.patientName}さんの確認済み状態を解除しました'
                  : '${response.patientName}さんを確認済にしました（送信済み解除）',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('確認状態の更新に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// メモダイアログを表示
  Future<void> _showMemoDialog(PatientResponse response) async {
    final memoController = TextEditingController(text: response.staffMemo ?? '');
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_lang.translate('staff_memo')),
        content: TextField(
          controller: memoController,
          decoration: InputDecoration(
            hintText: '特記事項を入力してください',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_lang.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, memoController.text),
            child: Text(_lang.translate('save')),
          ),
        ],
      ),
    );
    
    if (result != null) {
      try {
        final storage = LocalStorageService();
        await storage.updateStaffMemo(widget.facilityId, response.id, result);
        await _loadResponses();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('メモを保存しました'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('メモの保存に失敗しました: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    
    memoController.dispose();
  }

  /// 患者基本情報編集ダイアログを表示
  Future<void> _showEditBasicInfoDialog(PatientResponse response) async {
    final patientIdController = TextEditingController(text: response.patientId);
    final patientNameController = TextEditingController(text: response.patientName);
    final weightController = TextEditingController(text: response.weight.toString());
    DateTime? selectedDateOfBirth = response.dateOfBirth;
    final formKey = GlobalKey<FormState>();
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(_lang.translate('edit_basic_info')),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: patientIdController,
                    decoration: InputDecoration(
                      labelText: _lang.translate('patient_id'),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return _lang.translate('enter_patient_id');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: patientNameController,
                    decoration: InputDecoration(
                      labelText: _lang.translate('patient_name'),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return _lang.translate('enter_patient_name');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDateOfBirth ?? DateTime(2000),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          selectedDateOfBirth = date;
                        });
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: _lang.translate('date_of_birth'),
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        selectedDateOfBirth != null
                            ? DateFormat('yyyy/MM/dd').format(selectedDateOfBirth!)
                            : _lang.translate('select_date'),
                        style: TextStyle(
                          color: selectedDateOfBirth != null ? null : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: weightController,
                    decoration: InputDecoration(
                      labelText: _lang.translate('weight_kg'),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return _lang.translate('enter_weight');
                      }
                      final weight = double.tryParse(value);
                      if (weight == null) {
                        return _lang.translate('weight_must_be_number');
                      }
                      if (weight <= 0) {
                        return _lang.translate('weight_must_be_positive');
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(_lang.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context, {
                    'patientId': patientIdController.text.trim(),
                    'patientName': patientNameController.text.trim(),
                    'dateOfBirth': selectedDateOfBirth,
                    'weight': double.parse(weightController.text.trim()),
                  });
                }
              },
              child: Text(_lang.translate('save')),
            ),
          ],
        ),
      ),
    );
    
    if (result != null) {
      try {
        final storage = LocalStorageService();
        await storage.updatePatientBasicInfo(
          facilityId: widget.facilityId,
          responseId: response.id,
          patientId: result['patientId'],
          patientName: result['patientName'],
          weight: result['weight'],
          dateOfBirth: result['dateOfBirth'],
        );
        await _loadResponses();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_lang.translate('patient_info_updated')),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_lang.translate('basic_info_update_failed')}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    
    patientIdController.dispose();
    patientNameController.dispose();
    weightController.dispose();
  }

  /// 回答編集ダイアログを表示
  Future<void> _showEditAnswerDialog(
    PatientResponse response,
    String questionId,
    String questionText,
    Answer currentAnswer,
  ) async {
    final valueController = TextEditingController(text: currentAnswer.value);
    final detailController = TextEditingController(text: currentAnswer.detail ?? '');
    final formKey = GlobalKey<FormState>();
    
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_lang.translate('edit_answer')),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  questionText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: valueController,
                  decoration: InputDecoration(
                    labelText: _lang.translate('answer'),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return _lang.translate('enter_answer');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: detailController,
                  decoration: InputDecoration(
                    labelText: '${_lang.translate('detail')} (${_lang.translate('optional')})',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(_lang.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, {
                  'value': valueController.text.trim(),
                  'detail': detailController.text.trim(),
                });
              }
            },
            child: Text(_lang.translate('save')),
          ),
        ],
      ),
    );
    
    if (result != null) {
      try {
        final storage = LocalStorageService();
        await storage.updatePatientAnswer(
          facilityId: widget.facilityId,
          responseId: response.id,
          questionId: questionId,
          value: result['value']!,
          detail: result['detail']!.isEmpty ? null : result['detail'],
        );
        await _loadResponses();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_lang.translate('answer_updated')),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_lang.translate('answer_update_failed')}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    
    valueController.dispose();
    detailController.dispose();
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
