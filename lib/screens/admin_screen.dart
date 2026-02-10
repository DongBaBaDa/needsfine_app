import 'package:flutter/material.dart';
import 'package:needsfine_app/core/needsfine_theme.dart'; // 테마 import
import 'package:needsfine_app/models/app_data.dart';
import 'package:needsfine_app/screens/admin_stats_screen.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isLoggedIn = false;
  final TextEditingController _passwordController = TextEditingController();

  void _login() {
    final l10n = AppLocalizations.of(context)!;
    if (_passwordController.text == 'needsfine2953') {
      setState(() {
        _isLoggedIn = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordMismatch)),
      );
    }
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminPage)),
      body: _isLoggedIn ? _buildAdminDashboard() : _buildLoginScreen(),
    );
  }

  Widget _buildLoginScreen() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: l10n.password,
              border: const OutlineInputBorder(),
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
              child: Text(l10n.loginButton),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminDashboard() {
    final l10n = AppLocalizations.of(context)!;
    final reviews = List.generate(5, (i) => Review(userName: 'User $i', content: '관리자 테스트 리뷰 $i', rating: 4.0, date: '2024-05-2$i'));

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.analytics_outlined),
                label: Text(l10n.viewAdminStats),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminStatsScreen()));
                },
              ),
              const SizedBox(height: 24),
              Text(l10n.reviewManagement, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        ...reviews.map((review) => ListTile(
              title: Text(review.content),
              subtitle: Text('by ${review.userName} | 신뢰도: ${review.trustLevel}%'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.deleteReviewConfirm(review.content))),
                  );
                },
              ),
            )),
      ],
    );
  }
}
