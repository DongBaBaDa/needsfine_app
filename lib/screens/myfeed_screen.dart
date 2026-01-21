// lib/screens/myfeed_screen.dart
import 'package:flutter/material.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/models/user_model.dart';
import 'package:needsfine_app/screens/follow_list_screen.dart';
import 'dart:io';

// ✅ Review 모델 임포트 필수
import 'package:needsfine_app/models/ranking_models.dart';

class MyFeedScreen extends StatelessWidget {
  final UserProfile userProfile;
  // ✅ List<dynamic> -> List<Review>로 명확하게 타입 지정
  final List<Review> reviews;

  const MyFeedScreen({
    super.key,
    required this.userProfile,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("프로필"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context),
            const Divider(thickness: 8, color: kNeedsFinePurpleLight),
            _buildReviewSection(context),
          ],
        ),
      ),
    );
  }

  // 1. 내 정보가 반영된 프로필 헤더
  Widget _buildProfileHeader(BuildContext context) {
    ImageProvider profileImage;
    if (userProfile.imageFile != null) {
      profileImage = FileImage(userProfile.imageFile!);
    } else if (userProfile.profileImageUrl.isNotEmpty) {
      profileImage = NetworkImage(userProfile.profileImageUrl);
    } else {
      profileImage = const AssetImage('assets/images/default_profile.png');
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: kNeedsFinePurpleLight,
                backgroundImage: profileImage,
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userProfile.nickname, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _navigateToFollowList(context, 0),
                        child: Text("팔로워 ${userProfile.followerCount}", style: const TextStyle(color: Colors.grey)),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _navigateToFollowList(context, 1),
                        child: Text("팔로잉 ${userProfile.followingCount}", style: const TextStyle(color: Colors.grey)),
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),

          // ✅ 실제 데이터가 있다면 연동 (현재는 하드코딩된 값 유지 혹은 계산된 값 전달 필요)
          _buildInfoRow("평균 별점", "5.0", isStar: true),
          const SizedBox(height: 14),
          _buildInfoRow("신뢰도", "${userProfile.reliability}%", isReliability: true),

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: kNeedsFinePurple,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("+ 팔로우", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _navigateToFollowList(BuildContext context, int tabIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowListScreen(
          userId: "current_user_id", // 실제 ID 연동 필요 시 userProfile에 id 필드 추가 권장
          nickname: userProfile.nickname,
          initialTabIndex: tabIndex,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isStar = false, bool isReliability = false}) {
    return Row(
      children: [
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 15))),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        if (isStar) ...[
          const SizedBox(width: 6),
          ...List.generate(5, (index) => const Icon(Icons.star, color: Colors.orange, size: 18)),
        ],
        if (isReliability) ...[
          const SizedBox(width: 6),
          const Icon(Icons.verified_user, color: kNeedsFinePurple, size: 18),
        ]
      ],
    );
  }

  Widget _buildReviewSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text("${userProfile.nickname} 님의 리뷰 ${reviews.length}개",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ),
          const SizedBox(height: 20),

          if (reviews.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(40.0),
              child: Text("아직 작성된 리뷰가 없습니다.", style: TextStyle(color: Colors.grey)),
            ))
          else
            ...reviews.map((review) => _buildReviewCard(context, review)).toList(),
        ],
      ),
    );
  }

  // ✅ [수정 핵심] dynamic -> Review 객체 사용으로 변경
  Widget _buildReviewCard(BuildContext context, Review review) {
    // 날짜 포맷팅 (간단하게 구현)
    final dateStr = "${review.createdAt.year}.${review.createdAt.month}.${review.createdAt.day}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: kNeedsFinePurpleLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.restaurant, color: kNeedsFinePurple, size: 22),
          ),
          // ✅ review['key'] 대신 review.property 사용
          title: Text(review.storeName, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(review.storeAddress ?? "주소 정보 없음"),
          onTap: () {},
        ),

        // 사진이 있는 경우 표시 (없으면 Placeholder 숨김 혹은 처리)
        if (review.photoUrls.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: review.photoUrls.length > 4 ? 4 : review.photoUrls.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  return Image.network(
                    review.photoUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                  );
                },
              ),
            ),
          )
        else
        // 사진 없으면 숨기거나 높이 0
          const SizedBox.shrink(),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 18),
                  // ✅ 점수 데이터 연결
                  Text(" ${review.userRating.toStringAsFixed(1)}  ·  ", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                  Text(" $dateStr ", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 12),
              // ✅ 리뷰 내용 연결
              Text(
                review.reviewText,
                style: const TextStyle(height: 1.5, fontSize: 15),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
      ],
    );
  }

  Widget _buildPlaceholder() => Container(color: kNeedsFinePurpleLight, child: const Icon(Icons.image, color: Colors.white));

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(userProfile.nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 16),
                _modalAction(context, "내 리뷰 숨기기", Colors.black87, Icons.visibility_off_outlined),
                _modalAction(context, "내 피드 공유", kNeedsFinePurple, Icons.share_outlined),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _modalAction(BuildContext context, String title, Color color, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      onTap: () => Navigator.pop(context),
    );
  }
}