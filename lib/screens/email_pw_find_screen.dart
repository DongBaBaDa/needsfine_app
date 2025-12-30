import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailPWFindScreen extends StatefulWidget {
  const EmailPWFindScreen({super.key});

  @override
  State<EmailPWFindScreen> createState() => _EmailPWFindScreenState();
}

class _EmailPWFindScreenState extends State<EmailPWFindScreen> {
  final _supabase = Supabase.instance.client;
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  // 1. 이메일 찾기 로직 (전화번호 기준)
  Future<void> _findEmail() async {
    if (_phoneController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('profiles')
          .select('email')
          .eq('phone', _phoneController.text.trim())
          .maybeSingle();

      if (data != null && data['email'] != null) {
        _showResultDialog("가입된 이메일", "찾으시는 이메일은\n${data['email']} 입니다.");
      } else {
        _showResultDialog("결과 없음", "해당 번호로 가입된 정보가 없습니다.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("오류 발생: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. 비밀번호 찾기 로직 (이메일로 재설정 링크 발송)
  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.resetPasswordForEmail(_emailController.text.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("비밀번호 재설정 링크가 이메일로 발송되었습니다.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("발송 실패: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showResultDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("확인"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("이메일/비밀번호 찾기"),
          bottom: const TabBar(
            indicatorColor: Color(0xFF9C7CFF),
            labelColor: Color(0xFF9C7CFF),
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: "이메일 찾기"),
              Tab(text: "비밀번호 찾기"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 이메일 찾기
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("가입 시 등록한 전화번호를 입력해주세요."),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: "전화번호", hintText: "01012345678"),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _findEmail,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C7CFF), minimumSize: const Size(0, 52)),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("이메일 찾기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            // 비밀번호 찾기
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("비밀번호를 재설정할 이메일을 입력해주세요."),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "이메일 주소"),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C7CFF), minimumSize: const Size(0, 52)),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("재설정 링크 발송", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}