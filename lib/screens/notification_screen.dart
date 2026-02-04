import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/screens/review_detail_screen.dart';
import 'package:needsfine_app/screens/user_profile_screen.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  static const Color _bg = Colors.white;
  static const Color _brand = Color(0xFF8A2BE2);

  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() => _currentTabIndex = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ✅ 최적화: JOIN으로 필요한 모든 데이터 미리 로드
  Stream<List<Map<String, dynamic>>> _notificationStream() async* {
    final currentUser = _supabase.auth.currentUser?.id;
    if (currentUser == null) {
      yield [];
      return;
    }

    final normalStream = _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('receiver_id', currentUser)
        .order('created_at', ascending: false)
        .limit(50);

    await for (var normalNotifications in normalStream) {
      List<Map<String, dynamic>> enrichedNotifications = [];

      // 각 알림에 필요한 데이터를 미리 로드
      for (var noti in normalNotifications) {
        final type = noti['type'];
        final refId = noti['reference_id'];
        Map<String, dynamic> enriched = Map.from(noti);

        try {
          if (type == 'comment' && refId != null) {
            // ✅ 댓글 정보 조회 (별도 쿼리로 분리하여 안정성 확보)
            final commentData = await _supabase
                .from('comments')
                .select('content, user_id, review_id')
                .eq('id', refId)
                .maybeSingle();

            if (commentData != null) {
              enriched['comment_content'] = commentData['content'] ?? '삭제된 댓글';
              
              // ✅ 댓글 작성자 닉네임 별도 조회
              final commenterId = commentData['user_id'];
              if (commenterId != null) {
                final commenterProfile = await _supabase
                    .from('profiles')
                    .select('nickname')
                    .eq('id', commenterId)
                    .maybeSingle();
                enriched['commenter_nickname'] = commenterProfile?['nickname'] ?? '알 수 없는 유저';
              } else {
                enriched['commenter_nickname'] = '알 수 없는 유저';
              }

              final reviewId = commentData['review_id'];
              if (reviewId != null) {
                final reviewData = await _supabase
                    .from('reviews')
                    .select('store_name')
                    .eq('id', reviewId)
                    .maybeSingle();
                enriched['review_store_name'] = reviewData?['store_name'] ?? '매장';
              } else {
                enriched['review_store_name'] = '매장';
              }
            } else {
              // 삭제된 댓글 처리
              enriched['comment_content'] = '삭제된 댓글입니다';
              enriched['commenter_nickname'] = '알 수 없는 유저';
              enriched['review_store_name'] = '리뷰';
            }
          } else if (type == 'follow' && refId != null) {
            // ✅ 팔로워 프로필 조회 (디버그 로그 추가)
            debugPrint('🔔 팔로우 알림 로드: refId=$refId');
            final profileData = await _supabase
                .from('profiles')
                .select('nickname')
                .eq('id', refId)
                .maybeSingle();
            debugPrint('🔔 팔로우 프로필 결과: $profileData');
            enriched['follower_nickname'] = profileData?['nickname'] ?? '알 수 없는 유저';
          } else if (type == 'like' || type == 'comment_like') {
          // ✅ 좋아요/도움됨 알림 데이터 로드 (review_votes 사용!)
          final reviewData = await _supabase
              .from('reviews')
              .select('store_name, user_id')
              .eq('id', refId)
              .maybeSingle();

          if (reviewData != null) {
            enriched['review_store_name'] = reviewData['store_name'] ?? '매장';

            // review_votes 테이블에서 최근 좋아요 누른 사람 조회
            final voteData = await _supabase
                .from('review_votes')
                .select('user_id, profiles!review_votes_user_id_fkey(nickname)')
                .eq('review_id', refId)
                .order('created_at', ascending: false)
                .limit(1)
                .maybeSingle();

            if (voteData != null && voteData['profiles'] != null) {
              enriched['liker_nickname'] = voteData['profiles']['nickname'] ?? '알 수 없는 유저';
            } else {
              enriched['liker_nickname'] = '알 수 없는 유저';
            }
          } else {
            enriched['review_store_name'] = '매장';
            enriched['liker_nickname'] = '알 수 없는 유저';
          }
        }
        } catch (e) {
          debugPrint('알림 데이터 로드 실패 (${noti['id']}): $e');
        }

        enrichedNotifications.add(enriched);
      }

      // 공지사항 추가
      final notices = await _supabase
          .from('notices')
          .select('*')
          .order('created_at', ascending: false)
          .limit(10);

      for (var notice in notices) {
        enrichedNotifications.add({
          'id': 'notice_${notice['id']}',
          'type': 'notice',
          'title': notice['title'],
          'content': notice['content'],
          'created_at': notice['created_at'],
          'is_read': false,
          'reference_id': notice['id'],
        });
      }

      enrichedNotifications.sort((a, b) =>
          DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at']))
      );

      yield enrichedNotifications;
    }
  }

  List<Map<String, dynamic>> _filterNotifications(List<Map<String, dynamic>> notifications, int tabIndex) {
    switch (tabIndex) {
      case 0: return notifications;
      case 1: return notifications.where((n) => n['type'] == 'notice').toList();
      case 2: return notifications.where((n) => n['type'] == 'follow').toList();
      case 3: return notifications.where((n) => ['like', 'comment', 'comment_like'].contains(n['type'])).toList();
      default: return notifications;
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final currentUser = _supabase.auth.currentUser?.id;
      if (currentUser == null) return;

      switch (_currentTabIndex) {
        case 0: // 전체
          await _supabase
              .from('notifications')
              .update({'is_read': true})
              .eq('receiver_id', currentUser)
              .eq('is_read', false);
          break;
        case 1: // 공지사항 - 읽음 처리 안함
          return;
        case 2: // 팔로우
          await _supabase
              .from('notifications')
              .update({'is_read': true})
              .eq('receiver_id', currentUser)
              .eq('type', 'follow')
              .eq('is_read', false);
          break;
        case 3: // 좋아요·댓글
          await _supabase
              .from('notifications')
              .update({'is_read': true})
              .eq('receiver_id', currentUser)
              .or('type.eq.like,type.eq.comment,type.eq.comment_like')
              .eq('is_read', false);
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모두 읽음 처리되었습니다'))
        );
      }
    } catch (e) {
      debugPrint('모두 읽음 처리 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text("알림", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black, fontSize: 20, letterSpacing: -0.5)),
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text("모두 읽음처리", style: TextStyle(color: _brand, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: _bg,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              labelColor: _brand,
              unselectedLabelColor: Colors.grey,
              indicatorColor: _brand,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: "전체"),
                Tab(text: "공지사항"),
                Tab(text: "팔로우"),
                Tab(text: "좋아요·도움됨·댓글"),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey[100]),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _notificationStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('오류: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: _brand));
                }

                final allNotifications = snapshot.data ?? [];
                final filteredNotifications = _filterNotifications(allNotifications, _currentTabIndex);

                if (filteredNotifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text("새로운 알림이 없습니다.", style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filteredNotifications.length,
                  separatorBuilder: (context, index) => Divider(height: 1, thickness: 1, color: Colors.grey[100]),
                  itemBuilder: (context, index) {
                    return NotificationItem(notification: filteredNotifications[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ 완전히 리팩토링된 NotificationItem - 공지사항 스타일 적용
class NotificationItem extends StatelessWidget {
  final Map<String, dynamic> notification;
  const NotificationItem({super.key, required this.notification});

  static const Color _brand = Color(0xFF8A2BE2);

  Future<void> _markAsRead(BuildContext context) async {
    final supabase = Supabase.instance.client;
    final id = notification['id'];
    final type = notification['type'];

    if (type == 'notice') return;

    final isRead = notification['is_read'] ?? false;
    if (isRead) return;

    try {
      await supabase.from('notifications').update({'is_read': true}).eq('id', id);
    } catch (e) {
      debugPrint('읽음 처리 실패: $e');
    }
  }

  Future<void> _handleNavigation(BuildContext context) async {
    await _markAsRead(context);

    final supabase = Supabase.instance.client;
    final type = notification['type'];
    final refId = notification['reference_id'];

    if (type == 'follow' && refId != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: refId)));
    } else if ((type == 'comment' || type == 'like' || type == 'comment_like') && refId != null) {
      try {
        String reviewId = refId;
        if (type == 'comment') {
          final commentData = await supabase.from('comments').select('review_id').eq('id', refId).maybeSingle();
          if (commentData != null) {
            reviewId = commentData['review_id'];
          } else {
            // 삭제된 댓글
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('삭제된 댓글입니다'))
              );
            }
            return;
          }
        }

        final reviewData = await supabase.from('reviews').select('*, profiles(*)').eq('id', reviewId).maybeSingle();
        if (reviewData != null && context.mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewDetailScreen(review: Review.fromJson(reviewData))));
        }
      } catch (e) {
        debugPrint('리뷰 조회 실패: $e');
      }
    }
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('yyyy.MM.dd').format(dt);
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = notification['type'] ?? '';
    final isRead = notification['is_read'] ?? false;
    final date = _formatDate(notification['created_at']);

    // ✅ 공지사항 - 다른 알림과 동일한 Row 구조 적용 (읽음 표시 점 위치에 동일한 여백)
    if (type == 'notice') {
      return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          childrenPadding: EdgeInsets.zero,
          iconColor: _brand,
          collapsedIconColor: Colors.grey,
          backgroundColor: Colors.grey[50],
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // ✅ 다른 알림들과 동일한 14px 여백 (6px 점 + 8px margin)
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(notification['title'] ?? '공지사항', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, height: 1.4)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 14.0),
                child: Text(date, style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(38, 0, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(notification['content'] ?? '', style: const TextStyle(height: 1.8, fontSize: 15, color: Colors.black87)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ✅ 댓글 알림 - 공지사항 스타일 적용
    if (type == 'comment') {
      final commenter = notification['commenter_nickname'] ?? '알 수 없는 유저';
      final storeName = notification['review_store_name'] ?? '리뷰';
      final content = notification['comment_content'] ?? '댓글 내용을 불러올 수 없습니다';

      return Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) { if (expanded) _markAsRead(context); },
          tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          childrenPadding: EdgeInsets.zero,
          iconColor: _brand,
          collapsedIconColor: Colors.grey,
          backgroundColor: Colors.grey[50],
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(color: !isRead ? _brand : Colors.transparent, shape: BoxShape.circle),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
                        children: [
                          TextSpan(text: commenter, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const TextSpan(text: "님이 당신의 "),
                          TextSpan(text: storeName, style: const TextStyle(fontWeight: FontWeight.w700, color: _brand)),
                          const TextSpan(text: " 리뷰에 댓글을 달았습니다"),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 14.0),
                child: Text(date, style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          children: [
            InkWell(
              onTap: () => _handleNavigation(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(38, 0, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(content, style: const TextStyle(height: 1.8, fontSize: 15, color: Colors.black87)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ✅ 팔로우 알림 - 공지사항 스타일 적용 (InkWell)
    if (type == 'follow') {
      final follower = notification['follower_nickname'] ?? '알 수 없는 유저';

      return InkWell(
        onTap: () async {
          await _markAsRead(context);
          await _handleNavigation(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(color: !isRead ? _brand : Colors.transparent, shape: BoxShape.circle),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
                        children: [
                          TextSpan(text: follower, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const TextSpan(text: "님이 당신을 팔로우 했습니다"),
                        ],
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 14.0),
                child: Text(date, style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ 좋아요/도움됨 알림 - 공지사항 스타일 적용 (InkWell)
    if (type == 'like' || type == 'comment_like') {
      final liker = notification['liker_nickname'] ?? '알 수 없는 유저';
      final storeName = notification['review_store_name'] ?? '리뷰';

      return InkWell(
        onTap: () async {
          await _markAsRead(context);
          await _handleNavigation(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6, height: 6,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(color: !isRead ? _brand : Colors.transparent, shape: BoxShape.circle),
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
                        children: [
                          const TextSpan(text: "당신의 "),
                          TextSpan(text: storeName, style: const TextStyle(fontWeight: FontWeight.w700, color: _brand)),
                          const TextSpan(text: "의 리뷰가 "),
                          TextSpan(text: liker, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const TextSpan(text: "님에게 도움이 되었습니다"),
                        ],
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 14.0),
                child: Text(date, style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}