import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/models/user_model.dart';
import 'package:needsfine_app/widgets/review_card.dart';
import 'package:needsfine_app/screens/review_detail_screen.dart';

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

  bool _isLoading = true;
  bool _isFollowing = false;

  Map<String, int> _categoryStats = {};
  Map<int, int> _scoreDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

  int _selectedFilterIndex = 0;
  final List<String> _filters = ['최신순', '높은점수', '신뢰도순', '쓴소리'];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final myId = _supabase.auth.currentUser?.id;

    try {
      final profileData = await _supabase.from('profiles').select().eq('id', widget.userId).single();
      final followerCount = await _supabase.from('follows').count(CountOption.exact).eq('following_id', widget.userId);
      final followingCount = await _supabase.from('follows').count(CountOption.exact).eq('follower_id', widget.userId);

      if (myId != null) {
        final followCheck = await _supabase.from('follows').select().eq('follower_id', myId).eq('following_id', widget.userId).maybeSingle();
        _isFollowing = followCheck != null;
      }

      final reviewData = await _supabase.from('reviews')
          .select('*, profiles(*)')
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false);

      // ✅ [Fix] 데이터를 안전하게 Review 객체 리스트로 변환
      final List<Review> reviews = (reviewData as List).map((e) => Review.fromJson(e)).toList();

      _calculateStats(reviews);

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
        await _supabase.from('follows').insert({
          'follower_id': myId,
          'following_id': widget.userId,
        });
      } else {
        await _supabase.from('follows').delete()
            .eq('follower_id', myId)
            .eq('following_id', widget.userId);
      }
    } catch (e) {
      setState(() => _isFollowing = !_isFollowing);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_userProfile == null) return const Scaffold(body: Center(child: Text("유저 정보를 찾을 수 없습니다.")));

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(_userProfile!.nickname, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildProfileHeader()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: _buildTasteIdentityCard(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: _buildScoreDistributionCard(),
            ),
          ),
          const SliverSizedBox(height: 16),
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
                // ✅ [Fix] review 객체를 그대로 전달 (Map 접근 아님)
                return ReviewCard(
                  review: _filteredReviews[index],
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewDetailScreen(review: _filteredReviews[index])));
                  },
                  onTapStore: () {},
                  onTapProfile: () {}, // 내 피드는 클릭 방지
                );
              },
              childCount: _filteredReviews.length,
            ),
          ),
          const SliverSizedBox(height: 40),
        ],
      ),
    );
  }

  // (아래 _buildProfileHeader, _buildTasteIdentityCard 등의 서브 위젯 코드는 이전과 동일하며 그대로 사용)
  Widget _buildProfileHeader() {
    ImageProvider profileImage = _userProfile!.profileImageUrl.isNotEmpty
        ? NetworkImage(_userProfile!.profileImageUrl)
        : const AssetImage('assets/images/default_profile.png') as ImageProvider;

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
          const Text("Taste Identity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          const Text("Score History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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