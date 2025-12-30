import 'package:flutter/material.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/services/review_service.dart';
import 'package:needsfine_app/utils/ranking_calculator.dart';
import 'package:needsfine_app/widgets/star_rating.dart';
import 'package:needsfine_app/screens/write_review_screen.dart';

// [추가] 화면 간 데이터 전달을 위한 전역 트리거
final ValueNotifier<String?> searchTrigger = ValueNotifier<String?>(null);

class ReviewDetailScreen extends StatelessWidget {
  final Review review;
  const ReviewDetailScreen({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(review.storeName),
        backgroundColor: const Color(0xFF9C7CFF),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InkWell(
                    // [수정] 매장명 클릭 시 주소를 트리거에 담음
                    onTap: () {
                      if (review.storeAddress != null) {
                        searchTrigger.value = review.storeAddress;
                      }
                    },
                    child: Text(
                        review.storeName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9C7CFF), // 클릭 가능함을 알리는 보라색
                          decoration: TextDecoration.underline, // 언더라인 추가
                        )
                    ),
                  ),
                ),
                StarRating(rating: review.userRating, size: 20),
              ],
            ),
            if (review.storeAddress != null && review.storeAddress!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(review.storeAddress!, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF9C7CFF), borderRadius: BorderRadius.circular(12)),
                child: Text('니즈파인 ${review.needsfineScore.toStringAsFixed(1)}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(12)),
                child: Text('신뢰도 ${review.trustLevel}%', style: const TextStyle(fontSize: 14)),
              ),
            ]),
            const Divider(height: 32),
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
                      child: Image.network(review.photoUrls[index], fit: BoxFit.cover, width: 100, height: 100),
                    );
                  },
                ),
              ),
            if (review.photoUrls.isNotEmpty) const SizedBox(height: 16),
            const Text('리뷰 내용', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(review.reviewText, style: const TextStyle(fontSize: 15, height: 1.5)),
            const SizedBox(height: 24),
            if (review.tags.isNotEmpty) Wrap(
              spacing: 8.0,
              children: review.tags.map((tag) => Chip(label: Text(tag), backgroundColor: const Color(0xFFF0E9FF), visualDensity: VisualDensity.compact)).toList(),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [Text('${review.createdAt.year}.${review.createdAt.month}.${review.createdAt.day} 작성', style: const TextStyle(fontSize: 12, color: Colors.grey))],
            ),
          ],
        ),
      ),
    );
  }
}

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});
  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  List<Review> _allReviews = [];
  List<StoreRanking> _storeRankings = [];
  Stats? _stats;
  bool _isLoading = true;
  String _sortOption = '최신순';
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if(mounted) setState(() => _isLoading = true);
    try {
      final reviews = await ReviewService.fetchReviews(limit: 100);
      if (mounted) {
        setState(() {
          _allReviews = reviews;
          if (reviews.isNotEmpty) {
            final avgScore = reviews.map((r) => r.needsfineScore).reduce((a, b) => a + b) / reviews.length;
            final avgTrust = reviews.map((r) => r.trustLevel).reduce((a, b) => a + b) / reviews.length;
            _stats = Stats(total: reviews.length, average: avgScore, avgTrust: avgTrust);
            _storeRankings = RankingCalculator.calculateStoreRankings(reviews);
          } else {
            _stats = null;
            _storeRankings = [];
          }
        });
      }
    } catch (e) {
      print('❌ 데이터 로드 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<dynamic> get _sortedList {
    if (_tabIndex == 0) {
      List<Review> reviews = List.from(_allReviews);
      switch (_sortOption) {
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
    } else {
      return List.from(_storeRankings);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('리뷰 랭킹', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF9C7CFF),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData)],
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
          if (result == true) _loadData();
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
        _buildStatItem('평균 점수', _stats!.average.toStringAsFixed(1)),
        _buildStatItem('평균 신뢰도', '${_stats!.avgTrust.toStringAsFixed(0)}%'),
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
          value: _sortOption,
          underline: const SizedBox(),
          items: ['최신순', '니즈파인 점수순', '신뢰도순', '쓴소리'].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontSize: 14)));
          }).toList(),
          onChanged: (newValue) => setState(() => _sortOption = newValue!),
        ),
      ],
    ),
  );

  Widget _buildReviewList() {
    final reviews = _sortedList.cast<Review>();
    return reviews.isEmpty
        ? const Center(child: Text('조건에 맞는 리뷰가 없습니다.'))
        : ListView.separated(
      itemCount: reviews.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) => _buildReviewCard(reviews[index]),
    );
  }

  Widget _buildReviewCard(Review review) => InkWell(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewDetailScreen(review: review))),
    child: Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: InkWell(
                // [수정] 카드 내 매장명 클릭 시 주소 전달
                onTap: () {
                  if (review.storeAddress != null) {
                    searchTrigger.value = review.storeAddress;
                  }
                },
                child: Text(
                    review.storeName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9C7CFF),
                      decoration: TextDecoration.underline,
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
          const SizedBox(height: 8),
          Text(review.reviewText, style: const TextStyle(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
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
    final rankings = _sortedList.cast<StoreRanking>();
    return rankings.isEmpty
        ? const Center(child: Text('매장 데이터가 없습니다.'))
        : ListView.separated(
      itemCount: rankings.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) => _buildRankingCard(rankings[index]),
    );
  }

  Widget _buildRankingCard(StoreRanking ranking) => Container(
    padding: const EdgeInsets.all(16.0),
    child: Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: ranking.rank <= 3 ? const Color(0xFF9C7CFF) : Colors.grey[300], shape: BoxShape.circle),
        child: Center(child: Text('${ranking.rank}', style: TextStyle(color: ranking.rank <= 3 ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 18))),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(
            // [수정] 랭킹 리스트 매장명 클릭 시 동작
            onTap: () => searchTrigger.value = ranking.storeName, // 주소가 없을 경우 이름으로 시도
            child: Text(ranking.storeName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF9C7CFF), decoration: TextDecoration.underline)),
          ),
          const SizedBox(height: 4),
          Row(children: [
            Text('평균 ${ranking.avgScore.toStringAsFixed(1)}점', style: const TextStyle(fontSize: 14, color: Color(0xFF9C7CFF), fontWeight: FontWeight.bold)),
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