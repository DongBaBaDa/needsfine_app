import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/data/korean_regions.dart';

// 폴더 구조가 맞다면 에러가 사라집니다.
import 'steps/step_email.dart';
import 'steps/step_password.dart';
// import 'steps/step_birth.dart'; // ❌ 삭제됨
// import 'steps/step_gender.dart'; // ❌ 삭제됨
import 'steps/step_region.dart';
import 'steps/step_nickname.dart';
import 'steps/step_success.dart';

class UserJoinScreen extends StatefulWidget {
  const UserJoinScreen({super.key});

  @override
  State<UserJoinScreen> createState() => _UserJoinScreenState();
}

class _UserJoinScreenState extends State<UserJoinScreen> {
  final _supabase = Supabase.instance.client;
  final _pageController = PageController();

  // --- Controllers ---
  final _emailController = TextEditingController();
  final _authCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();

  // --- State Variables ---
  String? _selectedSido;
  String? _selectedSigungu;
  List<String> _sidoList = [];
  List<String> _sigunguList = [];

  // ❌ [삭제] 성별/생년월일 변수 제거됨
  // DateTime? _selectedDate;
  // String? _selectedGender;

  bool _isLoading = false;
  bool _isAuthCodeSent = false;
  bool _isEmailVerified = false;

  String _passwordValidationMessage = '';
  String _confirmPasswordMessage = '';

  @override
  void initState() {
    super.initState();
    _sidoList = koreanRegions.keys.toList();
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _authCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  // --- Logic Methods ---

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _prevPage() {
    if (_pageController.hasClients && _pageController.page! > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _validatePassword() {
    final val = _passwordController.text;
    final RegExp upperCase = RegExp(r'[A-Z]');
    final RegExp lowerCase = RegExp(r'[a-z]');
    final RegExp specialChar = RegExp(r'[!@#\$%^&*(),.?":{}|<>]');
    String message = '8자 이상, 영문 대/소문자, 특수문자 포함';

    if (val.length >= 8 &&
        upperCase.hasMatch(val) &&
        lowerCase.hasMatch(val) &&
        specialChar.hasMatch(val)) {
      message = '사용 가능한 비밀번호입니다.';
    }
    setState(() => _passwordValidationMessage = message);
  }

  void _validateConfirmPassword() {
    final val = _confirmPasswordController.text;
    setState(() {
      _confirmPasswordMessage = (_passwordController.text == val && val.isNotEmpty)
          ? '비밀번호가 일치합니다.'
          : '비밀번호가 일치하지 않습니다.';
    });
  }

  // 인증번호 발송
  Future<void> _sendAuthCode() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showSnackBar('올바른 이메일을 입력해주세요.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: "NeedsFine_Temp_1234!",
      );
      if (mounted) {
        _showSnackBar('인증번호가 발송되었습니다.');
        setState(() => _isAuthCodeSent = true);
      }
    } catch (e) {
      if (mounted) _showSnackBar('발송 실패: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 인증번호 확인
  Future<void> _verifyAuthCode() async {
    if (_authCodeController.text.length != 6) {
      _showSnackBar('인증번호 6자리를 입력해주세요.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _supabase.auth.verifyOTP(
        type: OtpType.signup,
        token: _authCodeController.text.trim(),
        email: _emailController.text.trim(),
      );
      setState(() => _isEmailVerified = true);
      if (mounted) {
        _showSnackBar('이메일 인증 완료!');
        _nextPage();
      }
    } catch (e) {
      if (mounted) _showSnackBar('인증 실패: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 회원가입 완료
  Future<void> _completeSignUp() async {
    if (_nicknameController.text.isEmpty) {
      _showSnackBar('닉네임을 입력해주세요.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 비밀번호 업데이트 (임시 비번 -> 실제 비번)
      await _supabase.auth.updateUser(
          UserAttributes(password: _passwordController.text.trim())
      );

      final userId = _supabase.auth.currentUser!.id;

      // ✅ [수정] 성별, 생년월일, 나이 업데이트 로직 제거 (InfoEditScreen에서 수행)
      await _supabase.from('profiles').update({
        'nickname': _nicknameController.text.trim(),
        'city': _selectedSido,
        'district': _selectedSigungu,
        // gender, birth_date, age는 null 상태로 유지됨
      }).eq('id', userId);

      _nextPage(); // 성공 화면으로
    } catch (e) {
      if (mounted) _showSnackBar('가입 처리 실패: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.blueAccent,
      ),
    );
  }

  // 지역 선택 변경 핸들러
  void _onSidoChanged(String? value) {
    setState(() {
      _selectedSido = value;
      _selectedSigungu = null;
      _sigunguList = value != null ? (koreanRegions[value] ?? []) : [];
    });
  }

  void _onSigunguChanged(String? value) {
    setState(() => _selectedSigungu = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원가입'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _prevPage,
        ),
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            StepEmail(
              emailController: _emailController,
              authCodeController: _authCodeController,
              isAuthCodeSent: _isAuthCodeSent,
              isEmailVerified: _isEmailVerified,
              isLoading: _isLoading,
              onSendTap: _sendAuthCode,
              onVerifyTap: _verifyAuthCode,
              onNext: _nextPage,
            ),
            StepPassword(
              passwordController: _passwordController,
              confirmController: _confirmPasswordController,
              pwMessage: _passwordValidationMessage,
              confirmMessage: _confirmPasswordMessage,
              onNext: _nextPage,
            ),
            // ❌ [삭제] StepBirth, StepGender 제거됨
            StepRegion(
              sidoList: _sidoList,
              sigunguList: _sigunguList,
              selectedSido: _selectedSido,
              selectedSigungu: _selectedSigungu,
              onSidoChanged: _onSidoChanged,
              onSigunguChanged: _onSigunguChanged,
              onNext: _nextPage,
            ),
            StepNickname(
              nicknameController: _nicknameController,
              isLoading: _isLoading,
              onComplete: _completeSignUp,
            ),
            StepSuccess(
              onClose: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}