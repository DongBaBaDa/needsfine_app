import 'package:flutter/material.dart';
import 'package:needsfine_app/main.dart'; // appLocaleNotifier 사용을 위해 import

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  // 현재 선택된 언어 (임시 저장용)
  late Locale _selectedLocale;

  // 가나다순 정렬: 미얀마어(ㅁ) -> 영어(ㅇ) -> 한국어(ㅎ)
  final List<Map<String, dynamic>> _languages = [
    {'name': '미얀마어', 'code': 'my', 'country': null},
    {'name': '영어', 'code': 'en', 'country': null},
    {'name': '한국어', 'code': 'ko', 'country': 'KR'},
  ];

  @override
  void initState() {
    super.initState();
    // 현재 적용된 언어 가져오기 (없으면 기본값 한국어)
    _selectedLocale = appLocaleNotifier.value ?? const Locale('ko', 'KR');
  }

  void _applyLanguage() {
    // ✅ 전역 변수 업데이트 -> 앱 전체 언어 변경
    appLocaleNotifier.value = _selectedLocale;
    Navigator.pop(context); // 화면 닫기
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('언어 설정', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF2F2F7),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _applyLanguage,
            child: const Text(
              "적용",
              style: TextStyle(
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