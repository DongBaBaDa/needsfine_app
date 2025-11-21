import 'package:flutter/material.dart';

/// 내 주변 화면 (배달앱 / 쿠팡이츠 느낌)
class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  bool _showMap = false; // 나중에 지도 붙일 때 쓰려고 남겨둔 플래그 (지금은 UI만)

  // 더미 매장 데이터
  final List<Map<String, dynamic>> _stores = [
    {
      "name": "니즈파인 족발·보쌈 1호점",
      "score": 4.8,
      "trust": 96,
      "time": "12분",
      "distance": "0.8km",
      "tags": ["족발·보쌈", "야식", "포장"],
    },
    {
      "name": "성지 인증 김치찌개집",
      "score": 4.6,
      "trust": 93,
      "time": "15분",
      "distance": "1.2km",
      "tags": ["찜·탕", "혼밥", "가성비"],
    },
    {
      "name": "파인의 분식 연구소",
      "score": 4.9,
      "trust": 98,
      "time": "9분",
      "distance": "0.5km",
      "tags": ["분식", "간단식사", "단골많음"],
    },
  ];

  @override
  Widget build(BuildContext context) {
    // 니즈파인 포인트 컬러 (연보라 계열)
    const Color nfPurple = Color(0xFFB79CFF);
    const Color nfPurpleLight = Color(0xFFF3ECFF);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () {
            // 나중에 주소 선택 화면으로 연결 가능
            // Navigator.pushNamed(context, '/location');
          },
          child: Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: Colors.black),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  "현재 위치 기준",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: Colors.black),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // 나중에 필터 바텀시트 연결
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔹 상단 필터/토글 영역
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E5E5)),
              ),
            ),
            child: Row(
              children: [
                _buildFilterChip(icon: Icons.sort, label: "니즈파인 점수순"),
                const SizedBox(width: 8),
                _buildFilterChip(icon: Icons.schedule, label: "가까운 도착순"),
                const Spacer(),
                // 지도 / 리스트 토글 버튼
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showMap = !_showMap;
                    });
                  },
                  icon: Icon(
                    _showMap ? Icons.list : Icons.map,
                    size: 18,
                    color: nfPurple,
                  ),
                  label: Text(
                    _showMap ? "리스트 보기" : "지도 보기",
                    style: const TextStyle(fontSize: 13, color: nfPurple),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ],
            ),
          ),

          // 🔹 지도 Placeholder or 리스트
          Expanded(
            child: _showMap
                ? _buildMapPlaceholder(nfPurpleLight)
                : _buildStoreList(nfPurple, nfPurpleLight),
          ),
        ],
      ),
    );
  }

  /// 상단 필터 칩 (정렬/조건 같은 것)
  Widget _buildFilterChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[800])),
        ],
      ),
    );
  }

  /// 지도 영역 (지금은 디자인만, 나중에 진짜 지도 연결 가능)
  Widget _buildMapPlaceholder(Color bgColor) {
    return Container(
      width: double.infinity,
      color: bgColor,
      child: const Center(
        child: Text(
          "지도 연동 전입니다.\n나중에 내 주변 성지/매장을 지도에서 볼 수 있게 연결 예정 🗺️",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  /// 매장 리스트 영역
  Widget _buildStoreList(Color nfPurple, Color nfPurpleLight) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _stores.length,
      itemBuilder: (context, index) {
        final store = _stores[index];
        final bool isTop = index == 0; // 첫 번째 매장만 "니즈파인 Top" 배지

        return GestureDetector(
          onTap: () {
            // 나중에 매장 상세 페이지로 이동
            // Navigator.pushNamed(context, '/store-detail', arguments: storeId);
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 14),
            elevation: 1.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 이미지 영역 (지금은 색 박스)
                Container(
                  height: 140,
                  width: double.infinity,
                  color: nfPurpleLight,
                  alignment: Alignment.center,
                  child: const Text(
                    "매장 사진 영역",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isTop)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: nfPurpleLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.emoji_events, color: Color(0xFF9C27B0), size: 14),
                              SizedBox(width: 4),
                              Text(
                                "니즈파인 Top 매장",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF9C27B0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isTop) const SizedBox(height: 6),

                      // 매장 이름
                      Text(
                        store["name"] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // 점수 / 신뢰도
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            (store["score"] as double).toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "(신뢰도 ${(store["trust"] as int)}%)",
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // 시간 / 거리
                      Row(
                        children: [
                          Text(
                            store["time"] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "· ${store["distance"]}",
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // 태그들
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: (store["tags"] as List<String>).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: nfPurpleLight,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6A4FBF),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}