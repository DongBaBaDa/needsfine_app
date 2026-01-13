import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/needsfine_theme.dart';

class FollowListScreen extends StatefulWidget {
  final String userId; // 대상 유저 ID
  final String nickname; // 상단 타이틀용
  final int initialTabIndex; // 0: 팔로워, 1: 팔로잉

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.nickname,
    required this.initialTabIndex,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
  }

  // 팔로우 데이터를 Supabase에서 가져오는 함수
  Future<List<dynamic>> _fetchFollowData(bool isFollowerTab) async {
    final targetIdField = isFollowerTab ? 'following_id' : 'follower_id';
    final profileIdField = isFollowerTab ? 'follower_id' : 'following_id';

    try {
      final response = await _supabase
          .from('follows')
          .select('profiles!$profileIdField(*)')
          .eq(targetIdField, widget.userId);

      return response as List<dynamic>;
    } catch (e) {
      debugPrint("팔로우 리스트 로드 에러: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.nickname),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: kNeedsFinePurple,
          labelColor: kNeedsFinePurple,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "팔로워"),
            Tab(text: "팔로잉"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFollowList(true), // 팔로워 탭
          _buildFollowList(false), // 팔로잉 탭
        ],
      ),
    );
  }

  Widget _buildFollowList(bool isFollowerTab) {
    return FutureBuilder<List<dynamic>>(
      future: _fetchFollowData(isFollowerTab),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(isFollowerTab ? "팔로워가 없습니다." : "팔로잉 중인 유저가 없습니다."));
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final profile = snapshot.data![index]['profiles'];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: kNeedsFinePurpleLight,
                backgroundImage: (profile['profile_image_url'] != null && profile['profile_image_url'].isNotEmpty)
                    ? NetworkImage(profile['profile_image_url'])
                    : const AssetImage('assets/images/default_profile.png') as ImageProvider,
              ),
              title: Text(profile['nickname'] ?? "이름 없음", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(profile['introduction'] ?? "소개글이 없습니다.", maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: OutlinedButton(
                onPressed: () {}, // 추후 해당 유저 피드로 이동 로직 추가 가능
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEEEEEE)),
                ),
                child: const Text("보기", style: TextStyle(color: Colors.black, fontSize: 12)),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}