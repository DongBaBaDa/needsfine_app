import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/screens/review_detail_screen.dart';
import 'package:needsfine_app/screens/user_profile_screen.dart';
import 'package:needsfine_app/screens/admin_dashboard_screen.dart'; // import corrected
import 'package:needsfine_app/l10n/app_localizations.dart'; // import added

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  late TabController _tabController;
  int _currentTabIndex = 0;

  // UI Colors
  static const Color _bg = Color(0xFFFAFAFA);
  static const Color _brand = Color(0xFF8A2BE2);

  @override
  void initState() {
    super.initState();
    // ✅ 탭 개수 5개로 증가
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
            Map<String, dynamic>? commentData;

            // 1차 시도
            commentData = await _supabase
                .from('comments')
                .select('content, user_id, review_id')
                .eq('id', refId)
                .maybeSingle();
            
            // 2차 시도
            if (commentData == null) {
              final fallbackComments = await _supabase
                  .from('comments')
                  .select('content, user_id, review_id')
                  .eq('review_id', refId)
                  .order('created_at', ascending: false)
                  .limit(1);
              
              if (fallbackComments.isNotEmpty) {
                commentData = fallbackComments.first;
              }
            }

            if (commentData != null) {
              enriched['comment_content'] = commentData['content'] ?? '삭제된 댓글';
              
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
              enriched['comment_content'] = '삭제된 댓글입니다';
              enriched['commenter_nickname'] = '알 수 없는 유저';
              enriched['review_store_name'] = '리뷰';
            }
          } else if (type == 'follow' && refId != null) {
            final profileData = await _supabase
                .from('profiles')
                .select('nickname')
                .eq('id', refId)
                .maybeSingle();
            enriched['follower_nickname'] = profileData?['nickname'] ?? '알 수 없는 유저';
          } else if (type == 'like' || type == 'comment_like') {
            final reviewData = await _supabase
                .from('reviews')
                .select('store_name, user_id')
                .eq('id', refId)
                .maybeSingle();

            if (reviewData != null) {
              enriched['review_store_name'] = reviewData['store_name'] ?? '매장';
              final voteData = await _supabase
                  .from('review_votes')
                  .select('user_id')
                  .eq('review_id', refId)
                  .order('created_at', ascending: false)
                  .limit(1)
                  .maybeSingle();

              if (voteData != null) {
                final likerId = voteData['user_id'];
                if (likerId != null) {
                  final likerProfile = await _supabase
                      .from('profiles')
                      .select('nickname')
                      .eq('id', likerId)
                      .maybeSingle();
                  enriched['liker_nickname'] = likerProfile?['nickname'] ?? '알 수 없는 유저';
                } else {
                  enriched['liker_nickname'] = '알 수 없는 유저';
                }
              } else {
                enriched['liker_nickname'] = '알 수 없는 유저';
              }
            } else {
              enriched['review_store_name'] = '매장';
              enriched['liker_nickname'] = '알 수 없는 유저';
            }
          } else if (type == 'admin_alert') {
            // Admin alerts need no special enrichment, title/content is in notification
          }
        } catch (e) {
          debugPrint('🚨 알림 데이터 로드 Exception (${noti['id']}): $e');
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
    // 0: Notices, 1: Activity, 2: Follow, 3: Customer Center, 4: All
    switch (tabIndex) {
      case 0: // Notices
        return notifications.where((n) => n['type'] == 'notice').toList();
      case 1: // Activity (Like, Comment)
        return notifications.where((n) => ['like', 'comment', 'comment_like'].contains(n['type'])).toList();
      case 2: // Follow
        return notifications.where((n) => n['type'] == 'follow').toList();
      case 3: // Customer Center (Admin Alert) - Only for Admin
        return notifications.where((n) => n['type'] == 'admin_alert').toList();
      case 4: // All (Exclude Admin Alerts for normal view, or keep separate? User said "Admin alerts should not appear in All")
        // "고객지원, 즉 1대1 문의, 건의사항은 관리자 계정에서 전체에 나오면 안돼고 고객지원에만 나오게끔 해줘."
        return notifications.where((n) => n['type'] != 'admin_alert').toList();
      default:
        return notifications;
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final currentUser = _supabase.auth.currentUser?.id;
      if (currentUser == null) return;
      final l10n = AppLocalizations.of(context)!;

      // Use RPC for performance and reliability
      await _supabase.rpc('mark_all_notifications_as_read', params: {'target_user_id': currentUser});

      /* 
      // Legacy Client-side update (Removed for performance)
      switch (_currentTabIndex) { ... } 
      */

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.markAllReadSuccess))
        );
      }
      
      // Refresh list
      setState(() {});
      
    } catch (e) {
      debugPrint('모두 읽음 처리 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(l10n.notificationsTitle, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black, fontSize: 20, letterSpacing: -0.5)),
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: Text(l10n.markAllRead, style: const TextStyle(color: _brand, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: _bg,
            width: double.infinity,
            padding: const EdgeInsets.only(left: 16), // 정렬 맞춤 (스크린 화면에 맞춰서 여백)
            child: TabBar(
              controller: _tabController,
              labelColor: _brand,
              unselectedLabelColor: Colors.grey,
              indicatorColor: _brand,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              labelPadding: const EdgeInsets.only(right: 24), // 탭 간 간격 조정
              isScrollable: true,
              tabAlignment: TabAlignment.center, // ✅ [Fix] Center alignment
              padding: EdgeInsets.zero,
              tabs: [
                Tab(text: l10n.notices), // 공지사항
                Tab(text: l10n.tabActivity), // 활동
                Tab(text: l10n.tabFollow), // 팔로우
                Tab(text: l10n.customerCenter), // 고객지원 (1:1 문의 등)
                Tab(text: l10n.tabAll), // 전체
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey[100]),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _notificationStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('${l10n.errorOccurred}: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: _brand));
                }

                final allNotifications = snapshot.data ?? [];
                // 1. 공지사항 / 2. 활동 / 3. 팔로우 / 4. 고객지원 / 5. 전체
                final filteredNotifications = _filterNotifications(allNotifications, _currentTabIndex);

                if (filteredNotifications.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(l10n.noNewNotifications, style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  color: _brand,
                  child: ListView.separated(
                    itemCount: filteredNotifications.length,
                    separatorBuilder: (context, index) => Divider(height: 1, thickness: 1, color: Colors.grey[100]),
                    itemBuilder: (context, index) {
                      return NotificationItem(notification: filteredNotifications[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

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
    final l10n = AppLocalizations.of(context)!;
    await _markAsRead(context);

    final supabase = Supabase.instance.client;
    final type = notification['type'];
    final refId = notification['reference_id'];
    
    // ✅ [Fix] Admin Alert Navigation -> AdminDashboard
    if (type == 'admin_alert') {
       Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
       return; 
    }

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
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.deletedComment))
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
    final l10n = AppLocalizations.of(context)!;
    final type = notification['type'] ?? '';
    final isRead = notification['is_read'] ?? false;
    final date = _formatDate(notification['created_at']);

    // ✅ [New] Admin Alert UI
    if (type == 'admin_alert') {
        return InkWell(
        onTap: () => _handleNavigation(context), // Use _handleNavigation fixed above
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
                    child: Text(notification['title'] ?? '관리자 알림', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, height: 1.4, color: Colors.indigo)),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                 padding: const EdgeInsets.only(left: 14.0),
                 child: Text(notification['content'] ?? '', style: const TextStyle(fontSize: 14, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 14.0),
                child: Text(date, style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      );
    }

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
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(notification['title'] ?? l10n.notices, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, height: 1.4)),
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

    if (type == 'comment') {
      final commenter = notification['commenter_nickname'] ?? l10n.unknownUser;
      final storeName = notification['review_store_name'] ?? l10n.review;
      final content = notification['comment_content'] ?? l10n.loadFailed;
      
      final titleText = l10n.commentNotification(commenter, storeName);

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
                  Expanded(child: Text(titleText, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, height: 1.4))),
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

    if (type == 'follow') {
      final follower = notification['follower_nickname'] ?? l10n.unknownUser;
      final titleText = l10n.followNotification(follower);

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
                    child: Text(titleText, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, height: 1.4)),
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

    if (type == 'like' || type == 'comment_like') {
      final liker = notification['liker_nickname'] ?? l10n.unknownUser;
      final storeName = notification['review_store_name'] ?? l10n.review;
      
      final titleText = l10n.likeNotification(storeName, liker);

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
                  Expanded(child: Text(titleText, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, height: 1.4))),
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