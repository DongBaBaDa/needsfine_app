
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';

class TasteSurveyModal extends StatefulWidget {
  final VoidCallback onCompleted;

  const TasteSurveyModal({super.key, required this.onCompleted});

  @override
  State<TasteSurveyModal> createState() => _TasteSurveyModalState();
}

class _TasteSurveyModalState extends State<TasteSurveyModal> {
  // Hardcoded tags for now, will fetch from DB later if needed
  final List<String> _options = [
    '한식 파', '중식 러버', '일식 매니아', '양식 선호',
    '매운맛 고수', '맵찔이', '가성비 중시', '분위기 깡패',
    '혼밥족', '데이트 맛집', '디저트 필수', '노포 감성'
  ];
  final Set<String> _selectedOptions = {};
  bool _isSaving = false;

  void _toggleOption(String option) {
    setState(() {
      if (_selectedOptions.contains(option)) {
        _selectedOptions.remove(option);
      } else {
        _selectedOptions.add(option);
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // Actual DB insertion logic for taste_tags
      await Supabase.instance.client
          .from('profiles')
          .update({'taste_tags': _selectedOptions.toList()})
          .eq('id', userId);
      
      if (mounted) {
        widget.onCompleted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.saveError}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Map options to localized strings
    final Map<String, String> optionMap = {
      '한식 파': l10n.tasteKorean,
      '중식 러버': l10n.tasteChinese,
      '일식 매니아': l10n.tasteJapanese,
      '양식 선호': l10n.tasteWestern,
      '매운맛 고수': l10n.tasteSpicyLover,
      '맵찔이': l10n.tasteSpicyHater,
      '가성비 중시': l10n.tasteCostEffective,
      '분위기 깡패': l10n.tasteAtmosphere,
      '혼밥족': l10n.tasteSolo,
      '데이트 맛집': l10n.tasteDate,
      '디저트 필수': l10n.tasteDessert,
      '노포 감성': l10n.tasteOldGen,
    };

    return Container( // Modal bottom sheet content
      padding: const EdgeInsets.all(24.0),
      height: MediaQuery.of(context).size.height * 0.8, // Take up significant height
      decoration: const BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.only(
           topLeft: Radius.circular(20),
           topRight: Radius.circular(20),
         )
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Text(
            l10n.tasteSurveyTitle,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tasteSurveySubtitle,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _options.length,
              itemBuilder: (context, index) {
                final optionKey = _options[index];
                final optionLabel = optionMap[optionKey] ?? optionKey;
                final isSelected = _selectedOptions.contains(optionKey);
                return GestureDetector(
                  onTap: () => _toggleOption(optionKey),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFC87CFF).withOpacity(0.1) : Colors.white,
                      border: Border.all(
                        color: isSelected ? const Color(0xFFC87CFF) : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      optionLabel,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFFC87CFF) : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          if (_isSaving)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: widget.onCompleted, // Skip
                    child: Text(l10n.doItLater, style: const TextStyle(color: Colors.grey)),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _selectedOptions.isNotEmpty ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC87CFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(l10n.start, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
