import 'package:flutter/material.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/services/review_service.dart';
import 'package:needsfine_app/utils/ranking_calculator.dart';
import 'package:needsfine_app/widgets/star_rating.dart';
import 'package:needsfine_app/screens/write_review_screen.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  // 상태 변수
  List<Review> _allReviews = [];
  List<StoreRanking> _storeRankings = [];
  Stats? _stats;
  bool _isLoading = true;

  // 필터 & 정렬 옵션
  String _sortOption = '최신순';
  String _filterOption = '전체';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 데이터 로드
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final reviews = await ReviewService.fetchReviews();
      
      if (reviews.isNotEmpty) {
        // 통계 계산
        final avgScore = reviews.map((r) => r.needsfineScore).reduce((a, b) => a + b) / reviews.length;
        final avgTrust = reviews.map((r) => r.trustLevel).reduce((a, b) => a + b) / reviews.length;

        setState(() {
          _allReviews = reviews;
          _stats = Stats(
            total: reviews.length,
            average: avgScore,
            avgTrust: avgTrust,
          );
          _storeRankings = RankingCalculator.calculateStoreRankings(reviews);
        });
      } else {
        setState(() {
             _allReviews = [];
             _storeRankings = [];
             _stats = null;
        });
      }
    } catch (e) {
      print('❌ 데이터 로드 실패: $e');
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  // 필터링 & 정렬된 리뷰 목록
  List<Review> get _filteredReviews {
    List<Review> reviews = List.from(_allReviews);

    // 필터링
    switch (_filterOption) {
      case '신뢰도 높음':
        reviews = reviews.where((r) => r.trustLevel >= 80).toList();
        break;
      case '비판적 리뷰':
        reviews = reviews.where((r) => r.needsfineScore < 75).toList();
        break;
      case '전체':
      default:
        break;
    }

    // 정렬
    switch (_sortOption) {
      case '신뢰도순':
        reviews.sort((a, b) => b.trustLevel.compareTo(a.trustLevel));
        break;
      case '니즈파인 점수순':
        reviews.sort((a, b) => b.needsfineScore.compareTo(a.needsfineScore));
        break;
      case '별점 높은 순':
        reviews.sort((a, b) => b.userRating.compareTo(a.userRating));
        break;
      case '별점 낮은 순':
        reviews.sort((a, b) => a.userRating.compareTo(b.userRating));
        break;
      case '최신순':
      default:
        reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return reviews;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('리뷰 랭킹', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF9C7CFF),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9C7CFF)),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // 로고 이미지 (없을 경우 텍스트로 대체될 수 있도록 안전 장치)
            Image.asset(
                'assets/needsfine_logo.png', 
                height: 28,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.star, color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Text('리뷰 랭킹', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: const Color(0xFF9C7CFF),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData)
        ]
      ),
      body: Column(
        children: [
          // 통계 헤더
          if (_stats != null) _buildStatsHeader(),
          
          // 필터 & 정렬 컨트롤
          _buildFilterAndSortControls(),
          
          const Divider(height: 1),
          
          // 탭 뷰 (리뷰 목록 / 매장 순위)
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    labelColor: Color(0xFF9C7CFF),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Color(0xFF9C7CFF),
                    tabs: [
                      Tab(text: '리뷰 목록'),
                      Tab(text: '매장 순위'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildReviewList(),
                        _buildStoreRankingList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WriteReviewScreen()),
          );
          
          // 리뷰 작성 성공 시 목록 새로고침
          if (result == true) {
            _loadData();
          }
        },
        backgroundColor: const Color(0xFF9C7CFF),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  // 통계 헤더
  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: const Color(0xFFF0E9FF),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('총 리뷰', '${_stats!.total}개'),
          _buildStatItem('평균 점수', _stats!.average.toStringAsFixed(1)),
          _buildStatItem('평균 신뢰도', '${_stats!.avgTrust.toStringAsFixed(0)}%'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF9C7CFF),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  // 필터 & 정렬 컨트롤
  Widget _buildFilterAndSortControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          // 필터 칩
          Expanded(
            child: Wrap(
              spacing: 8.0,
              children: ['전체', '신뢰도 높음', '비판적 리뷰'].map((filter) {
                return ChoiceChip(
                  label: Text(filter),
                  selected: _filterOption == filter,
                  selectedColor: const Color(0xFF9C7CFF),
                  labelStyle: TextStyle(
                    color: _filterOption == filter ? Colors.white : Colors.black,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _filterOption = filter);
                  },
                );
              }).toList(),
            ),
          ),
          
          // 정렬 드롭다운
          DropdownButton<String>(
            value: _sortOption,
            underline: const SizedBox(),
            items: [
              '최신순',
              '니즈파인 점수순',
              '신뢰도순',
              '별점 높은 순',
              '별점 낮은 순'
            ].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() => _sortOption = newValue!);
            },
          ),
        ],
      ),
    );
  }

  // 리뷰 목록
  Widget _buildReviewList() {
    if (_filteredReviews.isEmpty) {
      return const Center(
        child: Text('조건에 맞는 리뷰가 없습니다.'),
      );
    }

    return ListView.separated(
      itemCount: _filteredReviews.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final review = _filteredReviews[index];
        return _buildReviewCard(review);
      },
    );
  }

  // 리뷰 카드
  Widget _buildReviewCard(Review review) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (가게명 + 별점)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  review.storeName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              StarRating(rating: review.userRating),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 니즈파인 점수 + 신뢰도
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C7CFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '니즈파인 ${review.needsfineScore.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '신뢰도 ${review.trustLevel}%',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // 리뷰 내용
          Text(
            review.reviewText,
            style: const TextStyle(fontSize: 14),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 8),
          
          // 태그
          if (review.tags.isNotEmpty)
            Wrap(
              spacing: 6.0,
              children: review.tags.map((tag) {
                return Chip(
                  label: Text(
                    tag,
                    style: const TextStyle(fontSize: 11),
                  ),
                  backgroundColor: const Color(0xFFF0E9FF),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          
          const SizedBox(height: 4),
          
          // 작성일
          Text(
            '${review.createdAt.year}.${review.createdAt.month}.${review.createdAt.day}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // 매장 순위 목록
  Widget _buildStoreRankingList() {
    if (_storeRankings.isEmpty) {
      return const Center(
        child: Text('매장 데이터가 없습니다.'),
      );
    }

    return ListView.separated(
      itemCount: _storeRankings.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final ranking = _storeRankings[index];
        return _buildRankingCard(ranking);
      },
    );
  }

  // 매장 순위 카드
  Widget _buildRankingCard(StoreRanking ranking) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // 순위 배지
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ranking.rank <= 3 
                  ? const Color(0xFF9C7CFF) 
                  : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${ranking.rank}',
                style: TextStyle(
                  color: ranking.rank <= 3 ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 매장 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ranking.storeName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '평균 ${ranking.avgScore.toStringAsFixed(1)}점',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF9C7CFF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '신뢰도 ${ranking.avgTrust.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '리뷰 ${ranking.reviewCount}개',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                if (ranking.topTags != null && ranking.topTags!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Wrap(
                      spacing: 4.0,
                      children: ranking.topTags!.map((tag) {
                        return Chip(
                          label: Text(
                            tag,
                            style: const TextStyle(fontSize: 10),
                          ),
                          backgroundColor: const Color(0xFFF0E9FF),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
