import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/widgets/review_card.dart'; // ReviewCard 임포트
import 'package:needsfine_app/models/ranking_models.dart'; // Review 모델 임포트

class ReportManagementScreen extends StatefulWidget {
  const ReportManagementScreen({super.key});

  @override
  State<ReportManagementScreen> createState() => _ReportManagementScreenState();
}

class _ReportManagementScreenState extends State<ReportManagementScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _reports = [];
  Map<String, Review> _relatedReviews = {}; // 신고된 리뷰 데이터 캐싱

  final Color _backgroundColor = const Color(0xFFF2F2F7);

  @override
  void initState() {
    super.initState();
    _fetchReportsAndContent();
  }

  Future<void> _fetchReportsAndContent() async {
    setState(() => _isLoading = true);
    try {
      // 1. 신고 목록 가져오기 (대기중인 것만 가져오거나, 정렬을 상태순으로 할 수 있음)
      // 여기서는 'pending(대기중)' 상태인 것만 가져와서 "할 일 목록"처럼 만듭니다.
      final reportData = await _supabase
          .from('reports')
          .select()
          .eq('status', 'pending') // ✅ [핵심] 대기중인 신고만 불러오기
          .order('created_at', ascending: false);

      final reports = List<Map<String, dynamic>>.from(reportData);

      // 2. 신고된 리뷰 ID 추출 (중복 제거)
      final reviewIds = reports
          .where((r) => r['content_type'] == 'review')
          .map((r) => r['reported_content_id'] as String)
          .toSet()
          .toList();

      // 3. 관련 리뷰 데이터 한꺼번에 가져오기
      if (reviewIds.isNotEmpty) {
        // .filter() 메서드 사용 (supabase_flutter 최신 버전 대응)
        final reviewData = await _supabase
            .from('reviews')
            .select()
            .filter('id', 'in', reviewIds);

        final reviewsList = (reviewData as List).map((m) => Review.fromJson(m)).toList();

        // 맵으로 변환 (ID -> Review 객체)
        _relatedReviews = {for (var r in reviewsList) r.id: r};
      }

      if (mounted) {
        setState(() {
          _reports = reports;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('신고 내역 및 콘텐츠 로드 실패: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ [수정됨] 상태 변경 시 리스트에서 제거하는 로직
  Future<void> _updateStatus(String reportId, String newStatus) async {
    try {
      // 1. 서버 업데이트
      await _supabase.from('reports').update({'status': newStatus}).eq('id', reportId);

      // 2. UI 업데이트: 리스트에서 해당 항목 '삭제' (처리 완료된 것처럼 보이게 함)
      setState(() {
        _reports.removeWhere((element) => element['id'] == reportId);
      });

      // 3. 피드백 메시지
      if (mounted) {
        String actionText = newStatus == 'resolved' ? '처리 완료' : '기각';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("신고가 $actionText 되었습니다."),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("처리 중 오류가 발생했습니다.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: const Text("신고 관리 (대기중)", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchReportsAndContent),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reports.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          final contentId = report['reported_content_id'];
          final review = _relatedReviews[contentId]; // 해당 리뷰 객체 찾기

          return _ReportCard(
            report: report,
            reviewContent: review, // 리뷰 객체 전달
            onResolve: () => _updateStatus(report['id'], 'resolved'),
            onDismiss: () => _updateStatus(report['id'], 'dismissed'),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "대기 중인 신고가 없습니다.\n모두 처리되었습니다!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[500], height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;
  final Review? reviewContent; // 신고된 리뷰 객체 (있으면 표시)
  final VoidCallback onResolve;
  final VoidCallback onDismiss;

  const _ReportCard({
    required this.report,
    this.reviewContent,
    required this.onResolve,
    required this.onDismiss,
  });

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return "${date.year}.${date.month}.${date.day} ${date.hour}:${date.minute}";
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 이미 pending만 필터링해서 오므로 항상 pending 상태임

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 헤더 (타입, 날짜)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "신고 접수",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red[400]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    (report['content_type'] ?? '').toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Text(
                _formatDate(report['created_at']),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. 신고 사유 (강조)
          const Text("신고 사유", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: Text(
              report['reason'] ?? "사유 없음",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
          ),
          const SizedBox(height: 20),

          // 3. 신고된 콘텐츠 표시 (리뷰일 경우 ReviewCard 표시)
          if (reviewContent != null) ...[
            const Text("신고된 리뷰 내용:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 8),
            // ReviewCard를 사용하여 내용 미리보기 (이벤트 비활성화: AbsorbPointer)
            AbsorbPointer(
              absorbing: true, // 관리자 화면에서는 클릭 방지
              child: ReviewCard(
                review: reviewContent!,
                onTap: () {},
                onTapStore: () {},
                onTapProfile: () {},
              ),
            ),
          ] else if (report['content_type'] == 'review') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
              child: const Text("⚠️ 해당 리뷰를 찾을 수 없습니다. (이미 삭제됨)", style: TextStyle(color: Colors.grey, fontSize: 13)),
            )
          ],

          // 4. 관리자 액션 버튼
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDismiss,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("기각 (유지)", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onResolve,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("삭제/제재 처리", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}