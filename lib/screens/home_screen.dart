import 'package:flutter/material.dart';
import 'admin/admin_login_screen.dart';
import 'admin/super_admin_screen.dart';
import 'patient/patient_access_screen.dart';
import '../services/language_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tapCount = 0;
  final LanguageService _languageService = LanguageService();

  void _onLogoTap() {
    setState(() {
      _tapCount++;
    });

    // 5回タップでパスワード入力ダイアログを表示
    if (_tapCount >= 5) {
      _tapCount = 0;
      _showSuperAdminLogin();
    }
  }

  void _showSuperAdminLogin() {
    final passwordController = TextEditingController();
    
    // 翻訳テキスト
    final title = {
      'ja': 'スーパー管理者ログイン',
      'en': 'Super Admin Login',
      'zh': '超级管理员登录',
      'es': 'Inicio de sesión de súper administrador',
    }[_languageService.currentLanguage] ?? 'スーパー管理者ログイン';
    
    final message = {
      'ja': '管理者専用のアクセスです。\nパスワードを入力してください。',
      'en': 'Admin access only.\nPlease enter password.',
      'zh': '仅限管理员访问。\n请输入密码。',
      'es': 'Acceso solo para administradores.\nIntroduzca la contraseña.',
    }[_languageService.currentLanguage] ?? '管理者専用のアクセスです。\nパスワードを入力してください。';
    
    final passwordLabel = {
      'ja': 'パスワード',
      'en': 'Password',
      'zh': '密码',
      'es': 'Contraseña',
    }[_languageService.currentLanguage] ?? 'パスワード';
    
    final passwordHint = {
      'ja': '管理者パスワード',
      'en': 'Admin password',
      'zh': '管理员密码',
      'es': 'Contraseña de administrador',
    }[_languageService.currentLanguage] ?? '管理者パスワード';
    
    final cancelText = {
      'ja': 'キャンセル',
      'en': 'Cancel',
      'zh': '取消',
      'es': 'Cancelar',
    }[_languageService.currentLanguage] ?? 'キャンセル';
    
    final loginText = {
      'ja': 'ログイン',
      'en': 'Login',
      'zh': '登录',
      'es': 'Iniciar sesión',
    }[_languageService.currentLanguage] ?? 'ログイン';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: passwordLabel,
                hintText: passwordHint,
                prefixIcon: const Icon(Icons.lock),
              ),
              autofocus: true,
              onSubmitted: (value) {
                _verifyAndAccess(context, passwordController.text);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () {
              _verifyAndAccess(context, passwordController.text);
            },
            child: Text(loginText),
          ),
        ],
      ),
    );
  }

  void _verifyAndAccess(BuildContext dialogContext, String password) {
    // スーパー管理者パスワード: C1oemser
    const String correctPassword = 'C1oemser';
    
    if (password == correctPassword) {
      Navigator.pop(dialogContext); // ダイアログを閉じる
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SuperAdminScreen(),
        ),
      );
    } else {
      final errorMessage = {
        'ja': 'パスワードが正しくありません',
        'en': 'Incorrect password',
        'zh': '密码不正确',
        'es': 'Contraseña incorrecta',
      }[_languageService.currentLanguage] ?? 'パスワードが正しくありません';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 言語選択ウィジェット
  Widget _buildLanguageSelector() {
    return PopupMenuButton<String>(
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LanguageService.supportedLanguages[_languageService.currentLanguage]?['flag'] ?? '🇯🇵',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
      onSelected: (String languageCode) {
        setState(() {
          _languageService.changeLanguage(languageCode);
        });
      },
      itemBuilder: (BuildContext context) {
        return LanguageService.supportedLanguages.entries.map((entry) {
          final isSelected = entry.key == _languageService.currentLanguage;
          return PopupMenuItem<String>(
            value: entry.key,
            child: Row(
              children: [
                Text(
                  entry.value['flag'] ?? '',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  entry.value['name'] ?? '',
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Theme.of(context).colorScheme.primary : null,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ],
            ),
          );
        }).toList();
      },
    );
  }

  /// サブタイトル取得
  String _getSubtitle() {
    final translations = {
      'ja': '医療機関向け電子問診票',
      'en': 'Digital Medical Questionnaire',
      'zh': '医疗机构电子问卷',
      'es': 'Cuestionario médico digital',
    };
    return translations[_languageService.currentLanguage] ?? translations['ja']!;
  }

  /// 患者向けタイトル取得
  String _getPatientTitle() {
    final translations = {
      'ja': '患者の方はこちら',
      'en': 'For Patients',
      'zh': '患者请点击这里',
      'es': 'Para pacientes',
    };
    return translations[_languageService.currentLanguage] ?? translations['ja']!;
  }

  /// 患者向けサブタイトル取得
  String _getPatientSubtitle() {
    final translations = {
      'ja': '問診票に回答する',
      'en': 'Answer Questionnaire',
      'zh': '回答问卷',
      'es': 'Responder cuestionario',
    };
    return translations[_languageService.currentLanguage] ?? translations['ja']!;
  }

  /// 管理者向けタイトル取得
  String _getAdminTitle() {
    final translations = {
      'ja': '医療従事者の方はこちら',
      'en': 'For Healthcare Staff',
      'zh': '医务人员请点击这里',
      'es': 'Para personal médico',
    };
    return translations[_languageService.currentLanguage] ?? translations['ja']!;
  }

  /// 管理者向けサブタイトル取得
  String _getAdminSubtitle() {
    final translations = {
      'ja': '管理画面にログイン',
      'en': 'Admin Login',
      'zh': '管理面板登录',
      'es': 'Iniciar sesión en panel',
    };
    return translations[_languageService.currentLanguage] ?? translations['ja']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // 言語選択アイコン
          _buildLanguageSelector(),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ロゴとタイトル
              GestureDetector(
                onTap: _onLogoTap,
                child: Icon(
                  Icons.medical_services_rounded,
                  size: 100,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Med Survey',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _getSubtitle(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 64),

              // 患者向けボタン
              Card(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PatientAccessScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getPatientTitle(),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getPatientSubtitle(),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 医療従事者向けボタン
              Card(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminLoginScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.admin_panel_settings_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getAdminTitle(),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getAdminSubtitle(),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
