import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/data/korean_regions.dart';

import 'steps/step_email.dart';
import 'steps/step_password.dart';
import 'steps/step_region.dart';
import 'steps/step_nickname.dart';
import 'steps/step_success.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';

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
  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;
  bool _isSignUpComplete = false;

  String _passwordValidationMessage = '';
  String _confirmPasswordMessage = '';

  @override
  void initState() {
    super.initState();
    // Note: We'll set the correct list in didChangeDependencies where context is available
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 언어가 한국어가 아니면 영문 로마자 표기 사용
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'ko') {
      _sidoList = koreanRegions.keys.toList();
    } else {
      _sidoList = koreanRegionsEnglish.keys.toList();
    }
    // Only rebuild if the list was empty (first time)
    if (_sigunguList.isEmpty && _selectedSido == null) {
      setState(() {});
    }
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
      _handleExit();
    }
  }

  Future<void> _handleExit() async {
    if (_isEmailVerified && !_isSignUpComplete) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("회원가입 취소"),
          content: const Text("지금 나가시면 가입이 취소되고 입력한 정보가 삭제됩니다. 정말 나가시겠습니까?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(AppLocalizations.of(context)!.confirm, style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (shouldExit == true) {
        await _cleanupIncompleteAccount();
        if (mounted) Navigator.of(context).pop();
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _cleanupIncompleteAccount() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint("Cleanup failed: $e");
    }
  }

  void _validatePassword() {
    final val = _passwordController.text;
    final RegExp upperCase = RegExp(r'[A-Z]');
    final RegExp lowerCase = RegExp(r'[a-z]');
    final RegExp specialChar = RegExp(r'[!@#\$%^&*(),.?":{}|<>]');
    String message = AppLocalizations.of(context)!.passwordRequirement;

    bool isValid = false;
    if (val.length >= 8 &&
        upperCase.hasMatch(val) &&
        lowerCase.hasMatch(val) &&
        specialChar.hasMatch(val)) {
      message = AppLocalizations.of(context)!.passwordValid;
      isValid = true;
    } else {
      message = AppLocalizations.of(context)!.passwordRequirement;
      isValid = false;
    }
    setState(() {
      _passwordValidationMessage = message;
      _isPasswordValid = isValid;
    });
    
    // 비밀번호 변경 시 확인 필드도 재검증 (버튼 즉시 활성화)
    if (_confirmPasswordController.text.isNotEmpty) {
      _validateConfirmPassword();
    }
  }

  void _validateConfirmPassword() {
    final val = _confirmPasswordController.text;
    final isMatch = (_passwordController.text == val && val.isNotEmpty);
    setState(() {
      _confirmPasswordMessage = isMatch
          ? AppLocalizations.of(context)!.passwordMatch
          : AppLocalizations.of(context)!.passwordMismatch;
      _isConfirmPasswordValid = isMatch;
    });
  }

  Future<void> _sendAuthCode() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showSnackBar(AppLocalizations.of(context)!.invalidEmail, isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final AuthResponse res = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: "NeedsFine_Temp_1234!",
      );

      if (mounted) {
        if (res.session != null) {
          setState(() => _isEmailVerified = true);
          _showSnackBar(AppLocalizations.of(context)!.emailAutoVerified);
        } else {
          _showSnackBar(AppLocalizations.of(context)!.authCodeSent);
          setState(() => _isAuthCodeSent = true);
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar(AppLocalizations.of(context)!.sendFailed(e.toString()), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyAuthCode() async {
    if (_authCodeController.text.length != 6) {
      _showSnackBar(AppLocalizations.of(context)!.invalidAuthCodeLength, isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.signup,
        token: _authCodeController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (response.session != null || response.user != null) {
        setState(() => _isEmailVerified = true);
        if (mounted) {
          _showSnackBar(AppLocalizations.of(context)!.emailVerified);
        }
      } else {
        throw Exception(AppLocalizations.of(context)!.verificationFailed);
      }
    } catch (e) {
      if (mounted) _showSnackBar(AppLocalizations.of(context)!.invalidAuthCode, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeSignUp() async {
    if (_nicknameController.text.isEmpty) {
      _showSnackBar(AppLocalizations.of(context)!.nicknameRequired, isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final currentUser = _supabase.auth.currentUser;

      if (currentUser != null) {
        await _supabase.auth.updateUser(
            UserAttributes(password: _passwordController.text.trim())
        );

        // 영문 선택 시 한글로 변환하여 DB 저장 (일관성 유지)
        final locale = Localizations.localeOf(context).languageCode;
        String? cityToSave = _selectedSido;
        String? districtToSave = _selectedSigungu;
        
        if (locale != 'ko' && _selectedSido != null) {
          // 영문 -> 한글 변환
          cityToSave = englishToKoreanSido[_selectedSido!] ?? _selectedSido;
          // 시/군/구는 같은 인덱스로 변환
          if (_selectedSigungu != null && _selectedSido != null) {
            final englishList = koreanRegionsEnglish[_selectedSido!] ?? [];
            final koreanKey = englishToKoreanSido[_selectedSido!];
            final koreanList = koreanKey != null ? (koreanRegions[koreanKey] ?? []) : [];
            final idx = englishList.indexOf(_selectedSigungu!);
            if (idx >= 0 && idx < koreanList.length) {
              districtToSave = koreanList[idx];
            }
          }
        }

        await _supabase.from('profiles').update({
          'nickname': _nicknameController.text.trim(),
          'city': cityToSave,
          'district': districtToSave,
        }).eq('id', currentUser.id);

        setState(() => _isSignUpComplete = true);
        _nextPage();
      } else {
        throw Exception(AppLocalizations.of(context)!.sessionExpired);
      }
    } catch (e) {
      if (mounted) _showSnackBar(AppLocalizations.of(context)!.signupError(e.toString()), isError: true);
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
    final locale = Localizations.localeOf(context).languageCode;
    setState(() {
      _selectedSido = value;
      _selectedSigungu = null;
      if (locale == 'ko') {
        _sigunguList = value != null ? (koreanRegions[value] ?? []) : [];
      } else {
        _sigunguList = value != null ? (koreanRegionsEnglish[value] ?? []) : [];
      }
    });
  }

  void _onSigunguChanged(String? value) {
    setState(() => _selectedSigungu = value);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _prevPage();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.signup),
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
                isPasswordValid: _isPasswordValid,
                isConfirmValid: _isConfirmPasswordValid,
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
      ),
    );
  }
}