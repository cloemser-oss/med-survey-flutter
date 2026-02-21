import 'package:flutter/material.dart';
import '../../services/language_service.dart';
import 'package:intl/intl.dart';
import '../../services/local_storage_service.dart';
import '../../models/facility.dart';

/// 大元管理者向け医療機関一覧画面
/// すべての登録施設を確認できる特別な画面
class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  final LanguageService _lang = LanguageService();
  List<Facility> _facilities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFacilities();
  }

  Future<void> _loadFacilities() async {
    setState(() {
      _isLoading = true;
    });

    final storage = LocalStorageService();
    final facilities = storage.getAllFacilities();

    setState(() {
      _facilities = facilities;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_lang.translate('facility_list')),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _facilities.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.domain_disabled,
                        size: 80,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '登録されている医療機関はありません',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // サマリーカード
                    Card(
                      margin: const EdgeInsets.all(16),
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryItem(
                              context,
                              Icons.business,
                              '登録施設数',
                              '${_facilities.length}',
                            ),
                            _buildSummaryItem(
                              context,
                              Icons.calendar_today,
                              '最新登録',
                              _getLatestRegistrationDate(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // 施設リスト
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _facilities.length,
                        itemBuilder: (context, index) {
                          final facility = _facilities[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(
                                facility.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.pin,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '施設コード: ${facility.facilityCode}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '登録日: ${DateFormat('yyyy/MM/dd').format(facility.createdAt)}',
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildDetailRow(
                                        Icons.badge,
                                        _lang.translate('facility_id'),
                                        facility.id,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildDetailRow(
                                        Icons.email,
                                        '管理者メール',
                                        facility.adminEmail,
                                      ),
                                      if (facility.address != null) ...[
                                        const SizedBox(height: 8),
                                        _buildDetailRow(
                                          Icons.location_on,
                                          '住所',
                                          facility.address!,
                                        ),
                                      ],
                                      if (facility.phone != null) ...[
                                        const SizedBox(height: 8),
                                        _buildDetailRow(
                                          Icons.phone,
                                          '電話番号',
                                          facility.phone!,
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      const Divider(),
                                      const SizedBox(height: 16),
                                      // 広告設定セクション
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.campaign,
                                            size: 20,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '広告表示設定',
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SwitchListTile(
                                        title: Text(_lang.translate('show_ad')),
                                        subtitle: Text(
                                          facility.advertisement?.isEnabled ?? false
                                              ? '有効'
                                              : '無効',
                                        ),
                                        value: facility.advertisement?.isEnabled ?? false,
                                        onChanged: (value) {
                                          _toggleAdvertisement(facility, value);
                                        },
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      if (facility.advertisement?.isEnabled ?? false) ...[
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (facility.advertisement?.text != null)
                                                Text(
                                                  '広告テキスト: ${facility.advertisement!.text}',
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                ),
                                              if (facility.advertisement?.imageUrl != null)
                                                Text(
                                                  '画像URL: ${facility.advertisement!.imageUrl}',
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          _editAdvertisement(facility);
                                        },
                                        icon: const Icon(Icons.edit, size: 16),
                                        label: Text(_lang.translate('edit_ad_content')),
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(double.infinity, 40),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline,
                                            size: 16,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '患者はこの施設コードで問診票にアクセスします',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadFacilities,
        icon: const Icon(Icons.refresh),
        label: Text(_lang.translate('update')),
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 40,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  String _getLatestRegistrationDate() {
    if (_facilities.isEmpty) {
      return '-';
    }

    final latest = _facilities.reduce((a, b) =>
        a.createdAt.isAfter(b.createdAt) ? a : b);
    return DateFormat('MM/dd').format(latest.createdAt);
  }

  /// 広告表示のON/OFF切り替え
  Future<void> _toggleAdvertisement(Facility facility, bool enabled) async {
    final storage = LocalStorageService();
    
    final updatedFacility = Facility(
      id: facility.id,
      name: facility.name,
      facilityCode: facility.facilityCode,
      address: facility.address,
      phone: facility.phone,
      adminEmail: facility.adminEmail,
      advertisement: Advertisement(
        isEnabled: enabled,
        text: facility.advertisement?.text,
        imageUrl: facility.advertisement?.imageUrl,
        linkUrl: facility.advertisement?.linkUrl,
      ),
      createdAt: facility.createdAt,
    );

    await storage.updateFacility(updatedFacility);
    
    setState(() {
      final index = _facilities.indexWhere((f) => f.id == facility.id);
      if (index != -1) {
        _facilities[index] = updatedFacility;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(enabled ? '広告表示を有効にしました' : '広告表示を無効にしました'),
      ),
    );
  }

  /// 広告内容を編集
  void _editAdvertisement(Facility facility) {
    final textController = TextEditingController(
      text: facility.advertisement?.text ?? '',
    );
    final imageUrlController = TextEditingController(
      text: facility.advertisement?.imageUrl ?? '',
    );
    final linkUrlController = TextEditingController(
      text: facility.advertisement?.linkUrl ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${facility.name}\n広告内容の編集'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  labelText: '広告テキスト',
                  hintText: '例: 次回の検診予約はこちら',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: imageUrlController,
                decoration: InputDecoration(
                  labelText: '画像URL（任意）',
                  hintText: 'https://example.com/image.png',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: linkUrlController,
                decoration: InputDecoration(
                  labelText: 'リンクURL（任意）',
                  hintText: 'https://example.com',
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '医療行為・診断を連想させる表現は禁止されています',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              final storage = LocalStorageService();
              
              final updatedFacility = Facility(
                id: facility.id,
                name: facility.name,
                facilityCode: facility.facilityCode,
                address: facility.address,
                phone: facility.phone,
                adminEmail: facility.adminEmail,
                advertisement: Advertisement(
                  isEnabled: facility.advertisement?.isEnabled ?? false,
                  text: textController.text.isEmpty ? null : textController.text,
                  imageUrl: imageUrlController.text.isEmpty ? null : imageUrlController.text,
                  linkUrl: linkUrlController.text.isEmpty ? null : linkUrlController.text,
                ),
                createdAt: facility.createdAt,
              );

              await storage.updateFacility(updatedFacility);
              
              setState(() {
                final index = _facilities.indexWhere((f) => f.id == facility.id);
                if (index != -1) {
                  _facilities[index] = updatedFacility;
                }
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('広告内容を更新しました'),
                  ),
                );
              }
            },
            child: Text(_lang.translate('save')),
          ),
        ],
      ),
    );
  }
}
