import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/models/user_model.dart';
import 'package:needsfine_app/widgets/review_card.dart';
import 'package:needsfine_app/screens/review_detail_screen.dart';

// ✅ 리스트 상세 이동
import 'package:needsfine_app/screens/my_list_detail_screen.dart';
// ✅ 유저 리스트 목록 화면 임포트
import 'package:needsfine_app/screens/user_lists_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;

  UserProfile? _userProfile;
  List<Review> _allReviews = [];
  List<Review> _filteredReviews = [];

  // ✅ 유저의 리스트 데이터 저장
  List<Map<String, dynamic>> _userLists = [];

  bool _isLoading = true;
  bool _isFollowing = false;

  // ✅ 차단 상태 변수
  bool _iBlockedThem = false; // 내가 이 사람을 차단했나?
  bool _theyBlockedMe = false; // 이 사람이 나를 차단했나?

  Map<String, int> _categoryStats = {};
  Map<int, int> _scoreDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

  int _selectedFilterIndex = 0;
  final List<String> _filters = ['최신순', '높은점수', '신뢰도순', '쓴소리'];

  @override
  void initState() {
    super.initState();
    _checkBlockStatusAndFetchData();
  }

  // ✅ 차단 관계를 가장 먼저 확인하고 데이터를 로드하는 함수
  Future<void> _checkBlockStatusAndFetchData() async {
    setState(() => _isLoading = true);
    final myId = _supabase.auth.currentUser?.id;

    // 1. 차단 관계 확인 (비로그인 상태면 패스)
    if (myId != null && myId != widget.userId) {
      try {
        // A. 내가 상대를 차단했는지 확인
        final myBlock = await _supabase
            .from('blocks')
            .select()
            .eq('blocker_id', myId)
            .eq('blocked_id', widget.userId)
            .maybeSingle();

        // B. 상대가 나를 차단했는지 확인
        final theirBlock = await _supabase
            .from('blocks')
            .select()
            .eq('blocker_id', widget.userId)
            .eq('blocked_id', myId)
            .maybeSingle();

        if (mounted) {
          setState(() {
            _iBlockedThem = myBlock != null;
            _theyBlockedMe = theirBlock != null;
          });
        }

        // 차단 관계가 있다면 더 이상 데이터를 로드하지 않음
        if (_iBlockedThem || _theyBlockedMe) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
      } catch (e) {
        debugPrint("차단 확인 실패: $e");
      }
    }

    // 2. 차단 관계가 없을 때만 데이터 로드
    await _fetchUserData(myId);
  }

  Future<void> _fetchUserData(String? myId) async {
    try {
      // 1. 프로필 정보
      final profileData = await _supabase.from('profiles').select().eq('id', widget.userId).single();
      final followerCount = await _supabase.from('follows').count(CountOption.exact).eq('following_id', widget.userId);
      final followingCount = await _supabase.from('follows').count(CountOption.exact).eq('follower_id', widget.userId);

      // 2. 팔로우 상태
      if (myId != null) {
        final followCheck = await _supabase.from('follows').select().eq('follower_id', myId).eq('following_id', widget.userId).maybeSingle();
        _isFollowing = followCheck != null;
      }

      // 3. 리뷰 데이터
      final reviewData = await _supabase.from('reviews')
          .select('*, profiles(*)')
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false);

      final List<Review> reviews = (reviewData as List).map((e) => Review.fromJson(e)).toList();
      _calculateStats(reviews);

      // 4. 유저의 공개 리스트만 불러오기 (최근 3개만 미리보기)
      final listsData = await _supabase
          .from('user_lists')
          .select()
          .eq('user_id', widget.userId)
          .eq('is_public', true) // ✅ 공개 리스트만 표시
          .order('created_at', ascending: false)
          .limit(3);

      if (mounted) {
        setState(() {
          _userProfile = UserProfile(
            nickname: profileData['nickname'] ?? 'Unknown',
            introduction: profileData['introduction'] ?? '',
            activityZone: profileData['activity_zone'] ?? '',
            profileImageUrl: profileData['profile_image_url'] ?? '',
            reliability: 0,
            followerCount: followerCount,
            followingCount: followingCount,
            tasteTags: List<String>.from(profileData['taste_tags'] ?? []),
          );
          _allReviews = reviews;
          _userLists = List<Map<String, dynamic>>.from(listsData);
          _applyFilter(0);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("유저 프로필 로드 실패: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _calculateStats(List<Review> reviews) {
    _categoryStats.clear();
    _scoreDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var review in reviews) {
      if (review.tags.isNotEmpty) {
        final cat = review.tags.first;
        _categoryStats[cat] = (_categoryStats[cat] ?? 0) + 1;
      }
      int score = review.userRating.round().clamp(1, 5);
      _scoreDistribution[score] = (_scoreDistribution[score] ?? 0) + 1;
    }
  }

  void _applyFilter(int index) {
    setState(() {
      _selectedFilterIndex = index;
      switch (index) {
        case 0:
          _filteredReviews = List.from(_allReviews)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 1:
          _filteredReviews = List.from(_allReviews)..sort((a, b) => b.userRating.compareTo(a.userRating));
          break;
        case 2:
          _filteredReviews = List.from(_allReviews)..sort((a, b) => b.trustLevel.compareTo(a.trustLevel));
          break;
        case 3:
          _filteredReviews = _allReviews.where((r) => r.userRating < 3.0).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
      }
    });
  }

  Future<void> _toggleFollow() async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    setState(() => _isFollowing = !_isFollowing);

    try {
      if (_isFollowing) {
        // 팔로우 생성
        await _supabase.from('follows').insert({
          'follower_id': myId,
          'following_id': widget.userId,
        });

        // 팔로우 알림 생성
        await _supabase.from('notifications').insert({
          'receiver_id': widget.userId,
          'type': 'follow',
          'reference_id': myId,
        });
      } else {
        // 언팔로우
        await _supabase.from('follows').delete()
            .eq('follower_id', myId)
            .eq('following_id', widget.userId);
      }
    } catch (e) {
      setState(() => _isFollowing = !_isFollowing);
    }
  }

  // ✅ 차단하기 기능
  Future<void> _blockUser() async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("차단하기"),
        content: Text("${_userProfile?.nickname ?? '이 사용자'}를 차단하시겠습니까?\n차단하면 서로의 게시물을 볼 수 없습니다."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("취소")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("차단", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.from('blocks').insert({
        'blocker_id': myId,
        'blocked_id': widget.userId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("사용자를 차단했습니다.")));
        // 차단 후 즉시 화면 갱신 (차단 화면으로 전환)
        _checkBlockStatusAndFetchData();
      }
    } catch (e) {
      debugPrint("차단 실패: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("차단 처리 중 오류가 발생했습니다.")));
      }
    }
  }

  // ✅ 차단 해제 기능
  Future<void> _unblockUser() async {
    final myId = _supabase.auth.currentUser?.id;
    if (myId == null) return;

    try {
      await _supabase.from('blocks').delete()
          .eq('blocker_id', myId)
          .eq('blocked_id', widget.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("차단이 해제되었습니다.")));
        // 해제 후 데이터 다시 로드
        _checkBlockStatusAndFetchData();
      }
    } catch (e) {
      debugPrint("차단 해제 실패: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // ✅ 1. 내가 차단한 경우
    if (_iBlockedThem) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text("차단한 사용자입니다.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("차단을 해제해야 프로필을 볼 수 있습니다.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _unblockUser,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                child: const Text("차단 해제", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      );
    }

    // ✅ 2. 상대방이 나를 차단한 경우
    if (_theyBlockedMe) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_rounded, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text("차단 당한 사용자입니다.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("이 사용자의 프로필을 볼 수 없습니다.", style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // ✅ 3. 정상 프로필 화면 (기존 로직)
    if (_userProfile == null) return const Scaffold(body: Center(child: Text("유저 정보를 찾을 수 없습니다.")));

    final myId = _supabase.auth.currentUser?.id;
    final isMe = myId == widget.userId;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(_userProfile!.nickname, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (!isMe)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'block') _blockUser();
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'block',
                  child: Text('차단하기', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildProfileHeader()),

          // 1. Taste Identity
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: _buildTasteIdentityCard(),
            ),
          ),

          // 2. Score History
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: _buildScoreDistributionCard(),
            ),
          ),

          // 3. User Lists 카드
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: _buildUserListsCard(),
            ),
          ),

          const SliverSizedBox(height: 16),

          // 4. Filters & Reviews
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyFilterDelegate(
              filters: _filters,
              selectedIndex: _selectedFilterIndex,
              onTap: _applyFilter,
            ),
          ),
          _filteredReviews.isEmpty
              ? SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Center(child: Text("작성한 리뷰가 없습니다.", style: TextStyle(color: Colors.grey[500]))),
            ),
          )
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                return ReviewCard(
                  review: _filteredReviews[index],
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewDetailScreen(review: _filteredReviews[index])));
                  },
                  onTapStore: () {},
                  onTapProfile: () {},
                );
              },
              childCount: _filteredReviews.length,
            ),
          ),
          const SliverSizedBox(height: 100),
        ],
      ),
    );
  }

  // User Lists 카드 위젯
  Widget _buildUserListsCard() {
    return GestureDetector(
      onTap: () {
        // 전체 보기 화면(UserListsScreen)으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserListsScreen(
              userId: widget.userId,
              nickname: _userProfile!.nickname,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("유저 리스트", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 16),
            if (_userLists.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: Text(
                    "생성된 리스트가 없습니다.",
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ),
              )
            else
              Column(
                children: _userLists.map((list) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyListDetailScreen(
                            listId: list['id'].toString(),
                            listName: list['name'] ?? '이름 없음',
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.list_alt_rounded, size: 18, color: Color(0xFF8A2BE2)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              list['name'] ?? '이름 없음',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    ImageProvider? profileImage;
    if (_userProfile!.profileImageUrl.isNotEmpty) {
      profileImage = NetworkImage(_userProfile!.profileImageUrl);
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!, width: 1.0),
                ),
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: profileImage,
                  backgroundColor: Colors.grey[200],
                  child: profileImage == null ? const Icon(Icons.person, size: 32, color: Colors.grey) : null,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem("리뷰", "${_allReviews.length}"),
                        _buildStatItem("팔로워", "${_userProfile!.followerCount}"),
                        _buildStatItem("팔로잉", "${_userProfile!.followingCount}"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.userId != _supabase.auth.currentUser?.id)
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: _toggleFollow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFollowing ? Colors.grey[200] : const Color(0xFF8A2BE2),
                            foregroundColor: _isFollowing ? Colors.black : Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(_isFollowing ? "팔로잉" : "팔로우", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_userProfile!.nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text(_userProfile!.introduction.isNotEmpty ? _userProfile!.introduction : "소개글이 없습니다.",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String count) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildTasteIdentityCard() {
    String topCategory = "정보 없음";
    int maxCount = 0;
    _categoryStats.forEach((key, value) {
      if (value > maxCount) {
        maxCount = value;
        topCategory = key;
      }
    });
    double percentage = _allReviews.isNotEmpty ? (maxCount / _allReviews.length * 100) : 0;

    List<PieChartSectionData> sections = [];
    int colorIdx = 0;
    List<Color> colors = [
      const Color(0xFF8A2BE2),
      const Color(0xFFC87CFF),
      const Color(0xFFE0B0FF),
      const Color(0xFFDCD0FF),
      Colors.grey[300]!,
    ];

    _categoryStats.forEach((key, value) {
      if (sections.length < 4) {
        sections.add(PieChartSectionData(
          color: colors[colorIdx % colors.length],
          value: value.toDouble(),
          title: "",
          radius: 12,
        ));
        colorIdx++;
      }
    });
    if (sections.isEmpty) {
      sections.add(PieChartSectionData(color: Colors.grey[200], value: 1, title: "", radius: 12));
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("취향 분석", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sections: sections,
                        centerSpaceRadius: 35,
                        sectionsSpace: 2,
                        startDegreeOffset: -90,
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(topCategory, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          Text("${percentage.toStringAsFixed(0)}%", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _userProfile!.tasteTags.take(5).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "#$tag",
                      style: const TextStyle(color: Color(0xFF4A148C), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDistributionCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("평점 분포", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                barGroups: List.generate(5, (index) {
                  int score = index + 1;
                  int count = _scoreDistribution[score] ?? 0;

                  Color barColor;
                  if (score >= 4) {
                    barColor = const Color(0xFF8A2BE2);
                  } else if (score == 3) {
                    barColor = Colors.blue[300]!;
                  } else {
                    barColor = Colors.grey[300]!;
                  }

                  return BarChartGroupData(
                    x: score,
                    barRods: [
                      BarChartRodData(
                        toY: count.toDouble(),
                        color: barColor,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: (_allReviews.length).toDouble() == 0 ? 1 : (_allReviews.length / 2),
                          color: Colors.grey[50],
                        ),
                      ),
                    ],
                  );
                }),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            value.toInt().toString(),
                            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final List<String> filters;
  final int selectedIndex;
  final Function(int) onTap;

  _StickyFilterDelegate({
    required this.filters,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF2F2F7),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final isSelected = selectedIndex == index;
            final isBitter = filters[index] == '쓴소리';

            return GestureDetector(
              onTap: () => onTap(index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isBitter ? Colors.black87 : const Color(0xFF8A2BE2))
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected ? null : Border.all(color: Colors.grey[300]!),
                  boxShadow: isSelected ? [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                  ] : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  filters[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  double get maxExtent => 64.0;

  @override
  double get minExtent => 64.0;

  @override
  bool shouldRebuild(covariant _StickyFilterDelegate oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex;
  }
}

class SliverSizedBox extends StatelessWidget {
  final double height;
  const SliverSizedBox({super.key, required this.height});
  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(child: SizedBox(height: height));
  }
}