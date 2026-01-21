import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/screens/review_detail_screen.dart';
import 'package:needsfine_app/screens/notice_screen.dart';
// import 'package:needsfine_app/screens/user_profile_screen.dart'; // 상대방 프로필 화면 (필요 시 주석 해제)

// ✅ 다국어 패키지 임포트
import 'package:needsfine_app/l10n/app_localizations.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _supabase = Supabase.instance.client;

  // ✅ 드롭다운 확장 상태 관리
  final Set<String> _expandedIds = {};

  Stream<List<Map<String, dynamic>>> _notificationStream() {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(100);
  }

  // ✅ 1. 알림 확장/축소 및 읽음 처리 (로직 유지)
  Future<void> _toggleExpand(Map<String, dynamic> noti) async {
    final String id = noti['id'];
    final bool isRead = noti['is_read'] ?? false;

    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });

    if (!isRead && _expandedIds.contains(id)) {
      await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
    }
  }

  // ✅ 2. 상세 페이지 이동 로직 (로직 유지)
  Future<void> _navigateToDetail(Map<String, dynamic> noti) async {
    // l10n 사용을 위해 context 접근이 필요하지만 async 함수 내라 mounted 체크 필수
    final l10n = AppLocalizations.of(context)!;

    final String type = noti['type'] ?? '';
    final String? refId = noti['reference_id'];

    if (refId == null) {
      _showSnackBar(l10n.loadError); // "정보를 불러올 수 없습니다"
      return;
    }

    try {
      if (['comment', 'like', 'comment_like'].contains(type)) {
        _showLoadingDialog();
        final reviewData = await _supabase
            .from('reviews')
            .select('*, profiles(*)')
            .eq('id', refId)
            .maybeSingle();

        if (mounted) Navigator.pop(context);

        if (reviewData != null && mounted) {
          final review = Review.fromJson(reviewData);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ReviewDetailScreen(review: review)),
          );
        } else {
          _showSnackBar("삭제된 리뷰입니다."); // 특정 에러 메시지는 하드코딩 유지 (키 없음)
        }
      } else if (type == 'notice') {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticeScreen()));
      } else if (type == 'follow') {
        _showSnackBar(l10n.developingMessage); // "현재 개발 중인 기능입니다."
        // Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: refId)));
      }
    } catch (e) {
      debugPrint("이동 오류: $e");
      if(mounted && Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      }
      return "${dt.month}/${dt.day}";
    } catch (e) {
      return "";
    }
  }

  Map<String, dynamic> _getNotificationStyle(String type) {
    switch (type) {
      case 'like':
        return {'icon': Icons.thumb_up_alt, 'color': const Color(0xFFC87CFF)};
      case 'comment_like':
        return {'icon': Icons.favorite, 'color': Colors.pinkAccent};
      case 'comment':
        return {'icon': Icons.chat_bubble, 'color': Colors.blueAccent};
      case 'follow':
        return {'icon': Icons.person_add, 'color': Colors.green};
      case 'notice':
        return {'icon': Icons.campaign, 'color': Colors.orange};
      default:
        return {'icon': Icons.notifications, 'color': Colors.grey};
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ l10n 객체 가져오기
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      // ✅ [Design] 배경색 변경: Light Grey
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        // "알림"
        title: Text(l10n.notifications, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0, // ✅ [Design] 그림자 제거
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('오류: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) return _buildEmptyState(l10n);

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: notifications.length,
            // ✅ [Design] Divider 대신 SizedBox 사용
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final noti = notifications[index];
              return _buildNotificationItem(noti, l10n);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Color(0xFFE0E0E0), shape: BoxShape.circle),
            child: const Icon(Icons.notifications_off_outlined, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 16),
          // "정보 없음" (또는 적절한 빈 상태 메시지)
          Text(l10n.noInfo, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  // ✅ [Design] 카드 스타일 적용
  Widget _buildNotificationItem(Map<String, dynamic> noti, AppLocalizations l10n) {
    final String id = noti['id'];
    final bool isRead = noti['is_read'] ?? false;
    final String type = noti['type'] ?? 'info';
    final String title = noti['title'] ?? l10n.notifications; // '알림'
    final String content = noti['content'] ?? '';
    final String date = _formatDate(noti['created_at']);

    // 확장 여부
    final bool isExpanded = _expandedIds.contains(id);

    final style = _getNotificationStyle(type);
    final IconData icon = style['icon'];
    final Color iconColor = style['color'];

    // ✅ [Design] Container (Card Style)
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. 헤더 (InkWell with Radius)
          InkWell(
            onTap: () => _toggleExpand(noti),
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(16),
              bottom: isExpanded ? Radius.zero : const Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 아이콘
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: iconColor.withOpacity(0.08), // ✅ [Design] More transparent
                        child: Icon(icon, size: 20, color: iconColor),
                      ),
                      if (!isRead)
                        Positioned(
                          top: 0, right: 0,
                          child: Container(
                            width: 10, height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 1.5)),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // 텍스트 영역
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  // ✅ [Design] 읽음 여부에 따른 폰트 굵기/색상 차별화
                                  fontWeight: isRead ? FontWeight.normal : FontWeight.w800,
                                  fontSize: 15,
                                  color: isRead ? const Color(0xFF555555) : Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(date, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // 접혔을 때 한 줄 요약
                        if (!isExpanded)
                          Text(
                            content,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              height: 1.4,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  // 화살표
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. 드롭다운 내용 (확장 시)
          if (isExpanded)
            InkWell(
              onTap: () => _navigateToDetail(noti),
              // 하단 모서리 둥글게
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Container(
                width: double.infinity,
                color: Colors.white, // ✅ [Design] Seamless white background
                padding: const EdgeInsets.fromLTRB(76, 0, 20, 20), // 아이콘 너비만큼 들여쓰기
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content,
                      style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
                    ),
                    const SizedBox(height: 12),

                    // ✅ [Design] Text-only Link Style Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // "더보기" (자세히 보기)
                          Text(
                            l10n.more,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8A2BE2), // NeedsFine Purple
                                fontWeight: FontWeight.bold
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF8A2BE2)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}