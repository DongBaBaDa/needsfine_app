import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
  final _addressController = TextEditingController();

  // TODO: 발급받은 실제 키값을 입력하세요.
  final String _naverClientId = "YOUR_CLIENT_ID";
  final String _naverClientSecret = "YOUR_CLIENT_SECRET";

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
    _passwordController.addListener(() => _validatePassword(_passwordController.text));
    _confirmPasswordController.addListener(() => _validateConfirmPassword(_confirmPasswordController.text));
  }

  // --- 기존 로직 (비밀번호 및 이메일 인증) ---
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

  // --- 주소 검색 로직 (인코딩 및 검색성 개선) ---
  Future<void> _searchAddress() async {
    final searchController = TextEditingController();
    List<dynamic> results = [];
    bool isSearching = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('주소 검색', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: '도로명이나 지번을 입력하세요',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () async {
                            setDialogState(() => isSearching = true);
                            final fetched = await _fetchNaverAddress(searchController.text);
                            setDialogState(() {
                              results = fetched;
                              isSearching = false;
                            });
                          },
                        ),
                      ),
                      onSubmitted: (value) async {
                        setDialogState(() => isSearching = true);
                        final fetched = await _fetchNaverAddress(value);
                        setDialogState(() {
                          results = fetched;
                          isSearching = false;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (isSearching)
                      const CircularProgressIndicator()
                    else if (results.isEmpty && searchController.text.isNotEmpty)
                      const Text('검색 결과가 없습니다.')
                    else
                      Expanded(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: results.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final item = results[index];
                            return ListTile(
                              title: Text(item['roadAddress'] ?? '도로명 주소 없음'),
                              subtitle: Text(item['jibunAddress'] ?? ''),
                              onTap: () {
                                _addressController.text = item['roadAddress'];
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
              ],
            );
          }
      ),
    );
  }

  Future<List<dynamic>> _fetchNaverAddress(String query) async {
    if (query.isEmpty) return [];

    // 중요: Uri.https를 사용해야 한글 쿼리가 자동으로 퍼센트 인코딩됩니다.
    final url = Uri.https("naveropenapi.apigw.ntruss.com", "/map-geocode/v2/geocode", {
      "query": query,
    });

    try {
      final response = await http.get(url, headers: {
        "X-NCP-APIGW-API-KEY-ID": _naverClientId,
        "X-NCP-APIGW-API-KEY": _naverClientSecret,
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['addresses'] ?? [];
      } else {
        debugPrint("Naver API Error: ${response.statusCode} ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
      return [];
    }
  }

  // --- 회원가입 제출 로직 ---
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('주소를 검색해 주세요.')));
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
          'address': _addressController.text, // DB 컬럼명 확인 필요
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
              const Text('사는 지역', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _addressController,
                      readOnly: true,
                      decoration: const InputDecoration(hintText: '주소를 검색해 주세요'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _searchAddress,
                    child: const Text('주소 찾기'),
                  ),
                ],
              ),
              const SizedBox(height: 40),
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
    _addressController.dispose();
    super.dispose();
  }
}