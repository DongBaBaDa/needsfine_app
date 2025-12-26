import 'package:flutter/material.dart';
import 'package:needsfine_app/core/needsfine_theme.dart'; // 테마 import
import 'package:needsfine_app/models/app_data.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isLoggedIn = false;
  final TextEditingController _passwordController = TextEditingController();

  void _login() {
    if (_passwordController.text == 'needsfine2953') {
      setState(() {
        _isLoggedIn = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
    }
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('관리자 페이지')),
      body: _isLoggedIn ? _buildAdminDashboard() : _buildLoginScreen(),
    );
  }

  Widget _buildLoginScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '비밀번호',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _login(),
          ),
          const SizedBox(height: 16),
          // [수정] Primary Button 스타일 적용
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: kNeedsFinePurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('로그인'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminDashboard() {
    final reviews = List.generate(5, (i) => Review(userName: 'User $i', content: '관리자 테스트 리뷰 $i', rating: 4.0, date: '2024-05-2$i'));

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("리뷰 관리", style: Theme.of(context).textTheme.titleLarge),
        ),
        ...reviews.map((review) => ListTile(
              title: Text(review.content),
              subtitle: Text('by ${review.userName} | 신뢰도: ${review.trustLevel}%'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"${review.content}" 리뷰가 삭제되었습니다.')),
                  );
                },
              ),
            )),
      ],
    );
  }
}
