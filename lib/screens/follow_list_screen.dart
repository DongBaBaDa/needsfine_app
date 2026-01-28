import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/screens/user_profile_screen.dart'; // 상대방 프로필 이동용

class FollowListScreen extends StatefulWidget {
  final String userId;
  final String nickname;
  final int initialTabIndex; // 0: 팔로워, 1: 팔로잉

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.nickname,
    this.initialTabIndex = 0,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;

  // 디자인 토큰
  static const Color _brand = Color(0xFF8A2BE2);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _brand,
          indicatorWeight: 2,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(text: "팔로워"),
            Tab(text: "팔로잉"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _FollowList(userId: widget.userId, type: 'follower'),
          _FollowList(userId: widget.userId, type: 'following'),
        ],
      ),
    );
  }
}

// 리스트 뷰 위젯
class _FollowList extends StatefulWidget {
  final String userId;
  final String type; // 'follower' or 'following'

  const _FollowList({required this.userId, required this.type});

  @override
  State<_FollowList> createState() => _FollowListState();
}

class _FollowListState extends State<_FollowList> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      // follower_id가 나를 팔로우 하는 사람, following_id가 내가 팔로우 하는 사람
      final String targetField = widget.type == 'follower' ? 'follower_id' : 'following_id';
      final String filterField = widget.type == 'follower' ? 'following_id' : 'follower_id';

      // 1. 관계 테이블에서 ID 가져오기
      final response = await _supabase
          .from('follows')
          .select('$targetField, profiles!$targetField(*)') // profiles 테이블 조인
          .eq(filterField, widget.userId);

      final List<Map<String, dynamic>> loadedUsers = [];

      for (var item in response) {
        final profile = item['profiles']; // 조인된 프로필 정보
        if (profile != null) {
          // 내가 이 사람을 팔로우 중인지 확인 (현재 로그인한 유저 기준)
          final myId = _supabase.auth.currentUser?.id;
          bool isFollowing = false;

          if (myId != null) {
            final check = await _supabase
                .from('follows')
            // 🔴 [수정] id 대신 follower_id를 조회 (테이블에 id 컬럼이 없어서 발생한 오류 수정)
                .select('follower_id')
                .eq('follower_id', myId)
                .eq('following_id', profile['id'])
                .maybeSingle();
            isFollowing = check != null;
          }

          loadedUsers.add({
            'id': profile['id'],
            'nickname': profile['nickname'] ?? '알 수 없음',
            'profile_image_url': profile['profile_image_url'],
            'introduction': profile['introduction'] ?? '',
            'isFollowing': isFollowing, // 내 팔로우 상태
          });
        }
      }

      if (mounted) {
        setState(() {
          _users = loadedUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("팔로우 리스트 로드 실패: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF8A2BE2)));
    if (_users.isEmpty) {
      return Center(
        child: Text(
          widget.type == 'follower' ? "아직 팔로워가 없습니다." : "팔로잉하는 유저가 없습니다.",
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: _users.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 70, color: Color(0xFFF5F5F5)),
      itemBuilder: (context, index) {
        final user = _users[index];
        return _buildUserItem(user);
      },
    );
  }

  Widget _buildUserItem(Map<String, dynamic> user) {
    final bool isMe = user['id'] == _supabase.auth.currentUser?.id;

    return InkWell(
      onTap: () {
        // 유저 프로필로 이동
        Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user['id'])));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // 프로필 이미지
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[200],
              backgroundImage: (user['profile_image_url'] != null && user['profile_image_url'].isNotEmpty)
                  ? NetworkImage(user['profile_image_url'])
                  : const AssetImage('assets/images/default_profile.png') as ImageProvider,
            ),
            const SizedBox(width: 14),

            // 닉네임 및 소개
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['nickname'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                  ),
                  if (user['introduction'].isNotEmpty)
                    Text(
                      user['introduction'],
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),

            // 팔로우 버튼 (나 자신이 아니면 표시)
            if (!isMe)
              _FollowButton(
                userId: user['id'],
                nickname: user['nickname'],
                isFollowing: user['isFollowing'],
                onToggle: (newState) {
                  setState(() {
                    user['isFollowing'] = newState;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }
}

// 팔로우 버튼 위젯
class _FollowButton extends StatefulWidget {
  final String userId;
  final String nickname;
  final bool isFollowing;
  final Function(bool) onToggle;

  const _FollowButton({
    required this.userId,
    required this.nickname,
    required this.isFollowing,
    required this.onToggle,
  });

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  final _supabase = Supabase.instance.client;
  static const Color _brand = Color(0xFF8A2BE2);

  Future<void> _toggleFollow() async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    final newState = !widget.isFollowing;
    widget.onToggle(newState); // UI 즉시 업데이트

    try {
      if (newState) {
        // 팔로우 하기
        await _supabase.from('follows').insert({
          'follower_id': myId,
          'following_id': widget.userId,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("${widget.nickname}님을 팔로우합니다."),
            duration: const Duration(seconds: 1),
          ));
        }
      } else {
        // 팔로우 취소
        await _supabase.from('follows').delete()
            .eq('follower_id', myId)
            .eq('following_id', widget.userId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("${widget.nickname}님 팔로우를 취소합니다."),
            duration: const Duration(seconds: 1),
          ));
        }
      }
    } catch (e) {
      // 에러 시 롤백
      widget.onToggle(!newState);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("오류가 발생했습니다.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: widget.isFollowing
          ? OutlinedButton(
        onPressed: _toggleFollow,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey[300]!),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: const Text("팔로잉", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
      )
          : ElevatedButton(
        onPressed: _toggleFollow,
        style: ElevatedButton.styleFrom(
          backgroundColor: _brand,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: const Text("팔로우", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
      ),
    );
  }
}