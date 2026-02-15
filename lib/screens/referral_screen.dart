import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _codeController = TextEditingController();
  
  bool _isLoading = true;
  String? _myCode;
  int _referralCount = 0;
  double _myContributionScore = 0.0; // ✅ 기여도 추가
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchMyReferralInfo();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _fetchMyReferralInfo() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      Map<String, dynamic>? profileData;
      
      // 1. 시도: 기여도 포함 조회 (마이그레이션 완료된 경우)
      try {
        profileData = await _supabase.from('profiles')
            .select('my_referral_code, referral_count, contribution_score')
            .eq('id', user.id)
            .maybeSingle();
      } catch (e) {
        // 2. 실패 시: 기여도 제외 조회 (마이그레이션 안 된 경우 대비)
        debugPrint('Contribution score column missing? Retrying without it.');
        profileData = await _supabase.from('profiles')
            .select('my_referral_code, referral_count')
            .eq('id', user.id)
            .maybeSingle();
      }

      if (profileData != null) {
        setState(() {
          _myCode = profileData!['my_referral_code'];
          _referralCount = (profileData['referral_count'] as num?)?.toInt() ?? 0;
          _myContributionScore = (profileData['contribution_score'] as num?)?.toDouble() ?? 0.0;
        });

        // 코드가 없으면 생성 요청 (Edge Function)
        if (_myCode == null) {
           final response = await _supabase.functions.invoke(
            'make-server-26899706/get-my-referral-code',
            body: {'user_id': user.id},
          );
          
          if (response.status == 200 && response.data != null) {
             final data = response.data;
             setState(() {
               _myCode = data['code'];
               // Edge Function에서 기여도도 리턴해주면 업데이트
               if (data['contribution_score'] != null) {
                 _myContributionScore = (data['contribution_score'] as num).toDouble();
               }
             });
          }
        }
      }
    } catch (e) {
      debugPrint('Referral info fetch error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('정보를 불러오는데 실패했습니다.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReferralCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    
    if (code.toUpperCase() == _myCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('본인의 코드는 입력할 수 없습니다.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase.functions.invoke(
        'make-server-26899706/apply-referral-code',
        body: {
          'user_id': user.id,
          'referral_code': code,
        },
      );
      
      final data = response.data;
      if (response.status == 200 && data['success'] == true) {
        if (!mounted) return;
        
        // 성공 모달
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('🎉 축하합니다!'),
            content: Text(data['message'] ?? '기여도가 지급되었습니다.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                }, 
                child: const Text('확인')
              ),
            ],
          ),
        );
        // 데이터 갱신
        _fetchMyReferralInfo();
        
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? '오류가 발생했습니다.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('처리 중 오류 발생: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _shareReferralCode() {
    if (_myCode == null) return;
    
    String downloadLink;
    if (Platform.isAndroid) {
      downloadLink = "https://play.google.com/store/apps/details?id=com.needsfine.needsfine_app&pcampaignid=web_share";
    } else if (Platform.isIOS) {
       downloadLink = "https://apps.apple.com/app/id6758127044"; 
    } else {
       downloadLink = "https://needsfine.com/app";
    }

    final String message = 
        "[NeedsFine] 친구가 초대했어요! 🍽️\n"
        "추천 코드: $_myCode\n"
        "앱 설치하고 가입 시 위 코드를 입력하면 기여도 보상을 받을 수 있습니다!\n"
        "$downloadLink";
    
    Share.share(message, subject: "NeedsFine 친구 초대");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text("친구 초대", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // 1. Reward Card (Banner) with Contribution
                   Container(
                     padding: const EdgeInsets.all(24),
                     decoration: BoxDecoration(
                       gradient: const LinearGradient(
                         colors: [Color(0xFF8A2BE2), Color(0xFF9C7CFF)],
                         begin: Alignment.topLeft,
                         end: Alignment.bottomRight,
                       ),
                       borderRadius: BorderRadius.circular(20),
                       boxShadow: [
                         BoxShadow(
                           color: const Color(0xFF8A2BE2).withOpacity(0.3),
                           blurRadius: 12,
                           offset: const Offset(0, 6),
                         ),
                       ],
                     ),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         const Text("친구 초대하고\n기여도 함께 올려요! 🚀", 
                           style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, height: 1.3)
                         ),
                         const SizedBox(height: 16),
                         Container(
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                           decoration: BoxDecoration(
                             color: Colors.white.withOpacity(0.2),
                             borderRadius: BorderRadius.circular(10),
                           ),
                           child: Text("💎 현재 내 기여도: ${_myContributionScore.toStringAsFixed(1)}", 
                             style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)
                           ),
                         ),
                         const SizedBox(height: 12),
                         const Text("+10 기여도 즉시 지급", style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.bold)),
                         const SizedBox(height: 4),
                         const Text("5명 초대 시 특별 배지 검토 중!", style: TextStyle(fontSize: 12, color: Colors.white60)),
                       ],
                     ),
                   ),
                   const SizedBox(height: 32),

                   // 2. My Code Section
                   const Text("나의 초대 코드", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                   const SizedBox(height: 12),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(16),
                       border: Border.all(color: Colors.grey.shade200),
                     ),
                     child: Column(
                       children: [
                         Row(
                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                           children: [
                             Text(_myCode ?? "생성 중...", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.black)),
                             IconButton(
                               onPressed: _myCode == null ? null : () {
                                 Clipboard.setData(ClipboardData(text: _myCode!));
                                 ScaffoldMessenger.of(context).showSnackBar(
                                   const SnackBar(content: Text("초대 코드가 복사되었습니다!")),
                                 );
                               },
                               icon: const Icon(Icons.copy_rounded, color: Color(0xFF8A2BE2)),
                             )
                           ],
                         ),
                         const Divider(height: 24),
                         SizedBox(
                           width: double.infinity,
                           child: OutlinedButton.icon(
                             onPressed: _myCode == null ? null : _shareReferralCode,
                             icon: const Icon(Icons.share_rounded, size: 20, color: Color(0xFF8A2BE2)),
                             label: const Text("초대 코드 공유하기", style: TextStyle(color: Color(0xFF8A2BE2), fontWeight: FontWeight.bold)),
                             style: OutlinedButton.styleFrom(
                               side: const BorderSide(color: Color(0xFF8A2BE2), width: 1.5),
                               padding: const EdgeInsets.symmetric(vertical: 12),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                             ),
                           ),
                         ),
                       ],
                     ),
                   ),
                   const SizedBox(height: 8),
                   Text("현재까지 초대한 친구: $_referralCount명", style: TextStyle(color: Colors.grey.shade600, fontSize: 13), textAlign: TextAlign.right),
                   
                   const SizedBox(height: 40),

                   // 3. Input Friend's Code
                   const Text("친구 초대 코드 등록", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                   const SizedBox(height: 12),
                   TextField(
                     controller: _codeController,
                     decoration: InputDecoration(
                       hintText: "코드를 입력하세요",
                       filled: true,
                       fillColor: Colors.white,
                       border: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(16),
                         borderSide: BorderSide.none,
                       ),
                       contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                     ),
                     style: const TextStyle(fontSize: 18, letterSpacing: 1),
                     textCapitalization: TextCapitalization.characters,
                   ),
                   const SizedBox(height: 20),
                   SizedBox(
                     height: 56,
                     child: ElevatedButton(
                       onPressed: _isSubmitting ? null : _submitReferralCode,
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.black,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                       ),
                       child: _isSubmitting 
                           ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                           : const Text("코드 등록하기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                     ),
                   ),
                ],
              ),
            ),
    );
  }
}
