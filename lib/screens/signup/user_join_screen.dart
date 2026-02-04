import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/data/korean_regions.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';

// Steps imports
import 'steps/step_email.dart';
import 'steps/step_password.dart';
import 'steps/step_region.dart';
import 'steps/step_nickname.dart';
import 'steps/step_terms.dart';
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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();

  // --- State Variables ---
  String? _selectedSido;
  String? _selectedSigungu;
  List<String> _sidoList = [];
  List<String> _sigunguList = [];

  // 약관 동의 상태 (DB 저장을 위해 변수로 관리)
  bool _marketingAgreed = false;
  bool _adAgreed = false;

  bool _isLoading = false;

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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

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
    final l10n = AppLocalizations.of(context)!;
    final val = _passwordController.text;
    final RegExp upperCase = RegExp(r'[A-Z]');
    final RegExp lowerCase = RegExp(r'[a-z]');
    final RegExp specialChar = RegExp(r'[!@#\\$%^\u0026*(),.?\":{}|\u003c\u003e]');
    String message = l10n.passwordRequirement;

    if (val.length >= 8 &&
        upperCase.hasMatch(val) &&
        lowerCase.hasMatch(val) &&
        specialChar.hasMatch(val)) {
      message = l10n.passwordValid;
    }
    setState(() => _passwordValidationMessage = message);
  }

  void _validateConfirmPassword() {
    final l10n = AppLocalizations.of(context)!;
    final val = _confirmPasswordController.text;
    setState(() {
      _confirmPasswordMessage = (_passwordController.text == val && val.isNotEmpty)
          ? l10n.passwordMatch
          : l10n.passwordMismatch;
    });
  }

  // ✅ [핵심 수정] 실제 가입 로직 복원 및 강화
  Future<void> _completeSignUp() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final nickname = _nicknameController.text.trim();

      // 1. Supabase Auth 회원가입 요청 (실제 DB에 유저 생성)
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
        // 필요 시 이메일 인증 리다이렉트 URL 설정
        // emailRedirectTo: 'io.supabase.flutter://login-callback',
      );

      // 가입 정보가 없으면 에러 처리
      if (res.user == null) {
        throw const AuthException('회원가입에 실패했습니다. (User is null)');
      }

      final userId = res.user!.id;

      // 2. Profiles 테이블에 정보 저장 (upsert 사용)
      // upsert: 없으면 insert, 있으면 update -> 가장 안전함
      await _supabase.from('profiles').upsert({
        'id': userId, // PK
        'nickname': nickname,
        'city': _selectedSido,
        'district': _selectedSigungu,
        'is_marketing_agreed': _marketingAgreed,
        'is_ad_agreed': _adAgreed,
        // 필요한 다른 필드들 초기화...
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 3. 성공 화면으로 이동
      _nextPage();

    } catch (e) {
      if (mounted) {
        // 에러 메시지 표시 (이미 존재하는 이메일 등)
        _showSnackBar('${l10n.signupFailed}: ${e.toString().replaceAll('AuthException:', '')}', isError: true);
      }
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
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.signup),
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
            // 1. 이메일
            StepEmail(
              emailController: _emailController,
              onNext: _nextPage,
            ),

            // 2. 비밀번호
            StepPassword(
              passwordController: _passwordController,
              confirmController: _confirmPasswordController,
              pwMessage: _passwordValidationMessage,
              confirmMessage: _confirmPasswordMessage,
              onNext: _nextPage,
            ),

            // 3. 지역 선택
            StepRegion(
              sidoList: _sidoList,
              sigunguList: _sigunguList,
              selectedSido: _selectedSido,
              selectedSigungu: _selectedSigungu,
              onSidoChanged: _onSidoChanged,
              onSigunguChanged: _onSigunguChanged,
              onNext: _nextPage,
            ),

            // 4. 닉네임
            StepNickname(
              nicknameController: _nicknameController,
              onNext: _nextPage,
              onChanged: (_) => setState(() {}),
            ),

            // 5. 약관 동의
            StepTerms(
              isLoading: _isLoading,
              onComplete: _completeSignUp, // 여기서 실제 가입 진행
              // 약관 동의 상태를 받아와서 변수에 저장
              onAgreedChanged: (agreement) {
                _marketingAgreed = agreement.marketing;
                _adAgreed = agreement.ad;
              },
            ),

            // 6. 가입 성공
            StepSuccess(
              onClose: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}