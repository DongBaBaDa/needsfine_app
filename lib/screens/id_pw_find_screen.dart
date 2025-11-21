import 'package:flutter/material.dart';

// --- [ ✅ ✅ 4-1-3. '아이디'/'비밀번호' '찾기' ] ---
class IDPWFindScreen extends StatelessWidget {
  const IDPWFindScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("아이디/비밀번호 찾기"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "아이디 찾기"),
              Tab(text: "비밀번호 찾기"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // '아이디' '찾기' '탭'
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text("이메일로 찾기"),
                  TextFormField(decoration: const InputDecoration(labelText: "이메일")),
                  TextFormField(decoration: const InputDecoration(labelText: "인증번호")),
                  ElevatedButton(onPressed: () {}, child: const Text("인증번호 받기")),
                  const SizedBox(height: 20),
                  const Text("전화번호로 찾기"),
                  TextFormField(decoration: const InputDecoration(labelText: "전화번호")),
                  TextFormField(decoration: const InputDecoration(labelText: "인증번호")),
                  ElevatedButton(onPressed: () {}, child: const Text("인증번호 받기")),
                ],
              ),
            ),
            // '비밀번호' '찾기' '탭'
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  TextFormField(decoration: const InputDecoration(labelText: "아이디")),
                  const Text("이메일 또는 전화번호 인증 선택... (더미 UI)"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}