import 'package:flutter/material.dart';
import '../../services/language_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'questionnaire_list_screen.dart';
import 'response_list_screen.dart';
import 'facility_settings_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String facilityId;
  final String facilityName;

  const AdminDashboardScreen({
    super.key,
    required this.facilityId,
    required this.facilityName,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final LanguageService _lang = LanguageService();
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      QuestionnaireListScreen(facilityId: widget.facilityId),
      ResponseListScreen(facilityId: widget.facilityId),
      FacilitySettingsScreen(
        facilityId: widget.facilityId,
        facilityName: widget.facilityName,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.facilityName),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded),
            onPressed: _showQRCode,
            tooltip: '患者アクセス用QRコード',
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: '問診票管理',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: '回答一覧',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }

  void _showQRCode() {
    // デモ用のURL (実際はこの施設の問診票URLを生成)
    final qrData = 'https://med-survey.example.com/patient/${widget.facilityId}';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '患者アクセス用QRコード',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 250,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '患者の方はこのQRコードを読み取って問診票にアクセスできます',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
