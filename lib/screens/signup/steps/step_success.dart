import 'package:flutter/material.dart';

class StepSuccess extends StatelessWidget {
  // 부모에서 완료 처리 등을 위해 콜백이 필요하다면 받을 수 있지만,
  // 현재 코드에서는 내부에서 popUntil을 쓰므로 파라미터가 없어도 됩니다.
  final VoidCallback? onClose;

  const StepSuccess({super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // [MODIFIED] 아이콘 대신 로고 이미지 사용
          Image.asset(
            'assets/icon.png',
            width: 100, // 크기는 적절히 조절하세요
            height: 100,
          ),
          const SizedBox(height: 24),
          const Text('환영합니다!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('NeedsFine 회원가입이 완료되었습니다.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  // 앱의 첫 화면(initial_screen)까지 돌아갑니다.
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9C7CFF)),
                child: const Text('시작하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }
}