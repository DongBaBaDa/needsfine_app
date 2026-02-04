import 'package:flutter/material.dart';
// 🔴 [필수] HomeScreen 파일 경로에 맞춰 주석 해제하세요.
// import 'package:needsfine_app/screens/home_screen.dart';

import 'package:needsfine_app/l10n/app_localizations.dart';

class StepSuccess extends StatelessWidget {
  final VoidCallback? onClose;

  const StepSuccess({
    super.key,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/icon.png',
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)!.welcome, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(AppLocalizations.of(context)!.signupCompleteMessage, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  // ✅ [수정] HomeScreen으로 이동하며 이전 스택 모두 제거
                  // 만약 HomeScreen 클래스 이름이 다르다면 수정해주세요.
                  // Navigator.of(context).pushAndRemoveUntil(
                  //   MaterialPageRoute(builder: (_) => const HomeScreen()),
                  //   (route) => false,
                  // );

                  // ⚠️ HomeScreen import가 안 되어 있어 에러가 날 수 있으니
                  // 임시로 '/home' 라우트로 이동하는 코드로 두겠습니다.
                  // main.dart에 '/home' 라우트가 등록되어 있다면 이대로 작동합니다.
                  Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A2BE2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(AppLocalizations.of(context)!.getStarted, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }
}