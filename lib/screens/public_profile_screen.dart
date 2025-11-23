import 'package:flutter/material.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';

class PublicProfileScreen extends StatelessWidget {
  const PublicProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 더미 데이터 (나중에 API 연결 시 교체)
    const String nickname = "리뷰의 신";
    const String title = "서울 핵심 상권 전문 미식가";
    const int level = 27;
    const int needsFineScore = 9850;
    const int reviewCount = 132;
    const int followerCount = 421;

    final List<String> tasteTags = [
      "한식",
      "일식",
      "호프/수제맥주",
      "조용한 분위기",
      "데이트용",
      "혼밥가능",
    ];

    final List<Map<String, String>> representativeReviews = [
      {
        "storeName": "니즈파인 버거 강남점",
        "score": "4.9",
        "snippet": "패티 육향이 살아있고, 번이 너무 버터리해서 좋았던 집.",
        "category": "양식 · 버거",
      },
      {
        "storeName": "마라 선배 홍대점",
        "score": "4.8",
        "snippet": "매운맛 단계가 세분화되어 있어서 입맛대로 즐기기 좋았음.",
        "category": "중식 · 마라탕",
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("공개 프로필"),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 상단 퍼플 커버 + 프로필
            _buildHeader(
              context,
              nickname: nickname,
              title: title,
              level: level,
              needsFineScore: needsFineScore,
            ),

            // 아래 흰 콘텐츠 박스
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 지표 3개 (NeedsFine 점수 / 리뷰 수 / 팔로워)
                    _buildStatsRow(
                      needsFineScore: needsFineScore,
                      reviewCount: reviewCount,
                      followerCount: followerCount,
                    ),
                    const SizedBox(height: 24),

                    // 취향 태그
                    _buildSectionTitle("취향 태그"),
                    const SizedBox(height: 8),
                    _buildTasteTags(tasteTags),
                    const SizedBox(height: 24),

                    // 대표 리뷰
                    _buildSectionTitle("대표 리뷰"),
                    const SizedBox(height: 8),
                    ...representativeReviews.map(
                          (review) => _buildReviewCard(
                        context,
                        storeName: review["storeName"]!,
                        score: review["score"]!,
                        snippet: review["snippet"]!,
                        category: review["category"]!,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 이 사람과 비슷한 유저 보기 (추후 기능용)
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: 추후 "비슷한 유저 추천" 기능 연결
                      },
                      icon: const Icon(Icons.group_outlined),
                      label: const Text("비슷한 취향의 유저 보기"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        foregroundColor: kNeedsFinePurple,
                        side: const BorderSide(color: kNeedsFinePurple),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  // ---------------------------
  // 상단 헤더 (퍼플 배경 + 프로필)
  // ---------------------------
  Widget _buildHeader(
      BuildContext context, {
        required String nickname,
        required String title,
        required int level,
        required int needsFineScore,
      }) {
    return Container
      (
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      color: kNeedsFinePurple,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 프로필 기본 아이콘 (B 선택안)
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person_outline,
                  size: 36,
                  color: kNeedsFinePurple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nickname,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Text(
                            "LV.$level",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.emoji_events_outlined, size: 14, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                "NeedsFine ${needsFineScore.toString()}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------
  // 지표 3개 (점수 / 리뷰 / 팔로워)
  // ---------------------------
  Widget _buildStatsRow({
    required int needsFineScore,
    required int reviewCount,
    required int followerCount,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatBox(
            label: "NeedsFine 점수",
            value: needsFineScore.toString(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatBox(
            label: "리뷰 수",
            value: reviewCount.toString(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatBox(
            label: "팔로워",
            value: followerCount.toString(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ---------------------------
  // 섹션 타이틀
  // ---------------------------
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  // ---------------------------
  // 취향 태그
  // ---------------------------
  Widget _buildTasteTags(List<String> tags) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags
          .map(
            (t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: kNeedsFinePurple.withOpacity(0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: kNeedsFinePurple.withOpacity(0.2)),
          ),
          child: Text(
            t,
            style: TextStyle(
              fontSize: 12,
              color: kNeedsFinePurple.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      )
          .toList(),
    );
  }

  // ---------------------------
  // 대표 리뷰 카드
  // ---------------------------
  Widget _buildReviewCard(
      BuildContext context, {
        required String storeName,
        required String score,
        required String snippet,
        required String category,
      }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          // 매장 상세로 이동
          Navigator.pushNamed(context, '/store-detail');
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단: 매장 이름 + 점수
              Row(
                children: [
                  Expanded(
                    child: Text(
                      storeName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    score,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                category,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                snippet,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    "상세 보기",
                    style: TextStyle(
                      fontSize: 11,
                      color: kNeedsFinePurple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 12, color: kNeedsFinePurple),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
