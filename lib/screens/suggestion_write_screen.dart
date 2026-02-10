import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';

class SuggestionWriteScreen extends StatefulWidget {
  const SuggestionWriteScreen({super.key});

  @override
  State<SuggestionWriteScreen> createState() => _SuggestionWriteScreenState();
}

class _SuggestionWriteScreenState extends State<SuggestionWriteScreen> {
  final _controller = TextEditingController();
  final _supabase = Supabase.instance.client;
  bool _isSending = false;

  Future<void> _submitSuggestion() async {
    if (_controller.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("로그인이 필요합니다.");

      // DB에 건의사항 저장
      await _supabase.from('suggestions').insert({
        'user_id': userId,
        'content': _controller.text,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.saved)));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("전송 실패: $e")));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.sendSuggestionTitle)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                AppLocalizations.of(context)!.suggestionGuide,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _controller,
                maxLines: 12, // 높이 소폭 조정
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.suggestionHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSending ? null : _submitSuggestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kNeedsFinePurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSending
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(AppLocalizations.of(context)!.sendAction, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}