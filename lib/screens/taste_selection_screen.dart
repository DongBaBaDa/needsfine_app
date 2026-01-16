import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';

class TasteSelectionScreen extends StatefulWidget {
  const TasteSelectionScreen({super.key});

  @override
  State<TasteSelectionScreen> createState() => _TasteSelectionScreenState();
}

class _TasteSelectionScreenState extends State<TasteSelectionScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  // 선택 가능한 전체 태그 목록
  final List<String> _allTags = [
    '한식', '중식', '일식', '양식', '분식', '아시안',
    '조용한', '활기찬', '분위기 좋은', '뷰가 좋은',
    '가성비', '고급스러운', '혼밥하기 좋은', '단체모임',
    '디저트', '매운맛', '비건', '노키즈존', '반려동물'
  ];

  Set<String> _selectedTastes = {};

  @override
  void initState() {
    super.initState();
    _loadUserTags();
  }

  Future<void> _loadUserTags() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final data = await _supabase
          .from('profiles')
          .select('taste_tags')
          .eq('id', userId)
          .single();

      if (data != null && data['taste_tags'] != null) {
        setState(() {
          // DB에서 가져온 리스트를 Set으로 변환
          _selectedTastes = Set<String>.from(List<dynamic>.from(data['taste_tags']));
        });
      }
    } catch (e) {
      debugPrint("태그 불러오기 실패: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveTags() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('profiles').update({
        'taste_tags': _selectedTastes.toList(),
      }).eq('id', userId);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("저장 에러: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("저장에 실패했습니다. 잠시 후 다시 시도해주세요.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFFDF9),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: AppBar(
        title: const Text('나의 입맛', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFFDF9),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveTags,
            child: const Text("저장", style: TextStyle(color: kNeedsFinePurple, fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [섹션 1] 마인드맵 스타일 태그 선택
            _buildMindMapSection(),

            const Divider(thickness: 8, color: Color(0xFFF5F5F5)),

            // [섹션 2] Julie Zhuo 스타일: 최근 미식 지표 (데이터 없음 상태로 복구)
            _buildRecentStatsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildMindMapSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            "What is your Flavor?",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            "나를 표현하는 태그를 선택해주세요 (최대 5개)\n선택한 태그는 마이페이지에 표시됩니다.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
          ),
          const SizedBox(height: 32),
          Center(
            child: Wrap(
              spacing: 12,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: _allTags.map((tag) => _buildMindMapChip(tag)).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMindMapChip(String label) {
    final isSelected = _selectedTastes.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedTastes.remove(label);
          } else {
            if (_selectedTastes.length >= 5) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("태그는 최대 5개까지 선택 가능합니다.")),
              );
              return;
            }
            _selectedTastes.add(label);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kNeedsFinePurple : Colors.white,
          border: isSelected ? null : Border.all(color: Colors.black12, width: 1.5),
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [BoxShadow(color: kNeedsFinePurple.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ✅ 2. 통계 섹션 복구 (데이터가 없을 때의 UI)
  Widget _buildRecentStatsSection() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.history_edu, color: kNeedsFinePurple),
              SizedBox(width: 8),
              Text("Recent Flavor Footprint", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "최근 3개월 간 회원님이 남기신 발자국이에요.",
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 24),

          // 인사이트 카드 (데이터가 아직 없으므로 안내 메시지 표시)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.bar_chart_rounded, size: 40, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                const Text(
                  "아직 데이터가 충분하지 않아요",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  "니즈파인에서 활동을 시작하면\n취향 분석 리포트가 이곳에 나타납니다.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}