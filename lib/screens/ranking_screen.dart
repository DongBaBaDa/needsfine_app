// lib/screens/ranking_screen.dart
import 'package:flutter/material.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/services/review_service.dart';
import 'package:needsfine_app/screens/write_review_screen.dart';
import 'package:needsfine_app/screens/review_detail_screen.dart';
import 'package:needsfine_app/screens/user_profile_screen.dart';

// ✅ 분리된 위젯 임포트
import 'package:needsfine_app/widgets/review_card.dart';
import 'package:needsfine_app/widgets/store_ranking_card.dart';

// ✅ 전역 트리거 임포트
import 'package:needsfine_app/core/search_trigger.dart';

// ✅ 다국어 패키지 임포트
import 'package:needsfine_app/l10n/app_localizations.dart';
import 'package:needsfine_app/widgets/draggable_fab.dart';

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

  // 내부 로직용 변수
  String _reviewSortOption = '최신순';
  String _rankingSortOption = '니즈파인 순';

  int _tabIndex = 0;

  final ScrollController _scrollController = ScrollController();
  final int _limit = 20;

  // ✅ 팝업 위치를 잡기 위한 링크
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

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
    _removeOverlay(); // 화면 종료 시 팝업 닫기
    _scrollController.dispose();
    super.dispose();
  }

  // ✅ 팝업 닫기 함수
  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // ✅ 도움말 팝업 표시 함수
  void _showInfoPopup() {
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    // 언어별 위치 조정
    final currentLang = Localizations.localeOf(context).languageCode;
    final double xOffset = (currentLang == 'my') ? -150.0 : -60.0;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // 1. 배경을 터치하면 팝업 닫기
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeOverlay,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.transparent),
              ),
            ),
            // 2. 실제 말풍선 팝업
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(xOffset, 30),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoTitle(l10n.whatIsScore),
                      const SizedBox(height: 4),
                      Text(
                        l10n.scoreDesc,
                        style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      _buildScoreTier("4.5 ~ ", l10n.waitingSpot),
                      _buildScoreTier("4.0 ~ ", l10n.localSpot),
                      _buildScoreTier("3.5 ~ ", l10n.goodSpot),
                      _buildScoreTier("3.0 ~ ", l10n.polarizingSpot),
                      const Divider(height: 24),
                      _buildInfoTitle(l10n.whatIsReliability),
                      const SizedBox(height: 4),
                      Text(
                        l10n.reliabilityDesc,
                        style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildInfoTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF9C7CFF),
      ),
    );
  }

  Widget _buildScoreTier(String score, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text("• $score : ", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          Expanded(child: Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey))),
        ],
      ),
    );
  }

  Future<void> _loadInitialData({bool isRefresh = false}) async {
    if (!isRefresh && mounted) setState(() => _isLoading = true);

    try {
      // ✅ 새로운 테이블 정보를 가져오도록 SQL이 업데이트된 Service 호출
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
      debugPrint('❌ 데이터 로드 실패: $e');
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
      debugPrint('❌ 추가 데이터 로드 실패: $e');
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
    } else if (_rankingSortOption == '리뷰 개수 순') {
      rankings.sort((a, b) {
        int compare = b.reviewCount.compareTo(a.reviewCount);
        if (compare == 0) {
          return b.avgScore.compareTo(a.avgScore);
        }
        return compare;
      });
    } else {
      rankings.sort((a, b) => b.avgScore.compareTo(a.avgScore));
    }

    // ✅ [핵심] 정렬 후 순위를 다시 매길 때, 주소/좌표/태그 정보 유실 방지
    for (int i = 0; i < rankings.length; i++) {
      rankings[i] = StoreRanking(
        storeName: rankings[i].storeName,
        avgScore: rankings[i].avgScore,
        avgUserRating: rankings[i].avgUserRating,
        reviewCount: rankings[i].reviewCount,
        avgTrust: rankings[i].avgTrust,
        rank: i + 1,
        // ✅ 아래 필드들을 반드시 복사해야 새 DB 정보가 반영됨
        topTags: rankings[i].topTags,
        address: rankings[i].address,
        lat: rankings[i].lat,
        lng: rankings[i].lng,
      );
    }
    return rankings;
  }

  String _getLocalizedSortLabel(String value, AppLocalizations l10n) {
    switch (value) {
      case '니즈파인 점수순': return l10n.sortByScore;
      case '신뢰도순': return l10n.sortByReliability;
      case '쓴소리': return l10n.bitterCriticism;
      case '니즈파인 순': return l10n.sortByScore;
      case '사용자 별점 순': return l10n.sortByUserRating;
      case '리뷰 개수 순': return l10n.sortByReviewCount;
      case '최신순': return l10n.latestOrder;
      default: return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.reviewRanking, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            CompositedTransformTarget(
              link: _layerLink,
              child: GestureDetector(
                onTap: _showInfoPopup,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.question_mark,
                    size: 12,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF9C7CFF),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _loadInitialData(isRefresh: true)
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              _isLoading
                  ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9C7CFF))))
                  : Column(
                children: [
                  if (_stats != null) _buildStatsHeader(l10n),
                  _buildSortControls(l10n),
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
                            TabBar(
                              labelColor: const Color(0xFF9C7CFF),
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: const Color(0xFF9C7CFF),
                              tabs: [
                                Tab(text: l10n.reviewList),
                                Tab(text: l10n.storeRanking)
                              ],
                            ),
                            Expanded(
                              child: TabBarView(children: [_buildReviewList(l10n), _buildStoreRankingList(l10n)]),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
              DraggableFloatingActionButton(
                heroTag: 'ranking_write_fab',
                initialOffset: Offset(constraints.maxWidth - 80, constraints.maxHeight - 100),
                parentHeight: constraints.maxHeight,
                onPressed: () async {
                  final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const WriteReviewScreen()));
                  if (result == true) _loadInitialData(isRefresh: true);
                },
                child: const Icon(Icons.edit, color: Colors.white),
              ),
            ],
          );
        }
      ),
      // floatingActionButton: Removed
    );
  }

  Widget _buildStatsHeader(AppLocalizations l10n) => Container(
    padding: const EdgeInsets.all(16.0),
    color: const Color(0xFFF0E9FF),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(l10n.totalReviews, '${_stats!.total}개'),
        _buildStatItem(l10n.avgNeedsFineScore, _stats!.average == 0 ? '-' : _stats!.average.toStringAsFixed(1)),
        _buildStatItem(l10n.avgReliability, _stats!.avgTrust == 0 ? '-' : '${_stats!.avgTrust.toStringAsFixed(0)}%'),
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

  Widget _buildSortControls(AppLocalizations l10n) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        DropdownButton<String>(
          value: _tabIndex == 0 ? _reviewSortOption : _rankingSortOption,
          underline: const SizedBox(),
          items: (_tabIndex == 0
              ? ['최신순', '니즈파인 점수순', '신뢰도순', '쓴소리']
              : ['니즈파인 순', '사용자 별점 순', '리뷰 개수 순']
          ).map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(_getLocalizedSortLabel(value, l10n), style: const TextStyle(fontSize: 14)),
            );
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

  Widget _buildReviewList(AppLocalizations l10n) {
    final reviews = _getSortedReviews();
    if (reviews.isEmpty && !_isLoading) {
      return RefreshIndicator(
        onRefresh: () => _loadInitialData(isRefresh: true),
        color: const Color(0xFF8A2BE2),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              height: constraints.maxHeight,
              alignment: Alignment.center,
              child: Text(
                _reviewSortOption == '쓴소리' ? l10n.noBitterReviews : l10n.noListGenerated,
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadInitialData(isRefresh: true),
      color: const Color(0xFF8A2BE2),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
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
              if (result == true) _loadInitialData(isRefresh: true);
            },
            onTapStore: () {
              if (reviews[index].storeName.isNotEmpty) {
                searchTrigger.value = SearchTarget(
                    query: reviews[index].storeName,
                    lat: reviews[index].storeLat,
                    lng: reviews[index].storeLng
                );
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.movingToMap)));
              }
            },
            onTapProfile: () {
              if (reviews[index].userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UserProfileScreen(userId: reviews[index].userId!)),
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildStoreRankingList(AppLocalizations l10n) {
    final rankings = _getSortedRankings();
    final double overallAverage = _stats?.average ?? 0.0;

    if (rankings.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadInitialData(isRefresh: true),
        color: const Color(0xFF8A2BE2),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Container(
              height: constraints.maxHeight,
              alignment: Alignment.center,
              child: Text(l10n.noInfo),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadInitialData(isRefresh: true),
      color: const Color(0xFF8A2BE2),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: rankings.length,
        itemBuilder: (context, index) {
          final ranking = rankings[index];

          final double currentScore = _rankingSortOption == '니즈파인 순'
              ? ranking.avgScore
              : ranking.avgUserRating;

          final bool isAboveAverage = currentScore >= overallAverage;

          final nextRanking = (index + 1 < rankings.length)
              ? rankings[index + 1]
              : null;

          final double? nextScore = nextRanking != null
              ? (_rankingSortOption == '니즈파인 순' ? nextRanking.avgScore : nextRanking.avgUserRating)
              : null;

          final bool isNextBelowAverage = nextScore != null && nextScore < overallAverage;
          final bool showDivider = isAboveAverage && isNextBelowAverage;

          return Column(
            children: [
              GestureDetector(
                onTap: () {
                  // ✅ [핵심] 지도 검색 트리거 작동
                  searchTrigger.value = SearchTarget(query: ranking.storeName);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${ranking.storeName} ${l10n.movingToMap}")));
                },
                child: StoreRankingCard(
                  ranking: ranking,
                  sortOption: _rankingSortOption,
                ),
              ),

              if (showDivider) _buildAverageDivider(overallAverage, l10n),

              if (!showDivider && index < rankings.length - 1)
                const Divider(height: 1),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAverageDivider(double average, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(double.infinity, 1),
            painter: _DashedLinePainter(),
          ),
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
              '${l10n.avgNeedsFineScore} ${average.toStringAsFixed(1)}',
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