import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/data/korean_regions.dart';
import 'dart:math';

import 'package:needsfine_app/screens/main_shell.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';

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
  
  DateTime? _selectedDate;
  String? _selectedGender;
  List<String> _cities = [];
  List<String> _districts = [];
  List<String> _towns = [];
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedTown;

  bool _isLoading = false;
  bool _isAuthCodeSent = false;
  String _passwordValidationMessage = '';
  String _confirmPasswordMessage = '';

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => _validatePassword(_passwordController.text));
    _confirmPasswordController.addListener(() => _validateConfirmPassword(_confirmPasswordController.text));
    _cities = koreanRegions.keys.toList();
  }

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

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isAuthCodeSent) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('이메일 인증을 먼저 진행해주세요.'), backgroundColor: Colors.red,));
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
        await _supabase.from('profiles').update({
          'age': age,
          'gender': _selectedGender,
          'city': _selectedCity,
          'district': _selectedDistrict,
          'town': _selectedTown,
          'birth_date': _selectedDate?.toIso8601String(),
        }).eq('id', authResponse.user!.id);

        if(mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('회원가입이 완료되었습니다!')));
            Navigator.of(context).pop();
        }
      } else {
          throw '인증에 실패했습니다. 인증번호를 확인해주세요.';
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

  void _onCityChanged(String? city) {
    if (city == null) return;
    setState(() {
      _selectedCity = city;
      _districts = koreanRegions[city]?.keys.toList() ?? [];
      _selectedDistrict = null;
      _towns = [];
      _selectedTown = null;
    });
  }

  void _onDistrictChanged(String? district) {
    if (district == null) return;
    setState(() {
      _selectedDistrict = district;
      _towns = koreanRegions[_selectedCity]?[district] ?? [];
      _selectedTown = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입'), leading: BackButton(onPressed: () => Navigator.of(context).pop())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: '이메일'), keyboardType: TextInputType.emailAddress, validator: (v) => (v == null || !v.contains('@')) ? '올바른 이메일을 입력하세요' : null)),
                  const SizedBox(width: 8),
                  ElevatedButton(onPressed: _isLoading ? null : _sendAuthCode, child: const Text('인증번호 받기')),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _authCodeController, decoration: const InputDecoration(labelText: '인증번호'), keyboardType: TextInputType.number, validator: (v) => (v == null || v.isEmpty) ? '인증번호를 입력하세요' : null),
              const SizedBox(height: 24),
              TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: '비밀번호'), obscureText: true, validator: (v) => (v == null || v.length < 6) ? '6자리 이상 입력하세요' : null),
              Padding(padding: const EdgeInsets.only(top: 4, left: 12), child: Text(_passwordValidationMessage, style: TextStyle(color: _passwordValidationMessage == '사용 가능한 비밀번호입니다.' ? Colors.green : Colors.grey, fontSize: 12))),
              const SizedBox(height: 12),
              TextFormField(controller: _confirmPasswordController, decoration: const InputDecoration(labelText: '비밀번호 확인'), obscureText: true, validator: (v) => (v != _passwordController.text) ? '비밀번호가 일치하지 않습니다' : null),
              Padding(padding: const EdgeInsets.only(top: 4, left: 12), child: Text(_confirmPasswordMessage, style: TextStyle(color: _confirmPasswordMessage == '비밀번호가 일치합니다.' ? Colors.green : Colors.red, fontSize: 12))),
              const SizedBox(height: 24),
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: '생년월일',
                  hintText: _selectedDate == null ? '달력을 눌러 선택하세요' : '${_selectedDate!.year}년 ${_selectedDate!.month}월 ${_selectedDate!.day}일',
                  suffixIcon: IconButton(icon: const Icon(Icons.calendar_today), onPressed: () => _selectDate(context)),
                ),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 24),
              const Text('성별', style: TextStyle(fontSize: 16)),
              Row(
                children: [
                  Radio<String>(value: 'male', groupValue: _selectedGender, onChanged: (v) => setState(() => _selectedGender = v)),
                  const Text('남성'),
                  Radio<String>(value: 'female', groupValue: _selectedGender, onChanged: (v) => setState(() => _selectedGender = v)),
                  const Text('여성'),
                ],
              ),
              const SizedBox(height: 24),
              const Text('사는 지역', style: TextStyle(fontSize: 16)),
              DropdownButtonFormField<String>(hint: const Text('시/도'), value: _selectedCity, items: _cities.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: _onCityChanged),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(hint: const Text('시/군/구'), value: _selectedDistrict, items: _districts.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: _onDistrictChanged),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(hint: const Text('읍/면/동'), value: _selectedTown, items: _towns.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => _selectedTown = v)),
              const SizedBox(height: 40),
              ElevatedButton(onPressed: _isLoading ? null : _signUp, style: ElevatedButton.styleFrom(minimumSize: const Size(0, 52)), child: _isLoading ? const CircularProgressIndicator() : const Text('이메일로 회원가입')),
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('뒤로가기'))
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
