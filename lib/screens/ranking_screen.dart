import 'package:flutter/material.dart';
import 'package:needsfine_app/models/app_data.dart';
import 'package:needsfine_app/widgets/review_card.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  String _sortOption = '최신순';
  String _filterOption = '전체';

  // 더미 데이터 생성
  final List<Review> _allReviews = List.generate(10, (i) => 
    Review(
      userName: 'User $i',
      content: '이것은 랭킹 화면을 위한 리뷰입니다. ${i % 3 == 0 ? "아주 훌륭해요." : "조금 아쉽네요."}',
      rating: 3.5 + i * 0.1,
      date: '2024-05-1${9-i}',
    )
  );

  List<Review> get _filteredReviews {
    List<Review> reviews = List.from(_allReviews);

    // 필터링
    if (_filterOption == '신뢰도 높음') {
      reviews = reviews.where((r) => r.trustLevel >= 80).toList();
    } else if (_filterOption == '비판적 리뷰') {
      reviews = reviews.where((r) => r.needsfineScore < 75).toList(); // 임시 기준
    }

    // 정렬
    switch (_sortOption) {
      case '신뢰도순':
        reviews.sort((a, b) => b.trustLevel.compareTo(a.trustLevel));
        break;
      case '별점 높은 순':
        reviews.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case '별점 낮은 순':
        reviews.sort((a, b) => a.rating.compareTo(b.rating));
        break;
      case '최신순':
      default:
        reviews.sort((a, b) => b.date.compareTo(a.date));
        break;
    }

    return reviews;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('리뷰 랭킹'),
      ),
      body: Column(
        children: [
          _buildFilterAndSortControls(),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredReviews.length,
              itemBuilder: (context, index) {
                return ReviewCard(review: _filteredReviews[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSortControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Wrap(
                spacing: 8.0,
                children: ['전체', '신뢰도 높음', '비판적 리뷰'].map((filter) {
                  return ChoiceChip(
                    label: Text(filter),
                    selected: _filterOption == filter,
                    onSelected: (selected) {
                      if (selected) setState(() => _filterOption = filter);
                    },
                  );
                }).toList(),
              ),
              const Spacer(),
              DropdownButton<String>(
                value: _sortOption,
                underline: const SizedBox(),
                items: ['최신순', '신뢰도순', '별점 높은 순', '별점 낮은 순']
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _sortOption = newValue!;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
