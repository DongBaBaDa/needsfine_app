import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/screens/review_detail_screen.dart';
import 'package:needsfine_app/screens/notice_screen.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';

// 🔴 [필수] 상대방 프로필 화면 import (파일 경로에 맞게 주석 해제하세요)
import 'package:needsfine_app/screens/user_profile_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _supabase = Supabase.instance.client;
  static const Color _bg = Colors.white;

  Stream<List<Map<String, dynamic>>> _notificationStream() {
    // ✅ 실시간 구독 (최신순 정렬)
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(50);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          l10n.notifications,
          style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black, fontSize: 20),
        ),
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('오류: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF8A2BE2)));
          }

          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return const Center(child: Text("새로운 알림이 없습니다.", style: TextStyle(color: Colors.grey)));
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),
            itemBuilder: (context, index) {
              // 🔴 개별 아이템 위젯으로 분리 (데이터 로딩 안정성 확보)
              return NotificationItem(notification: notifications[index]);
            },
          );
        },
      ),
    );
  }
}

// ✅ 개별 알림 아이템 (StatefulWidget으로 변경하여 데이터 로딩 관리)
class NotificationItem extends StatefulWidget {
  final Map<String, dynamic> notification;

  const NotificationItem({super.key, required this.notification});

  @override
  State<NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem> {
  final _supabase = Supabase.instance.client;
  static const Color _brand = Color(0xFF8A2BE2);

  String? _realTitle;   // DB에서 가져온 진짜 제목
  String? _realContent; // DB에서 가져온 진짜 내용
  String? _followerNickname; // 팔로워 닉네임

  @override
  void initState() {
    super.initState();
    // 위젯이 생성될 때 진짜 데이터(댓글 내용, 팔로워 이름 등)를 가져옵니다.
    _fetchRealData();
  }

  // 🔴 알림 타입에 따라 원본 테이블 조회 (안전장치 추가)
  Future<void> _fetchRealData() async {
    final type = widget.notification['type'];
    final refId = widget.notification['reference_id'];

    if (refId == null) return;

    try {
      if (type == 'notice') {
        // 공지사항 조회
        final data = await _supabase.from('notices').select('title, content').eq('id', refId).maybeSingle();
        if (data != null && mounted) {
          setState(() {
            _realTitle = data['title'];
            _realContent = data['content'];
          });
        }
      } else if (type == 'comment') {
        // 댓글 조회
        final data = await _supabase.from('comments').select('content').eq('id', refId).maybeSingle();
        if (data != null && mounted) {
          setState(() {
            _realContent = data['content'];
          });
        } else {
          // 데이터가 없으면(삭제됨)
          if(mounted) setState(() => _realContent = "삭제된 댓글입니다.");
        }
      } else if (type == 'follow') {
        // 팔로워 닉네임 조회
        final data = await _supabase.from('profiles').select('nickname').eq('id', refId).maybeSingle();
        if (data != null && mounted) {
          setState(() {
            _followerNickname = data['nickname'];
          });
        }
      }
    } catch (e) {
      debugPrint("데이터 로드 실패: $e");
    }
  }

  Future<void> _markAsRead() async {
    final id = widget.notification['id'];
    final isRead = widget.notification['is_read'] ?? false;
    if (!isRead) {
      await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
    }
  }

  Future<void> _handleNavigation() async {
    final type = widget.notification['type'];
    final refId = widget.notification['reference_id'];

    if (type == 'notice') return;
    if (refId == null) return;

    // ✅ 1. 팔로우 이동
    if (type == 'follow') {
      await _markAsRead();
      // 🔴 UserProfileScreen import 필요
      /*
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UserProfileScreen(userId: refId))
      );
      */
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("프로필 화면으로 이동합니다. (import 필요)")));
      return;
    }

    // ✅ 2. 리뷰/댓글 이동
    if (['comment', 'like', 'comment_like'].contains(type)) {
      await _markAsRead();

      String targetReviewId = refId;
      if (type == 'comment') {
        final commentData = await _supabase.from('comments').select('review_id').eq('id', refId).maybeSingle();
        if (commentData != null) targetReviewId = commentData['review_id'];
      }

      if (!mounted) return;

      showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator(color: _brand)));
      final reviewData = await _supabase.from('reviews').select('*, profiles(*)') .eq('id', targetReviewId).maybeSingle();
      if (mounted) Navigator.pop(context);

      if (reviewData != null && mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewDetailScreen(review: Review.fromJson(reviewData))));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("삭제된 리뷰입니다.")));
      }
    }
  }

  void _goToNoticeScreen() {
    _markAsRead();
    Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticeScreen()));
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return "${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}";
    } catch (e) { return ""; }
  }

  @override
  Widget build(BuildContext context) {
    final noti = widget.notification;
    final type = noti['type'] ?? 'info';
    final isRead = noti['is_read'] ?? false;
    final date = _formatDate(noti['created_at']);

    // ---------------------------------------------------------
    // 1. 공지사항 (Notice)
    // ---------------------------------------------------------
    if (type == 'notice') {
      return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) { if (expanded) _markAsRead(); },
          tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          childrenPadding: EdgeInsets.zero,
          iconColor: Colors.grey[400],
          collapsedIconColor: Colors.grey[400],
          backgroundColor: Colors.grey[50],
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _realTitle ?? noti['title'] ?? '공지사항',
                      style: TextStyle(
                          fontWeight: isRead ? FontWeight.w400 : FontWeight.w700,
                          fontSize: 16,
                          color: Colors.black87
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(date, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  width: 5, height: 5,
                  margin: const EdgeInsets.only(left: 8, top: 8),
                  decoration: const BoxDecoration(color: _brand, shape: BoxShape.circle),
                ),
            ],
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _realContent ?? noti['content'] ?? '내용을 불러오는 중...',
                    style: const TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _goToNoticeScreen,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Text("공지사항 전체보기", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                        Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      );
    }

    // ---------------------------------------------------------
    // 2. 댓글 (Comment)
    // ---------------------------------------------------------
    if (type == 'comment') {
      return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) { if (expanded) _markAsRead(); },
          tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          childrenPadding: EdgeInsets.zero,
          iconColor: Colors.grey[400],
          collapsedIconColor: Colors.grey[400],
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text("새로운 댓글", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.blueAccent)),
                  if (!isRead)
                    Container(
                      width: 5, height: 5,
                      margin: const EdgeInsets.only(left: 6, bottom: 6),
                      decoration: const BoxDecoration(color: _brand, shape: BoxShape.circle),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(date, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
            ],
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ 실제 댓글 내용을 불러오지 못했다면, 알림 테이블에 있는 content라도 보여줌
                  Text(
                    _realContent ?? noti['content'] ?? "내용을 불러오는 중입니다...",
                    style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _handleNavigation,
                    child: Row(
                      children: const [
                        Text("리뷰 확인하러 가기", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _brand)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: _brand),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      );
    }

    // ---------------------------------------------------------
    // 3. 리뷰 도움됨 (Like)
    // ---------------------------------------------------------
    if (type == 'like' || type == 'comment_like') {
      return InkWell(
        onTap: _handleNavigation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text("리뷰 도움됨", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _brand)),
                        if (!isRead)
                          Container(
                            width: 5, height: 5,
                            margin: const EdgeInsets.only(left: 6, bottom: 6),
                            decoration: const BoxDecoration(color: _brand, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(date, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 24),
            ],
          ),
        ),
      );
    }

    // ---------------------------------------------------------
    // 4. ✅ 팔로우 (Follow) - UI 복구됨
    // ---------------------------------------------------------
    if (type == 'follow') {
      return InkWell(
        onTap: _handleNavigation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text("[팔로우] ", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.green)),
                        Expanded(
                          child: Text(
                            // 닉네임 로딩 중이면 '알 수 없는 유저' or DB Title
                            "${_followerNickname ?? '알 수 없는 유저'}님이 팔로우 했어요",
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 5, height: 5,
                            margin: const EdgeInsets.only(left: 6, bottom: 6),
                            decoration: const BoxDecoration(color: _brand, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(date, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                  ],
                ),
              ),
              // 피드 보러가기 화살표
              const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 24),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink(); // 정의되지 않은 타입은 숨김
  }
}