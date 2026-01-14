import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/data/korean_regions.dart';

// 분리된 Step 위젯들을 import 합니다.
import './steps/step_email.dart';
import './steps/step_password.dart';
import './steps/step_birth.dart';
import './steps/step_gender.dart';
import './steps/step_region.dart';
import './steps/step_nickname.dart';
import './steps/step_terms.dart';
import './steps/step_success.dart';

class UserJoinScreen extends StatefulWidget {
  const UserJoinScreen({super.key});

  @override
  State<UserJoinScreen> createState() => _UserJoinScreenState();
}

class _UserJoinScreenState extends State<UserJoinScreen> {
  final _supabase = Supabase.instance.client;
  final _pageController = PageController();
  int _currentPage = 0;

  // --- Controllers & State Variables ---
  final _emailController = TextEditingController();
  final _authCodeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();

  String? _selectedSido;
  String? _selectedSigungu;
  List<String> _sidoList = [];
  List<String> _sigunguList = [];

  DateTime _selectedDate = DateTime(2000, 1, 1);
  String? _selectedGender;

  bool _isLoading = false;
  bool _isAuthCodeSent = false;
  bool _isEmailVerified = false;

  Timer? _timer;
  int _remainingTime = 0;

  bool _isRequiredTermsMet = false;
  bool _isMarketingAgreed = false;
  bool _isAdAgreed = false;

  String _passwordValidationMessage = '';
  String _confirmPasswordMessage = '';

  final List<Map<String, String>> _pageInfo = [
    {'title': '이메일을 입력해주세요', 'subtitle': '계정 찾기 및 중요 알림에 사용됩니다.'},
    {'title': '비밀번호를 설정해주세요', 'subtitle': '안전한 사용을 위해 특수문자를 포함해주세요.'},
    {'title': '생년월일을 선택해주세요', 'subtitle': '정확한 연령대 추천을 위해 필요해요.'},
    {'title': '성별을 알려주세요', 'subtitle': ''},
    {'title': '어디에 거주하시나요?', 'subtitle': '동네 맛집 추천을 위해 필요해요.'},
    {'title': 'NeedsFine에서 사용할\n닉네임을 정해주세요', 'subtitle': '나중에 언제든 변경할 수 있어요.'},
    {'title': '약관에 동의해주세요', 'subtitle': '원활한 서비스 이용을 위해 필요해요.'},
  ];

  @override
  void initState() {
    super.initState();
    _sidoList = koreanRegions.keys.toList();
    _passwordController.addListener(() => _validatePassword(_passwordController.text));
    _confirmPasswordController.addListener(() => _validateConfirmPassword(_confirmPasswordController.text));

    // 페이지 변경 시 상태 업데이트
    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentPage) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
    if (_currentPage < _pageInfo.length) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remainingTime = 180; // 3분
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  void _validatePassword(String password) {
    final RegExp upperCase = RegExp(r'[A-Z]');
    final RegExp lowerCase = RegExp(r'[a-z]');
    final RegExp specialChar = RegExp(r'[!@#\$%^&*(),.?":{}|<>]');
    String message = '8자 이상, 영문 대/소문자, 특수문자 포함';

    if (password.length >= 8 &&
        upperCase.hasMatch(password) &&
        lowerCase.hasMatch(password) &&
        specialChar.hasMatch(password)) {
      message = '사용 가능한 비밀번호입니다.';
    }
    setState(() => _passwordValidationMessage = message);
  }

  void _validateConfirmPassword(String confirmPassword) {
    setState(() {
      _confirmPasswordMessage = (_passwordController.text == confirmPassword && confirmPassword.isNotEmpty)
          ? '비밀번호가 일치합니다.'
          : '비밀번호가 일치하지 않습니다.';
    });
  }

  Future<void> _sendAuthCode() async {
    if (_emailController.text.isEmpty || !_emailController.text.contains('@')) {
      _showSnackBar('올바른 이메일을 입력해주세요.', isError: true);
      return;
    }

    if (_remainingTime > 0 && _isAuthCodeSent) {
      _showSnackBar('이미 인증번호가 발송되었습니다. 잠시 후 다시 시도해주세요.');
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
        _startTimer();
      }
    } catch (e) {
      if (mounted) _showSnackBar('발송 실패: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyAuthCode() async {
    if (_remainingTime == 0) {
      _showSnackBar('인증 시간이 만료되었습니다. 인증번호를 다시 받아주세요.', isError: true);
      return;
    }

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
      setState(() {
        _isEmailVerified = true;
      });
      _timer?.cancel();
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

  // [중요] 닉네임 중복 확인 로직
  Future<void> _checkNicknameAndNext() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('profiles')
          .select('id')
          .eq('nickname', nickname)
          .maybeSingle();

      if (data != null) {
        if (mounted) _showSnackBar('이미 사용 중인 닉네임입니다.', isError: true);
      } else {
        // 중복 없으면 다음 페이지로
        _nextPage();
      }
    } catch (e) {
      if (mounted) _showSnackBar('닉네임 확인 중 오류가 발생했습니다: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeSignUp() async {
    if (!_isRequiredTermsMet) {
      _showSnackBar('필수 약관에 모두 동의해주세요.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _supabase.auth.updateUser(
          UserAttributes(password: _passwordController.text.trim())
      );

      final age = DateTime.now().year - _selectedDate.year + 1;
      final userId = _supabase.auth.currentUser!.id;

      await _supabase.from('profiles').update({
        'nickname': _nicknameController.text.trim(),
        'age': age,
        'gender': _selectedGender,
        'city': _selectedSido,
        'district': _selectedSigungu,
        'birth_date': _selectedDate.toIso8601String(),
        'is_service_agreed': true,
        'is_privacy_agreed': true,
        'is_location_agreed': true,
        'is_marketing_agreed': _isMarketingAgreed,
        'is_ad_agreed': _isAdAgreed,
      }).eq('id', userId);

      _nextPage();
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

  bool _isNextButtonEnabled() {
    switch (_currentPage) {
      case 0: return _isEmailVerified;
      case 1: return _passwordValidationMessage.contains('가능') && _confirmPasswordMessage.contains('일치합니다');
      case 2: return true;
      case 3: return _selectedGender != null;
      case 4: return _selectedSido != null && _selectedSigungu != null;
      case 5: return _nicknameController.text.isNotEmpty; // 닉네임 입력 즉시 활성화됨
      case 6: return _isRequiredTermsMet;
      default: return false;
    }
  }

  void _onNextButtonPressed() {
    if (_isLoading) return;

    if (_currentPage == 5) {
      // 5페이지(닉네임)에서 다음 버튼 누르면 중복확인 실행
      _checkNicknameAndNext();
    } else if (_currentPage == 6) {
      _completeSignUp();
    } else {
      _nextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      StepEmail(
        emailController: _emailController,
        authCodeController: _authCodeController,
        isAuthCodeSent: _isAuthCodeSent,
        isEmailVerified: _isEmailVerified,
        isLoading: _isLoading,
        onSendAuthCode: _sendAuthCode,
        onVerifyAuthCode: _verifyAuthCode,
        remainingTime: _remainingTime,
      ),
      StepPassword(
        passwordController: _passwordController,
        confirmPasswordController: _confirmPasswordController,
        passwordValidationMessage: _passwordValidationMessage,
        confirmPasswordMessage: _confirmPasswordMessage,
      ),
      StepBirth(
        selectedDate: _selectedDate,
        onDateChanged: (newDate) => setState(() => _selectedDate = newDate),
      ),
      StepGender(
        selectedGender: _selectedGender,
        onGenderSelected: (gender) => setState(() => _selectedGender = gender),
      ),
      StepRegion(
        selectedSido: _selectedSido,
        selectedSigungu: _selectedSigungu,
        sidoList: _sidoList,
        sigunguList: _sigunguList,
        onSidoChanged: (value) {
          setState(() {
            _selectedSido = value;
            _selectedSigungu = null;
            _sigunguList = koreanRegions[value!] ?? [];
          });
        },
        onSigunguChanged: (value) => setState(() => _selectedSigungu = value),
      ),
      // [MODIFIED] 닉네임 입력 즉시 반영되도록 onChanged 연결
      StepNickname(
        nicknameController: _nicknameController,
        onChanged: (value) {
          // 입력할 때마다 화면을 갱신해서 버튼 활성화 상태 체크
          setState(() {});
        },
      ),
      StepTerms(
        isLoading: _isLoading,
        onAgreedChanged: (agreement) {
          setState(() {
            _isRequiredTermsMet = agreement.isRequiredMet;
            _isMarketingAgreed = agreement.marketing;
            _isAdAgreed = agreement.ad;
          });
        },
      ),
      const StepSuccess(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPage < _pageInfo.length ? '회원가입' : ''),
        leading: _currentPage < _pageInfo.length ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _prevPage,
        ) : null,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: pages.length,
          itemBuilder: (context, index) {
            if (index == pages.length - 1) {
              return pages[index];
            }
            return _buildPageLayout(
              title: _pageInfo[index]['title']!,
              subtitle: _pageInfo[index]['subtitle']!,
              content: pages[index],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPageLayout({required String title, required String subtitle, required Widget content}) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 40),
          Expanded(child: SingleChildScrollView(child: content)),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_isNextButtonEnabled() && !_isLoading)
                  ? _onNextButtonPressed
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C7CFF),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: _isLoading && (_currentPage == 0 || _currentPage == 5 || _currentPage == 6)
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_currentPage == 6 ? '회원가입 완료' : '다음', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}