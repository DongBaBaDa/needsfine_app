import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// [모델] 약관 동의 상태
class TermsAgreement {
  final bool isRequiredMet; // 필수 약관 충족 여부
  final bool marketing;     // 마케팅 동의 여부
  final bool ad;            // 광고 동의 여부

  TermsAgreement({
    required this.isRequiredMet,
    required this.marketing,
    required this.ad,
  });
}

class StepTerms extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onComplete; // [필수] 가입 완료 버튼 클릭 시 실행
  final ValueChanged<TermsAgreement>? onAgreedChanged; // [선택] 부모에게 데이터 전달

  const StepTerms({
    super.key,
    required this.isLoading,
    required this.onComplete,
    this.onAgreedChanged,
  });

  @override
  State<StepTerms> createState() => _StepTermsState();
}

class _StepTermsState extends State<StepTerms> {
  // 개별 약관 상태
  bool _allAgreed = false;
  bool _ageChecked = false;      // 필수
  bool _serviceChecked = false;  // 필수
  bool _privacyChecked = false;  // 필수
  bool _locationChecked = false; // 필수
  bool _marketingChecked = false;// 선택
  bool _adChecked = false;       // 선택

  // 약관 URL
  final String _urlService = 'https://needsfine.com/term.html';
  final String _urlLocation = 'https://needsfine.com/location.html';
  final String _urlPrivacy = 'https://needsfine.com/privacy.html';

  // 상태 변경 알림
  void _notifyParent() {
    // 필수 약관 4가지가 모두 체크되었는지 확인
    bool isRequiredMet = _ageChecked && _serviceChecked && _privacyChecked && _locationChecked;

    if (widget.onAgreedChanged != null) {
      widget.onAgreedChanged!(TermsAgreement(
        isRequiredMet: isRequiredMet,
        marketing: _marketingChecked,
        ad: _adChecked,
      ));
    }
  }

  // 전체 동의 토글
  void _onAllAgreedChanged(bool? value) {
    if (value == null) return;
    setState(() {
      _allAgreed = value;
      _ageChecked = value;
      _serviceChecked = value;
      _privacyChecked = value;
      _locationChecked = value;
      _marketingChecked = value;
      _adChecked = value;
    });
    _notifyParent();
  }

  // 개별 동의 토글 (하나라도 꺼지면 전체 동의 해제, 모두 켜지면 전체 동의 체크)
  void _updateAllAgreed() {
    setState(() {
      _allAgreed = _ageChecked && _serviceChecked && _privacyChecked &&
          _locationChecked && _marketingChecked && _adChecked;
    });
    _notifyParent();
  }

  // URL 열기
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 필수 약관이 모두 체크되었는지 확인 (버튼 활성화용)
    final bool isEnabled = _ageChecked && _serviceChecked && _privacyChecked && _locationChecked;

    return Column(
      children: [
        // 상단 타이틀 (UserJoinScreen UI와 맞춤)
        const Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('약관에 동의해주세요', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('원활한 서비스 이용을 위해 필요해요.', style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // 전체 동의 박스
        GestureDetector(
          onTap: () => _onAllAgreedChanged(!_allAgreed),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _allAgreed ? const Color(0xFF8A2BE2) : Colors.grey.shade300)
            ),
            child: Row(
              children: [
                Icon(
                  _allAgreed ? Icons.check_circle : Icons.check_circle_outline,
                  color: _allAgreed ? const Color(0xFF8A2BE2) : Colors.grey,
                ),
                const SizedBox(width: 12),
                const Text('약관 전체 동의', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(height: 1),
        const SizedBox(height: 16),

        // 개별 약관 리스트
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTermItem('[필수] 만 14세 이상입니다.', _ageChecked, (v) { setState(() => _ageChecked = v!); _updateAllAgreed(); }),
                _buildTermItem('[필수] 서비스 이용약관 동의', _serviceChecked, (v) { setState(() => _serviceChecked = v!); _updateAllAgreed(); }, hasView: true, url: _urlService),
                _buildTermItem('[필수] 개인정보 수집 및 이용 동의', _privacyChecked, (v) { setState(() => _privacyChecked = v!); _updateAllAgreed(); }, hasView: true, url: _urlPrivacy),
                _buildTermItem('[필수] 위치정보 이용약관 동의', _locationChecked, (v) { setState(() => _locationChecked = v!); _updateAllAgreed(); }, hasView: true, url: _urlLocation),
                _buildTermItem('[선택] 마케팅 정보 수신 동의', _marketingChecked, (v) { setState(() => _marketingChecked = v!); _updateAllAgreed(); }),
                _buildTermItem('[선택] 광고성 정보 수신 동의', _adChecked, (v) { setState(() => _adChecked = v!); _updateAllAgreed(); }),
              ],
            ),
          ),
        ),

        // [중요] 회원가입 완료 버튼 추가
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            // 필수 약관이 충족되고, 로딩 중이 아닐 때만 버튼 활성화
            onPressed: (isEnabled && !widget.isLoading) ? widget.onComplete : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8A2BE2),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: widget.isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('회원가입 완료', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // 약관 항목 빌더
  Widget _buildTermItem(String title, bool value, ValueChanged<bool?> onChanged, {bool hasView = false, String? url}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                  value: value,
                  onChanged: onChanged,
                  activeColor: const Color(0xFF8A2BE2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))
              )
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(!value),
              child: Text(title, style: const TextStyle(fontSize: 14, color: Colors.black87)),
            ),
          ),
          if (hasView && url != null)
            GestureDetector(
                onTap: () => _launchURL(url),
                child: const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Text('보기', style: TextStyle(fontSize: 13, color: Colors.grey, decoration: TextDecoration.underline)),
                )
            ),
        ],
      ),
    );
  }
}