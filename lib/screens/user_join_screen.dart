import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/data/korean_regions.dart'; // 방금 만든 데이터 임포트

class UserJoinScreen extends StatefulWidget {
  const UserJoinScreen({super.key});

  @override
  State<UserJoinScreen> createState() => _UserJoinScreenState();
}

class _UserJoinScreenState extends State<UserJoinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // 지역 선택을 위한 변수들
  String? _selectedSido;
  String? _selectedSigungu;
  List<String> _sidoList = [];
  List<String> _sigunguList = [];

  DateTime? _selectedDate;
  String? _selectedGender;
  bool _isLoading = false;
  bool _isAuthCodeSent = false;
  String _passwordValidationMessage = '';
  String _confirmPasswordMessage = '';

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // 초기 시/도 목록 로드
    _sidoList = koreanRegions.keys.toList();
    _passwordController.addListener(() => _validatePassword(_passwordController.text));
    _confirmPasswordController.addListener(() => _validateConfirmPassword(_confirmPasswordController.text));
  }

  // --- 비밀번호 유효성 검사 로직 (기존 유지) ---
  void _validatePassword(String password) {
    final RegExp upperCase = RegExp(r'[A-Z]');
    final RegExp lowerCase = RegExp(r'[a-z]');
    final RegExp specialChar = RegExp(r'[!@#\$%^&*(),.?":{}|<>]');
    String message = '8자 이상, 영문 대/소문자, 특수문자를 포함해야 합니다.';

    if (password.length >= 8 && upperCase.hasMatch(password) && lowerCase.hasMatch(password) && specialChar.hasMatch(password)) {
      message = '사용 가능한 비밀번호입니다.';
    }
    setState(() => _passwordValidationMessage = message);
    _validateConfirmPassword(_confirmPasswordController.text);
  }

  void _validateConfirmPassword(String confirmPassword) {
    String message = '';
    if (confirmPassword.isNotEmpty) {
      if (_passwordController.text == confirmPassword) {
        message = '비밀번호가 일치합니다.';
      } else {
        message = '비밀번호가 일치하지 않습니다.';
      }
    }
    setState(() => _confirmPasswordMessage = message);
  }

  // --- 이메일 인증번호 발송 (기존 유지) ---
  Future<void> _sendAuthCode() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('올바른 이메일을 먼저 입력해주세요.'), backgroundColor: Colors.red,));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.signInWithOtp(email: _emailController.text.trim(), shouldCreateUser: true);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('인증번호가 발송되었습니다.')));
        setState(() => _isAuthCodeSent = true);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('인증번호 발송 실패: $e'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  // --- 회원가입 제출 로직 (수정: 드롭다운 데이터 반영) ---
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSido == null || _selectedSigungu == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('사는 지역을 선택해 주세요.')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authResponse = await _supabase.auth.verifyOTP(
        type: OtpType.signup,
        token: _authCodeController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (authResponse.user != null) {
        final age = _selectedDate != null ? DateTime.now().year - _selectedDate!.year + 1 : null;

        // Supabase profiles 테이블 업데이트
        await _supabase.from('profiles').update({
          'age': age,
          'gender': _selectedGender,
          'city': _selectedSido,      // 시/도 저장
          'district': _selectedSigungu, // 시/군/구 저장
          'birth_date': _selectedDate?.toIso8601String(),
        }).eq('id', authResponse.user!.id);

        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('회원가입이 완료되었습니다!')));
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('회원가입 실패: $e'), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입'), leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 이메일 및 인증 섹션
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: '이메일'), keyboardType: TextInputType.emailAddress)),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _isLoading ? null : _sendAuthCode, child: const Text('인증번호 받기')),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _authCodeController, decoration: const InputDecoration(labelText: '인증번호'), keyboardType: TextInputType.number),

              const SizedBox(height: 24),
              // 2. 비밀번호 섹션
              TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: '비밀번호'), obscureText: true),
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(_passwordValidationMessage, style: TextStyle(color: _passwordValidationMessage.contains('가능') ? Colors.green : Colors.grey, fontSize: 12)),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _confirmPasswordController, decoration: const InputDecoration(labelText: '비밀번호 확인'), obscureText: true),
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(_confirmPasswordMessage, style: TextStyle(color: _confirmPasswordMessage.contains('일치합') ? Colors.green : Colors.red, fontSize: 12)),
              ),

              const SizedBox(height: 24),
              // 3. 생년월일 및 성별 섹션
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: '생년월일',
                  hintText: _selectedDate == null ? '선택하세요' : '${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}',
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 12),
              const Text('성별', style: TextStyle(fontSize: 14, color: Colors.grey)),
              Row(
                children: [
                  Radio<String>(value: 'male', groupValue: _selectedGender, onChanged: (v) => setState(() => _selectedGender = v)),
                  const Text('남성'),
                  const SizedBox(width: 20),
                  Radio<String>(value: 'female', groupValue: _selectedGender, onChanged: (v) => setState(() => _selectedGender = v)),
                  const Text('여성'),
                ],
              ),

              const SizedBox(height: 24),
              // 4. 사는 지역 섹션 (2단계 드롭다운으로 변경됨)
              const Text('사는 지역 선택', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              // 시/도 드롭다운
              DropdownButtonFormField<String>(
                value: _selectedSido,
                hint: const Text('시/도 선택'),
                items: _sidoList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSido = value;
                    _selectedSigungu = null; // 시/도 변경 시 하위 목록 초기화
                    _sigunguList = koreanRegions[value!] ?? [];
                  });
                },
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
              ),
              const SizedBox(height: 12),

              // 시/군/구 드롭다운
              DropdownButtonFormField<String>(
                value: _selectedSigungu,
                hint: const Text('시/군/구 선택'),
                items: _sigunguList.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: _selectedSido == null ? null : (value) {
                  setState(() => _selectedSigungu = value);
                },
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
              ),

              const SizedBox(height: 40),
              // 5. 완료 버튼
              ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(minimumSize: const Size(0, 52)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('회원가입 완료'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _authCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}