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

  // ✅ [수정] 인증번호 발송 로직 -> 테스트용으로 바로 다음 페이지 이동으로 변경
  Future<void> _sendAuthCode() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showSnackBar('올바른 이메일을 입력해주세요.', isError: true);
      return;
    }

    // --- ⬇️ 테스트를 위해 주석 처리 시작 ⬇️ ---
    /*
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
    */
    // --- ⬆️ 테스트를 위해 주석 처리 끝 ⬆️ ---

    // ✅ [테스트용] 인증 과정 생략하고 바로 다음 페이지(비밀번호 입력)로 이동
    _nextPage();
  }

  // ✅ [수정] 인증번호 확인 로직 -> 테스트용이라 사용 안 함 (주석 처리)
  Future<void> _verifyAuthCode() async {
    // --- ⬇️ 테스트를 위해 주석 처리 시작 ⬇️ ---
    /*
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
    */
    // --- ⬆️ 테스트를 위해 주석 처리 끝 ⬆️ ---

    // 혹시라도 호출되면 바로 다음으로 넘기기
    _nextPage();
  }

  // 회원가입 완료
  Future<void> _completeSignUp() async {
    if (_nicknameController.text.isEmpty) {
      _showSnackBar('닉네임을 입력해주세요.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // ✅ [테스트용 수정] 실제 인증을 안 했으므로 currentUser가 없을 수 있음.
      // 로그인된 유저가 있으면 업데이트, 없으면 테스트 로그만 남기고 성공 처리.

      final currentUser = _supabase.auth.currentUser;

      if (currentUser != null) {
        // 1. 실제 가입 프로세스 (인증을 건너뛰면 이 부분 에러 날 수 있음)
        await _supabase.auth.updateUser(
            UserAttributes(password: _passwordController.text.trim())
        );

        await _supabase.from('profiles').update({
          'nickname': _nicknameController.text.trim(),
          'city': _selectedSido,
          'district': _selectedSigungu,
        }).eq('id', currentUser.id);
      } else {
        // 2. 테스트 모드 (로그인 정보 없음)
        debugPrint('⚠️ [TEST MODE] 인증 없이 진행되어 DB 저장을 건너뜁니다.');
        debugPrint('입력된 정보 - 이메일: ${_emailController.text}, 비번: ${_passwordController.text}, 닉네임: ${_nicknameController.text}');

        // 가짜 딜레이
        await Future.delayed(const Duration(seconds: 1));
      }

      _nextPage(); // 성공 화면으로 이동
    } catch (e) {
      if (mounted) _showSnackBar('가입 처리 실패(테스트 중 무시 가능): $e', isError: true);
      // 에러가 나도 테스트 중이면 성공 화면으로 일단 보낼 수도 있음
      // _nextPage();
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
              // ✅ [수정] "인증번호 전송" 버튼을 누르면 -> 바로 다음 페이지(_sendAuthCode 내부에서 처리)
              onSendTap: _sendAuthCode,
              // ✅ [수정] "인증확인" 버튼은 사실상 안 쓰이거나 숨겨야 함
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