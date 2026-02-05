import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';

class StepNickname extends StatefulWidget {
  final TextEditingController nicknameController;
  final VoidCallback onComplete; // 가입 완료 액션
  final bool isLoading;
  final ValueChanged<String>? onChanged;

  const StepNickname({
    super.key,
    required this.nicknameController,
    required this.onComplete,
    this.isLoading = false,
    this.onChanged,
  });

  @override
  State<StepNickname> createState() => _StepNicknameState();
}

class _StepNicknameState extends State<StepNickname> {
  final _supabase = Supabase.instance.client;
  bool _isNextEnabled = false;
  bool _isChecking = false;
  bool _isNicknameAvailable = false;
  String? _nicknameMessage;

  @override
  void initState() {
    super.initState();
    widget.nicknameController.addListener(_onNicknameChanged);
  }

  @override
  void dispose() {
    widget.nicknameController.removeListener(_onNicknameChanged);
    super.dispose();
  }

  void _onNicknameChanged() {
    // 닉네임이 변경되면 중복확인 상태 초기화
    setState(() {
      _isNicknameAvailable = false;
      _nicknameMessage = null;
      _isNextEnabled = false;
    });
  }

  Future<void> _checkNicknameDuplicate() async {
    final nickname = widget.nicknameController.text.trim();
    
    if (nickname.isEmpty) {
      setState(() {
        _nicknameMessage = AppLocalizations.of(context)!.nicknameEmpty;
        _isNicknameAvailable = false;
        _isNextEnabled = false;
      });
      return;
    }

    if (nickname.length < 2) {
      setState(() {
        _nicknameMessage = AppLocalizations.of(context)!.nicknameTooShort;
        _isNicknameAvailable = false;
        _isNextEnabled = false;
      });
      return;
    }

    setState(() => _isChecking = true);

    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      
      // 닉네임 중복 체크 (자신 제외)
      var query = _supabase
          .from('profiles')
          .select('id')
          .eq('nickname', nickname);
      
      if (currentUserId != null) {
        query = query.neq('id', currentUserId);
      }
      
      final result = await query.maybeSingle();

      if (result != null) {
        // 중복됨
        setState(() {
          _nicknameMessage = AppLocalizations.of(context)!.nicknameDuplicate;
          _isNicknameAvailable = false;
          _isNextEnabled = false;
        });
      } else {
        // 사용 가능
        setState(() {
          _nicknameMessage = AppLocalizations.of(context)!.nicknameAvailable;
          _isNicknameAvailable = true;
          _isNextEnabled = true;
        });
      }
    } catch (e) {
      setState(() {
        _nicknameMessage = "확인 중 오류: $e";
        _isNicknameAvailable = false;
        _isNextEnabled = false;
      });
    } finally {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.setNickname, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.nicknameInfo, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 40),

          // 닉네임 입력 + 중복확인 버튼
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.nicknameController,
                  onChanged: widget.onChanged,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.nickname,
                    hintText: AppLocalizations.of(context)!.nicknameHint,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                    // 중복확인 결과 메시지
                    helperText: _nicknameMessage,
                    helperStyle: TextStyle(
                      color: _isNicknameAvailable ? Colors.green : Colors.red,
                    ),
                    errorText: (_nicknameMessage != null && !_isNicknameAvailable) 
                        ? null  // helperText로 표시
                        : null,
                  ),
                  maxLength: 10,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isChecking ? null : _checkNicknameDuplicate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isChecking
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(AppLocalizations.of(context)!.checkDuplicate),
                ),
              ),
            ],
          ),

          const Spacer(),

          // 가입 완료 버튼
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_isNextEnabled && _isNicknameAvailable && !widget.isLoading) ? widget.onComplete : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8A2BE2),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: widget.isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(AppLocalizations.of(context)!.completeSignup, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}