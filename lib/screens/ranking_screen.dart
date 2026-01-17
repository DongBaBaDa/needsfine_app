import 'package:flutter/material.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/services/review_service.dart';
import 'package:needsfine_app/widgets/star_rating.dart';
import 'package:needsfine_app/screens/write_review_screen.dart';
import 'package:needsfine_app/screens/review_detail_screen.dart'; // 상세 화면 파일 필요 시

// ✅ 전역 트리거 (MainShell에서 감지하여 탭 이동 및 지도 검색 수행)
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
    if(mounted) setState(() => _isLoading = true);
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

    // 순위 재계산
    for(int i=0; i<rankings.length; i++) {
      rankings[i] = StoreRanking(
          storeName: rankings[i].storeName,
          avgScore: rankings[i].avgScore,
          avgUserRating: rankings[i].avgUserRating,
          reviewCount: rankings[i].reviewCount,
          avgTrust: rankings[i].avgTrust,
          rank: i + 1,
          topTags: rankings[i].topTags
      );
    }
    return rankings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          items: (_tabIndex == 0
              ? ['최신순', '니즈파인 점수순', '신뢰도순', '쓴소리']
              : ['니즈파인 순', '사용자 별점 순']
          ).map((String value) {
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
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
      itemBuilder: (context, index) {
        if (index == reviews.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _buildReviewCard(reviews[index]);
      },
    );
  }

  // 리뷰 목록 카드
  Widget _buildReviewCard(Review review) => InkWell(
    onTap: () async {
      final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewDetailScreen(review: review)));
      if (result == true) _loadInitialData();
    },
    child: Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: InkWell(
                // ✅ 클릭 시 내 주변(MainShell index 2)으로 이동하여 검색 수행
                onTap: () {
                  if (review.storeName.isNotEmpty) {
                    searchTrigger.value = review.storeName;
                  }
                },
                child: Text(
                    review.storeName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // ✅ 검은색 변경
                      decoration: TextDecoration.none, // ✅ 밑줄 제거
                    ),
                    overflow: TextOverflow.ellipsis
                ),
              ),
            ),
            StarRating(rating: review.userRating),
          ]),
          const SizedBox(height: 8),

          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF9C7CFF), borderRadius: BorderRadius.circular(12)),
              child: Text('니즈파인 ${review.needsfineScore.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
              child: Text('신뢰도 ${review.trustLevel}%', style: const TextStyle(fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 12),

          Text(review.reviewText, style: const TextStyle(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),

          if (review.photoUrls.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.photoUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(review.photoUrls[index], width: 100, height: 100, fit: BoxFit.cover),
                  );
                },
              ),
            ),
          if (review.photoUrls.isNotEmpty) const SizedBox(height: 12),

          if (review.tags.isNotEmpty)
            Wrap(
              spacing: 6.0,
              children: review.tags.map((tag) => Chip(label: Text(tag, style: const TextStyle(fontSize: 11)), backgroundColor: const Color(0xFFF0E9FF), visualDensity: VisualDensity.compact)).toList(),
            ),
        ],
      ),
    ),
  );

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

  // 매장 순위 카드
  Widget _buildRankingCard(StoreRanking ranking) {
    // ✅ 1~3위만 원형 배경, 4위부터는 숫자만
    final bool isTopRank = ranking.rank <= 3;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(children: [
        // 순위 표시 (수정됨)
        Container(
          width: 40,
          height: 40,
          decoration: isTopRank
              ? const BoxDecoration(color: Color(0xFF9C7CFF), shape: BoxShape.circle)
              : null, // ✅ 4위부터 배경 없음
          child: Center(
            child: Text(
                '${ranking.rank}',
                style: TextStyle(
                    color: isTopRank ? Colors.white : Colors.black, // ✅ 4위부터 글자 검정
                    fontWeight: FontWeight.bold,
                    fontSize: 18
                )
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            InkWell(
              // ✅ 클릭 시 내 주변(MainShell index 2)으로 이동하여 검색 수행
              onTap: () => searchTrigger.value = ranking.storeName,
              child: Text(
                  ranking.storeName,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black, // ✅ 검은색 변경
                      decoration: TextDecoration.none // ✅ 밑줄 제거
                  )
              ),
            ),
            const SizedBox(height: 4),
            Row(children: [
              Text(
                  _rankingSortOption == '니즈파인 순'
                      ? '평균 ${ranking.avgScore.toStringAsFixed(1)}점'
                      : '별점 ${ranking.avgUserRating.toStringAsFixed(1)}점',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF9C7CFF), fontWeight: FontWeight.bold)
              ),
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