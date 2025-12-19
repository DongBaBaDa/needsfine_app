import 'package:flutter/material.dart';

class FollowListScreen extends StatefulWidget {
  const FollowListScreen({super.key});

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 더미 데이터
  final List<Map<String, String>> _followers = []; // 비어있음
  final List<Map<String, String>> _following = [
    {"name": "쩝쩝쓰", "description": "스시 좋아하는 쩝쩝이"},
    {"name": "싹싹이", "description": "비우는게 취미"},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('발랄한 맛사냥꾼_53515'),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.person_add_alt_1_outlined))],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '팔로워'), Tab(text: '팔로잉')],
          indicatorColor: Colors.black,
          labelColor: Colors.black,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFollowerList(),
          _buildFollowingList(),
        ],
      ),
    );
  }

  Widget _buildFollowerList() {
    if (_followers.isEmpty) {
      return _buildEmptyList(
        icon: Icons.person_off_outlined,
        message: '아직 나를 팔로우하는 사람이 없어요',
        buttonText: '연락처 연동하고 친구 찾기',
        onPressed: () {},
      );
    }
    return _buildUserList(_followers, isFollowing: false);
  }

  Widget _buildFollowingList() {
    if (_following.isEmpty) {
      return _buildEmptyList(
        icon: Icons.person_search_outlined,
        message: '아직 팔로우하는 사람이 없어요',
        buttonText: '추천 친구 보러가기',
        onPressed: () {},
      );
    }
    return _buildUserList(_following, isFollowing: true);
  }

  Widget _buildEmptyList({required IconData icon, required String message, required String buttonText, required VoidCallback onPressed}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 24),
          OutlinedButton(onPressed: onPressed, child: Text(buttonText)),
        ],
      ),
    );
  }

  Widget _buildUserList(List<Map<String, String>> users, {required bool isFollowing}) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          leading: const CircleAvatar(backgroundImage: NetworkImage('https://via.placeholder.com/150')),
          title: Text(user['name']!),
          subtitle: Text(user['description']!),
          trailing: isFollowing
            ? ElevatedButton(onPressed: () {}, child: const Text('팔로잉'), style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200]))
            : ElevatedButton(onPressed: () {}, child: const Text('팔로우'), style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white)),
        );
      },
    );
  }
}
