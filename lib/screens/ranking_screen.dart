import 'package:flutter/material.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/services/review_service.dart';
import 'package:needsfine_app/screens/write_review_screen.dart';
import 'package:needsfine_app/screens/review_detail_screen.dart';
import 'dart:math';

// ✅ 전역 트리거
final ValueNotifier<String?> searchTrigger = ValueNotifier<String?>(null);

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});
  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  List<Review> _reviews = [];
  List<StoreRanking> _storeRankings = [];
  Stats? _stats;

  bool _isLoading = true;
  bool _isMoreLoading = false;
  bool _hasMore = true;

  String _reviewSortOption = '최신순';
  String _rankingSortOption = '니즈파인 순';

  int _tabIndex = 0;

  final ScrollController _scrollController = ScrollController();
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9 &&
          !_isMoreLoading &&
          _hasMore &&
          _tabIndex == 0) {
        _loadMoreReviews();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final statsFuture = ReviewService.fetchGlobalStats();
      final reviewsFuture = ReviewService.fetchReviews(limit: _limit, offset: 0);
      final rankingsFuture = ReviewService.fetchStoreRankings();

      final results = await Future.wait([statsFuture, reviewsFuture, rankingsFuture]);

      final statsData = results[0] as Map<String, dynamic>;
      final reviews = results[1] as List<Review>;
      final rankings = results[2] as List<StoreRanking>;

      if (mounted) {
        setState(() {
          if (statsData.isNotEmpty) {
            _stats = Stats(
              total: (statsData['total_reviews'] as num?)?.toInt() ?? reviews.length,
              average: (statsData['average_score'] as num?)?.toDouble() ?? 0.0,
              avgTrust: (statsData['avg_trust'] as num?)?.toDouble() ?? 0.0,
            );
          } else {
            _stats = Stats(total: reviews.length, average: 0, avgTrust: 0);
          }
          _reviews = reviews;
          _storeRankings = rankings;
          _hasMore = reviews.length >= _limit;
        });
      }
    } catch (e) {
      print('❌ 데이터 로드 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreReviews() async {
    if (_isMoreLoading) return;
    setState(() => _isMoreLoading = true);

    try {
      final currentCount = _reviews.length;
      final moreReviews = await ReviewService.fetchReviews(limit: _limit, offset: currentCount);

      if (mounted) {
        setState(() {
          for (var newReview in moreReviews) {
            if (!_reviews.any((existing) => existing.id == newReview.id)) {
              _reviews.add(newReview);
            }
          }
          _hasMore = moreReviews.length >= _limit;
        });
      }
    } catch (e) {
      print('❌ 추가 데이터 로드 실패: $e');
    } finally {
      if (mounted) setState(() => _isMoreLoading = false);
    }
  }

  List<Review> _getSortedReviews() {
    List<Review> reviews = List.from(_reviews);
    switch (_reviewSortOption) {
      case '니즈파인 점수순':
        reviews.sort((a, b) => b.needsfineScore.compareTo(a.needsfineScore));
        break;
      case '신뢰도순':
        reviews.sort((a, b) => b.trustLevel.compareTo(a.trustLevel));
        break;
      case '쓴소리':
        reviews = reviews.where((r) => r.isCritical).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case '최신순':
      default:
        reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return reviews;
  }

  List<StoreRanking> _getSortedRankings() {
    List<StoreRanking> rankings = List.from(_storeRankings);

    if (_rankingSortOption == '사용자 별점 순') {
      rankings.sort((a, b) => b.avgUserRating.compareTo(a.avgUserRating));
    } else {
      rankings.sort((a, b) => b.avgScore.compareTo(a.avgScore));
    }

    for (int i = 0; i < rankings.length; i++) {
      rankings[i] = StoreRanking(
          storeName: rankings[i].storeName,
          avgScore: rankings[i].avgScore,
          avgUserRating: rankings[i].avgUserRating,
          reviewCount: rankings[i].reviewCount,
          avgTrust: rankings[i].avgTrust,
          rank: i + 1,
          topTags: rankings[i].topTags);
    }
    return rankings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9), // Warm White Background
      appBar: AppBar(
        title: const Text('리뷰 랭킹', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF9C7CFF),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadInitialData)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9C7CFF))))
          : Column(
        children: [
          if (_stats != null) _buildStatsHeader(),
          _buildSortControls(),
          const Divider(height: 1),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Builder(builder: (context) {
                final tabController = DefaultTabController.of(context);
                tabController.addListener(() {
                  if (!tabController.indexIsChanging) {
                    setState(() => _tabIndex = tabController.index);
                  }
                });
                return Column(
                  children: [
                    const TabBar(
                      labelColor: Color(0xFF9C7CFF),
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Color(0xFF9C7CFF),
                      tabs: [Tab(text: '리뷰 목록'), Tab(text: '매장 순위')],
                    ),
                    Expanded(
                      child: TabBarView(children: [_buildReviewList(), _buildStoreRankingList()]),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const WriteReviewScreen()));
          if (result == true) _loadInitialData();
        },
        backgroundColor: const Color(0xFF9C7CFF),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildStatsHeader() => Container(
    padding: const EdgeInsets.all(16.0),
    color: const Color(0xFFF0E9FF),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('총 리뷰', '${_stats!.total}개'),
        _buildStatItem('평균 니즈파인 점수', _stats!.average == 0 ? '-' : _stats!.average.toStringAsFixed(1)),
        _buildStatItem('평균 신뢰도', _stats!.avgTrust == 0 ? '-' : '${_stats!.avgTrust.toStringAsFixed(0)}%'),
      ],
    ),
  );

  Widget _buildStatItem(String label, String value) => Column(
    children: [
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF9C7CFF))),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    ],
  );

  Widget _buildSortControls() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        DropdownButton<String>(
          value: _tabIndex == 0 ? _reviewSortOption : _rankingSortOption,
          underline: const SizedBox(),
          items: (_tabIndex == 0 ? ['최신순', '니즈파인 점수순', '신뢰도순', '쓴소리'] : ['니즈파인 순', '사용자 별점 순']).map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 14)));
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              if (_tabIndex == 0) {
                _reviewSortOption = newValue!;
              } else {
                _rankingSortOption = newValue!;
              }
            });
          },
        ),
      ],
    ),
  );

  Widget _buildReviewList() {
    final reviews = _getSortedReviews();
    if (reviews.isEmpty && !_isLoading) {
      return const Center(child: Text('조건에 맞는 리뷰가 없습니다.'));
    }

    return ListView.separated(
      controller: _scrollController,
      itemCount: reviews.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, __) => Container(height: 1, color: const Color(0xFFEEEEEE)),
      itemBuilder: (context, index) {
        if (index == reviews.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return ReviewCard(
          review: reviews[index],
          onTap: () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewDetailScreen(review: reviews[index])));
            if (result == true) _loadInitialData();
          },
          onTapStore: () {
            if (reviews[index].storeName.isNotEmpty) {
              searchTrigger.value = reviews[index].storeName;
            }
          },
        );
      },
    );
  }

  Widget _buildStoreRankingList() {
    final rankings = _getSortedRankings();
    return rankings.isEmpty
        ? const Center(child: Text('매장 데이터가 없습니다.'))
        : ListView.separated(
      itemCount: rankings.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) => _buildRankingCard(rankings[index]),
    );
  }

  Widget _buildRankingCard(StoreRanking ranking) {
    final bool isTopRank = ranking.rank <= 3;
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: isTopRank ? const BoxDecoration(color: Color(0xFF9C7CFF), shape: BoxShape.circle) : null,
          child: Center(
            child: Text('${ranking.rank}',
                style: TextStyle(
                    color: isTopRank ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            InkWell(
              onTap: () => searchTrigger.value = ranking.storeName,
              child: Text(ranking.storeName,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      decoration: TextDecoration.none
                  )),
            ),
            const SizedBox(height: 4),
            Row(children: [
              Text(_rankingSortOption == '니즈파인 순' ? '평균 ${ranking.avgScore.toStringAsFixed(1)}점' : '별점 ${ranking.avgUserRating.toStringAsFixed(1)}점',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF9C7CFF), fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text('신뢰도 ${ranking.avgTrust.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 8),
              Text('리뷰 ${ranking.reviewCount}개', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

// ==========================================
// REVIEW CARD (닉네임 표시 적용됨)
// ==========================================
class ReviewCard extends StatefulWidget {
  final Review review;
  final VoidCallback onTap;
  final VoidCallback onTapStore;

  const ReviewCard({
    super.key,
    required this.review,
    required this.onTap,
    required this.onTapStore,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isCommentExpanded = false;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.review.likeCount;
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
  }

  void _toggleComment() {
    setState(() {
      _isCommentExpanded = !_isCommentExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color kPrimary = Color(0xFFC87CFF);

    return InkWell(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
        color: const Color(0xFFFFFDF9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Store Name Header
            InkWell(
              onTap: widget.onTapStore,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.review.storeName,
                    style: const TextStyle(
                      fontFamily: 'NotoSansKR',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
                ],
              ),
            ),
            if (widget.review.storeAddress != null)
              Padding(
                padding: const EdgeInsets.only(top: 2.0, bottom: 12.0),
                child: Text(
                  widget.review.storeAddress!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              )
            else
              const SizedBox(height: 12),

            // 2. User Info & Scores (닉네임 표시됨 ✅)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.person, color: Colors.grey, size: 22),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nickname
                    Text(
                      widget.review.nickname,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    // NeedsFine Score & Trust Badge
                    Row(
                      children: [
                        _buildSmallBadge(
                          "니즈파인 ${widget.review.needsfineScore.toStringAsFixed(1)}",
                          kPrimary,
                          true,
                        ),
                        const SizedBox(width: 6),
                        _buildSmallBadge(
                          "신뢰도 ${widget.review.trustLevel}%",
                          Colors.grey[600]!,
                          false,
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                // User Rating (Stars) - Moved to right
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < widget.review.userRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: const Color(0xFFFFB800),
                      size: 18,
                    );
                  }),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 3. Content
            Text(
              widget.review.reviewText,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'NotoSansKR',
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
            ),

            if (widget.review.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.review.tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "#$tag",
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  )).toList(),
                ),
              ),

            const SizedBox(height: 16),

            // 4. Photos
            if (widget.review.photoUrls.isNotEmpty)
              Container(
                height: 150,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.review.photoUrls.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.review.photoUrls[index],
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(width: 150, color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                      ),
                    );
                  },
                ),
              ),

            const Divider(height: 24, thickness: 0.5, color: Color(0xFFEEEEEE)),

            // 5. Footer (Updated)
            Row(
              children: [
                // Helpful Button
                InkWell(
                  onTap: _toggleLike,
                  child: Row(
                    children: [
                      Icon(
                        _isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                        size: 18,
                        color: _isLiked ? kPrimary.withOpacity(0.7) : Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "도움이 돼요 $_likeCount",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _isLiked ? FontWeight.bold : FontWeight.normal,
                          color: _isLiked ? kPrimary.withOpacity(0.7) : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Comment Button
                InkWell(
                  onTap: _toggleComment,
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        "댓글",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Date/Time (Moved to bottom right)
                Text(
                  '${widget.review.createdAt.year}.${widget.review.createdAt.month}.${widget.review.createdAt.day} '
                      '${widget.review.createdAt.hour.toString().padLeft(2, '0')}:${widget.review.createdAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                ),
              ],
            ),

            // 6. Comment Section (Expandable)
            if (_isCommentExpanded)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("댓글 목록 (준비중)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      // Dummy comments for visualization
                      _buildDummyComment("사용자123", "좋은 정보 감사합니다!"),
                      const SizedBox(height: 8),
                      _buildDummyComment("맛집탐방러", "여기 웨이팅 길었나요?"),
                      const SizedBox(height: 12),
                      // Input Placeholder
                      Container(
                        height: 40,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[300]!)),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text("댓글을 입력하세요...", style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallBadge(String text, Color color, bool isPrimary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isPrimary ? color : Colors.transparent,
        border: Border.all(color: color, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isPrimary ? Colors.white : color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDummyComment(String user, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(radius: 10, backgroundColor: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87)),
            ],
          ),
        )
      ],
    );
  }

  int min(int a, int b) => a < b ? a : b;
}