import 'package:flutter/material.dart';
import '../models/app_data.dart';

class StoreDetailScreen extends StatefulWidget {
  const StoreDetailScreen({super.key});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  @override
  Widget build(BuildContext context) {
    // arguments로 가게 ID를 받음 (이전 오류 수정)
    final String storeId = ModalRoute.of(context)!.settings.arguments as String;
    final store = AppData().stores.firstWhere((s) => s.id == storeId);

    return Scaffold(
      appBar: AppBar(title: Text(store.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. 점수판
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreCard("별점", "⭐ ${store.userRating.toStringAsFixed(1)}"),
              _buildScoreCard("니즈파인 F", "F ${store.needsFineScore.toStringAsFixed(1)}", isF: true),
            ],
          ),
          const SizedBox(height: 20),

          // 2. 리뷰 쓰기 버튼
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.pushNamed(context, '/write-review', arguments: store.id);
              setState(() {}); // 돌아왔을 때 화면 갱신
            },
            icon: const Icon(Icons.edit),
            label: const Text("리뷰 남기고 점수 바꾸기"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 20),

          // 3. 리뷰 리스트
          const Text("최신 리뷰", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (store.reviews.isEmpty)
            const Center(child: Text("아직 리뷰가 없습니다. 첫 리뷰를 남겨보세요!")),

          ...store.reviews.map((review) => Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(review.userName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(review.content),
                  const SizedBox(height: 5),
                  // [오류 수정] qrScore 대신 needsfineScore와 trustLevel 표시
                  Row(
                    children: [
                      Text(
                        "F ${review.needsfineScore.toStringAsFixed(1)}",
                        style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "신뢰도 ${review.trustLevel}%",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  Text(review.rating.toStringAsFixed(1)),
                ],
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String title, String value, {bool isF = false}) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isF ? Colors.blue.shade50 : Colors.white,
        border: Border.all(color: isF ? Colors.blue : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isF ? Colors.blue : Colors.black
          )),
        ],
      ),
    );
  }
}