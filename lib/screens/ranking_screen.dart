import 'package:flutter/material.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/services/review_service.dart';
import 'package:needsfine_app/screens/write_review_screen.dart';
import 'package:needsfine_app/screens/review_detail_screen.dart';

// ✅ 분리된 위젯 임포트
import 'package:needsfine_app/widgets/review_card.dart';
import 'package:needsfine_app/widgets/store_ranking_card.dart';

// ✅ 전역 트리거 임포트
import 'package:needsfine_app/core/search_trigger.dart';

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
      backgroundColor: const Color(0xFFFFFDF9),
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

  // ✅ [수정] 구분선 로직이 반영된 매장 리스트 빌더
  Widget _buildStoreRankingList() {
    final rankings = _getSortedRankings();
    final double overallAverage = _stats?.average ?? 0.0;

    return rankings.isEmpty
        ? const Center(child: Text('매장 데이터가 없습니다.'))
        : ListView.builder(
      itemCount: rankings.length,
      itemBuilder: (context, index) {
        final ranking = rankings[index];

        // 현재 매장 점수
        final double currentScore = _rankingSortOption == '니즈파인 순'
            ? ranking.avgScore
            : ranking.avgUserRating;

        // 현재가 평균 이상인지
        final bool isAboveAverage = currentScore >= overallAverage;

        // 다음 매장 점수 (없으면 null)
        final nextRanking = (index + 1 < rankings.length)
            ? rankings[index + 1]
            : null;

        final double? nextScore = nextRanking != null
            ? (_rankingSortOption == '니즈파인 순' ? nextRanking.avgScore : nextRanking.avgUserRating)
            : null;

        // 다음 매장이 평균 미만인지 확인
        final bool isNextBelowAverage = nextScore != null && nextScore < overallAverage;

        // ✅ 구분선 표시 조건: (현재 >= 평균) && (다음 < 평균)
        final bool showDivider = isAboveAverage && isNextBelowAverage;

        return Column(
          children: [
            StoreRankingCard(
              ranking: ranking,
              sortOption: _rankingSortOption,
            ),

            if (showDivider) _buildAverageDivider(overallAverage),

            // 카드 사이의 기본 구분선 (마지막 아이템 제외)
            if (!showDivider && index < rankings.length - 1)
              const Divider(height: 1),
          ],
        );
      },
    );
  }

  // ✅ 평균 점수 구분선 위젯
  Widget _buildAverageDivider(double average) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. 니즈파인색 점선
          CustomPaint(
            size: const Size(double.infinity, 1),
            painter: _DashedLinePainter(),
          ),

          // 2. 중앙 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF9C7CFF),
                width: 1.5,
              ),
            ),
            child: Text(
              '니즈파인 평균 점수 ${average.toStringAsFixed(1)}점',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ 점선 그리기용 Painter
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9C7CFF)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}