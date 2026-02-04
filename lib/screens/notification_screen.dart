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

  Stream<List<Map<String, dynamic>>> _notificationStream() async* {
    final normalStream = _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(50);

    await for (var normalNotifications in normalStream) {
      final filtered = normalNotifications.where((n) => n['type'] != 'notice').toList();
      
      final notices = await _supabase
          .from('notices')
          .select('*')
          .order('created_at', ascending: false)
          .limit(10);
      
      List<Map<String, dynamic>> allNotifications = List.from(filtered);
      for (var notice in notices) {
        allNotifications.add({
          'id': 'notice_${notice['id']}',
          'type': 'notice',
          'title': notice['title'],
          'content': notice['content'],
          'created_at': notice['created_at'],
          'is_read': false,
          'reference_id': notice['id'],
        });
      }
      
      allNotifications.sort((a, b) => 
        DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at']))
      );
      
      yield allNotifications;
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

class NotificationItem extends StatefulWidget {
  final Map<String, dynamic> notification;
  const NotificationItem({super.key, required this.notification});

  @override
  State<NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem> {
  final _supabase = Supabase.instance.client;
  static const Color _brand = Color(0xFF8A2BE2);

  String? _commenterNickname;
  String? _reviewStoreName;
  String? _commentContent;
  String? _followerNickname;
  String? _likerNickname;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final type = widget.notification['type'];
    final refId = widget.notification['reference_id'];

    if (refId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      if (type == 'notice') {
        // 공지사항은 이미 데이터가 있음
      } else if (type == 'comment') {
        final commentData = await _supabase
            .from('comments')
            .select('content, user_id, review_id')
            .eq('id', refId)
            .maybeSingle();

        debugPrint('댓글 데이터: $commentData');

        if (commentData != null && mounted) {
          final content = commentData['content'];
          final userId = commentData['user_id'];
          final reviewId = commentData['review_id'];
          
          debugPrint('content: $content, userId: $userId, reviewId: $reviewId');
          
          if (content != null) {
            setState(() => _commentContent = content);
          }

          if (userId != null) {
            final userData = await _supabase.from('profiles').select('nickname').eq('id', userId).maybeSingle();
            debugPrint('유저 데이터: $userData');
            if (userData != null && mounted) {
              setState(() => _commenterNickname = userData['nickname']);
            }
          }

          if (reviewId != null) {
            final reviewData = await _supabase.from('reviews').select('store_name').eq('id', reviewId).maybeSingle();
            debugPrint('리뷰 데이터: $reviewData');
            if (reviewData != null && mounted) {
              setState(() => _reviewStoreName = reviewData['store_name']);
            }
          }
        } else {
          debugPrint('댓글을 찾을 수 없음: refId=$refId');
        }
      } else if (type == 'follow') {
        final data = await _supabase.from('profiles').select('nickname').eq('id', refId).maybeSingle();
        if (data != null && mounted) {
          setState(() => _followerNickname = data['nickname']);
        }
      } else if (type == 'like' || type == 'comment_like') {
        final reviewData = await _supabase.from('reviews').select('store_name, user_id').eq('id', refId).maybeSingle();
        if (reviewData != null && mounted) {
          setState(() => _reviewStoreName = reviewData['store_name']);

          final saveData = await _supabase
              .from('review_saves')
              .select('user_id')
              .eq('review_id', refId)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

          if (saveData != null) {
            final saverId = saveData['user_id'];
            if (saverId != null) {
              final userData = await _supabase.from('profiles').select('nickname').eq('id', saverId).maybeSingle();
              if (userData != null && mounted) {
                setState(() => _likerNickname = userData['nickname']);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('데이터 로딩 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead() async {
    final id = widget.notification['id'];
    final type = widget.notification['type'];
    
    if (type == 'notice') return;

    final isRead = widget.notification['is_read'] ?? false;
    if (isRead) return;

    try {
      await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
    } catch (e) {
      debugPrint('읽음 처리 실패: $e');
    }
  }

  Future<void> _handleNavigation() async {
    await _markAsRead();

    final type = widget.notification['type'];
    final refId = widget.notification['reference_id'];

    if (type == 'follow' && refId != null) {
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: refId)));
      }
    } else if ((type == 'comment' || type == 'like' || type == 'comment_like') && refId != null) {
      try {
        String reviewId = refId;
        if (type == 'comment') {
          final commentData = await _supabase.from('comments').select('review_id').eq('id', refId).maybeSingle();
          if (commentData != null) {
            reviewId = commentData['review_id'];
          }
        }
        
        final reviewData = await _supabase.from('reviews').select('*, profiles(*)').eq('id', reviewId).maybeSingle();
        if (reviewData != null && mounted) {
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
    final noti = widget.notification;
    final type = noti['type'] ?? '';
    final isRead = noti['is_read'] ?? false;
    final date = _formatDate(noti['created_at']);

    if (type == 'notice') {
      return Column(
        children: [
          Theme(
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
                      Container(
                        width: 6, height: 6,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: const BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
                      ),
                      Expanded(
                        child: Text(noti['title'] ?? '공지사항', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, height: 1.4)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(date, style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500)),
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
                      Text(noti['content'] ?? '', style: const TextStyle(height: 1.8, fontSize: 15, color: Colors.black87)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (type == 'comment') {
      if (_isLoading) {
        return const Padding(padding: EdgeInsets.all(24.0), child: Center(child: CircularProgressIndicator(color: _brand)));
      }

      final commenter = _commenterNickname ?? '알 수 없는 유저';
      final storeName = _reviewStoreName ?? '리뷰';
      final content = _commentContent ?? '댓글 내용';

      return Column(
        children: [
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              onExpansionChanged: (expanded) { if (expanded) _markAsRead(); },
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
                            style: const TextStyle(fontSize: 16, color: Colors.black87),
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
                  Text(date, style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                ],
              ),
              children: [
                InkWell(
                  onTap: _handleNavigation,
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
          ),
        ],
      );
    }

    if (type == 'follow') {
      if (_isLoading) {
        return const Padding(padding: EdgeInsets.all(24.0), child: Center(child: CircularProgressIndicator(color: _brand)));
      }

      final follower = _followerNickname ?? '알 수 없는 유저';

      return InkWell(
        onTap: _handleNavigation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 6, height: 6,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(color: !isRead ? _brand : Colors.transparent, shape: BoxShape.circle),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                        children: [
                          TextSpan(text: follower, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const TextSpan(text: "님이 당신을 팔로우 했습니다"),
                        ],
                      ),
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

    if (type == 'like' || type == 'comment_like') {
      if (_isLoading) {
        return const Padding(padding: EdgeInsets.all(24.0), child: Center(child: CircularProgressIndicator(color: _brand)));
      }

      final liker = _likerNickname ?? '알 수 없는 유저';
      final storeName = _reviewStoreName ?? '리뷰';

      return InkWell(
        onTap: _handleNavigation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 6, height: 6,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(color: !isRead ? _brand : Colors.transparent, shape: BoxShape.circle),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                        children: [
                          const TextSpan(text: "당신의 "),
                          TextSpan(text: storeName, style: const TextStyle(fontWeight: FontWeight.w700, color: _brand)),
                          const TextSpan(text: "의 리뷰가 "),
                          TextSpan(text: liker, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const TextSpan(text: "님에게 도움이 되었습니다"),
                        ],
                      ),
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

    return const SizedBox.shrink();
  }
}