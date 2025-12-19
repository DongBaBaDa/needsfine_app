import 'package:flutter/material.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import '../models/app_data.dart';

class StoreDetailScreen extends StatefulWidget {
  const StoreDetailScreen({super.key});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  // 더미 데이터: 실제로는 API 등을 통해 가져와야 합니다.
  final double _naverRating = 4.8;

  @override
  Widget build(BuildContext context) {
    final String storeId = ModalRoute.of(context)!.settings.arguments as String;
    final store = AppData().stores.firstWhere((s) => s.id == storeId);

    return Scaffold(
      appBar: AppBar(title: Text(store.name)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTrustAnchorSection(store),
                const SizedBox(height: 24),
                Text(
                  store.category,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: store.tags
                      .map((tag) => Chip(
                            label: Text(tag),
                            backgroundColor: Colors.grey[100],
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("검증된 리뷰 (${store.reviewCount})"),
                    TextButton.icon(
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/write-review', arguments: store.id);
                        setState(() {});
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text("리뷰 쓰기"),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (store.reviews.isEmpty)
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text("아직 검증된 리뷰가 없습니다.\n첫 번째 탐정이 되어보세요!",
                        textAlign: TextAlign.center),
                  )),
                ...store.reviews.map((review) => _buildReviewCard(review)),
              ],
            ),
          ),
          _buildGatewayBottomBar(store),
        ],
      ),
    );
  }

  Widget _buildTrustAnchorSection(Store store) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text("신뢰도 분석 리포트",
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  const Text("네이버/캐치테이블", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text("$_naverRating",
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough)),
                ],
              ),
              const Icon(Icons.arrow_forward, color: Colors.grey),
              Column(
                children: [
                  const Text("니즈파인 검증 F",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: kNeedsFinePurple)),
                  const SizedBox(height: 4),
                  Text(
                    store.needsFineScore.toStringAsFixed(1),
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: kNeedsFinePurple),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kNeedsFinePurpleLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 16, color: kNeedsFinePurple),
                SizedBox(width: 8),
                Text("거품이 제거된 '진짜 맛집'입니다.",
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: kNeedsFinePurple)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  radius: 16,
                  child: const Icon(Icons.person, size: 20, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(review.date,
                        style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: review.trustLevel >= 80
                        ? kNeedsFinePurpleLight
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "신뢰도 ${review.trustLevel}%",
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: review.trustLevel >= 80
                            ? kNeedsFinePurple
                            : Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(review.content),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.star, size: 14, color: Colors.amber),
                const SizedBox(width: 2),
                Text(review.rating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 12),
                Text("F ${review.needsfineScore.toStringAsFixed(1)}",
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: kNeedsFinePurple)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGatewayBottomBar(Store store) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: () {
                _showReturnLoopDialog("네이버 지도");
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined, size: 20, color: Colors.black87),
                  SizedBox(height: 2),
                  Text("길찾기", style: TextStyle(fontSize: 10, color: Colors.black87)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: ElevatedButton(
              onPressed: () {
                _showReturnLoopDialog("캐치테이블");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kNeedsFinePurple, // 니즈파인 대표색
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("빈자리 확인 & 예약",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("캐치테이블로 연결됩니다",
                      style: TextStyle(fontSize: 10, color: Colors.white70)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReturnLoopDialog(String platformName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("잠깐! 예약 성공하시겠어요?",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "$platformName(으)로 이동합니다.\n\n맛있게 드시고 다시 돌아와서\n'영수증 인증 리뷰'를 남겨주세요!",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Text("리뷰 작성 시 500P 적립 예정",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("취소", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: 실제 외부 앱 실행 로직 (url_launcher 사용)
              // _launchURL(store.outlinkUrl);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("$platformName(으)로 이동합니다.")),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kNeedsFinePurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("이동하기"),
          ),
        ],
      ),
    );
  }
}
