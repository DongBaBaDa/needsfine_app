import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// [NEW] 약관 동의 상태를 전달하기 위한 모델 클래스
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
  // [MODIFIED] 단순 bool 대신 TermsAgreement 객체를 전달
  final ValueChanged<TermsAgreement> onAgreedChanged;

  const StepTerms({
    super.key,
    required this.isLoading,
    required this.onAgreedChanged,
  });

  @override
  State<StepTerms> createState() => _StepTermsState();
}

class _StepTermsState extends State<StepTerms> {
  bool _allAgreed = false;
  bool _ageChecked = false;
  bool _serviceChecked = false;
  bool _privacyChecked = false;
  bool _locationChecked = false;
  bool _marketingChecked = false;
  bool _adChecked = false;

  final String _urlService = 'https://needsfine.com/term.html';
  final String _urlLocation = 'https://needsfine.com/location.html';
  final String _urlPrivacy = 'https://needsfine.com/privacy.html';

  // [MODIFIED] 상태 변경 시 상세 정보를 부모에게 전달
  void _notifyParent() {
    bool isRequiredMet = _ageChecked && _serviceChecked && _privacyChecked && _locationChecked;

    widget.onAgreedChanged(TermsAgreement(
      isRequiredMet: isRequiredMet,
      marketing: _marketingChecked,
      ad: _adChecked,
    ));
  }

  void _updateAllAgreed() {
    setState(() {
      _allAgreed = _ageChecked && _serviceChecked && _privacyChecked &&
          _locationChecked && _marketingChecked && _adChecked;
    });
    _notifyParent();
  }

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

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _onAllAgreedChanged(!_allAgreed),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _allAgreed ? const Color(0xFF9C7CFF) : Colors.transparent)
            ),
            child: Row(
              children: [
                Icon(_allAgreed ? Icons.check_circle : Icons.check_circle_outline, color: _allAgreed ? const Color(0xFF9C7CFF) : Colors.grey),
                const SizedBox(width: 12),
                const Text('약관 전체 동의', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 8),

        _buildTermItem('[필수] 만 14세 이상입니다.', _ageChecked, (v) { setState(() => _ageChecked = v!); _updateAllAgreed(); }),
        _buildTermItem('[필수] 서비스 이용약관 동의', _serviceChecked, (v) { setState(() => _serviceChecked = v!); _updateAllAgreed(); }, hasView: true, url: _urlService),
        _buildTermItem('[필수] 개인정보 수집 및 이용 동의', _privacyChecked, (v) { setState(() => _privacyChecked = v!); _updateAllAgreed(); }, hasView: true, url: _urlPrivacy),
        _buildTermItem('[필수] 위치정보 이용약관 동의', _locationChecked, (v) { setState(() => _locationChecked = v!); _updateAllAgreed(); }, hasView: true, url: _urlLocation),
        _buildTermItem('[선택] 마케팅 정보 수신 동의', _marketingChecked, (v) { setState(() => _marketingChecked = v!); _updateAllAgreed(); }),
        _buildTermItem('[선택] 광고성 정보 수신 동의', _adChecked, (v) { setState(() => _adChecked = v!); _updateAllAgreed(); }),
      ],
    );
  }

  Widget _buildTermItem(String title, bool value, ValueChanged<bool?> onChanged, {bool hasView = false, String? url}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(width: 24, height: 24, child: Checkbox(value: value, onChanged: onChanged, activeColor: const Color(0xFF9C7CFF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)))),
          const SizedBox(width: 12),
          Expanded(child: GestureDetector(onTap: () => onChanged(!value), child: Text(title, style: const TextStyle(fontSize: 14)))),
          if (hasView && url != null)
            GestureDetector(
                onTap: () => _launchURL(url),
                child: const Text('보기', style: TextStyle(fontSize: 13, color: Colors.grey, decoration: TextDecoration.underline))
            ),
        ],
      ),
    );
  }
}