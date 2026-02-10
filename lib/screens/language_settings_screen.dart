import 'package:flutter/material.dart';
import 'package:needsfine_app/main.dart'; // appLocaleNotifier 사용을 위해 import

// ✅ 다국어 패키지 임포트
import 'package:needsfine_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  // 현재 선택된 언어 (임시 저장용)
  late Locale _selectedLocale;

  // ✅ 9개국어 지원 (한국어, 영어, 일본어, 중국어, 스페인어, 아랍어, 포르투갈어, 인도네시아어, 미얀마어)
  final List<Map<String, dynamic>> _languages = [
    {'name': '한국어', 'code': 'ko', 'country': 'KR'},
    {'name': '영어 English', 'code': 'en', 'country': null},
    {'name': '日本語', 'code': 'ja', 'country': null},
    {'name': '中文', 'code': 'zh', 'country': null},
    {'name': 'Español', 'code': 'es', 'country': null},
    {'name': 'العربية', 'code': 'ar', 'country': null},
    {'name': 'Português', 'code': 'pt', 'country': null},
    {'name': 'Bahasa Indonesia', 'code': 'id', 'country': null},
    {'name': 'မြန်မာစာ', 'code': 'my', 'country': null},
  ];

  @override
  void initState() {
    super.initState();
    // 현재 적용된 언어 가져오기 (없으면 기본값 한국어)
    _selectedLocale = appLocaleNotifier.value ?? const Locale('ko', 'KR');
  }

  Future<void> _applyLanguage() async {
    // ✅ 전역 변수 업데이트 -> 앱 전체 언어 변경
    appLocaleNotifier.value = _selectedLocale;
    
    // ✅ 저장 (Persistence)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', _selectedLocale.languageCode);

    if (mounted) Navigator.pop(context); // 화면 닫기
  }

  @override
  Widget build(BuildContext context) {
    // ✅ l10n 객체 가져오기
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        // "언어 설정"
        title: Text(l10n.languageSettings, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _applyLanguage,
            // "적용"
            child: Text(
              l10n.apply,
              style: const TextStyle(
                color: Color(0xFF8A2BE2), // NeedsFine Color
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: _languages.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, index) {
          final lang = _languages[index];
          // 언어 코드와 국가 코드로 Locale 생성
          final itemLocale = Locale(lang['code'], lang['country']);

          // 현재 선택된 상태인지 확인 (언어 코드만 비교)
          final isSelected = _selectedLocale.languageCode == lang['code'];

          return Container(
            color: Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              title: Text(
                lang['name'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: Colors.black87,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: Color(0xFF8A2BE2)) // ✅ 니즈파인색 체크
                  : null,
              onTap: () {
                setState(() {
                  _selectedLocale = itemLocale;
                });
              },
            ),
          );
        },
      ),
    );
  }
}