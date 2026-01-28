// lib/screens/myfeed_screen.dart
import 'package:flutter/material.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/models/user_model.dart';
import 'package:needsfine_app/screens/follow_list_screen.dart';
import 'dart:io';

// ✅ Review 모델 임포트
import 'package:needsfine_app/models/ranking_models.dart';

class MyFeedScreen extends StatelessWidget {
  // ✅ [수정] 팔로우 리스트 조회를 위해 userId 필드 추가
  final String userId;
  final UserProfile userProfile;
  final List<Review> reviews;

  const MyFeedScreen({
    super.key,
    required this.userId, // ✅ 필수 인자로 추가
    required this.userProfile,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("프로필", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () => _showMoreOptions(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context),
            const Divider(thickness: 8, color: Color(0xFFF2F2F7)), // 구분선 색상 조정
            _buildReviewSection(context),
          ],
        ),
      ),
    );
  }

  // 1. 프로필 헤더
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
                backgroundColor: Colors.grey[200],
                backgroundImage: profileImage,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userProfile.nickname,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // ✅ [수정] 터치 영역 확장을 위해 Row 전체에 이벤트 적용하거나 패딩 추가
                    Row(
                      children: [
                        InkWell(
                          onTap: () => _navigateToFollowList(context, 0),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                                children: [
                                  const TextSpan(text: "팔로워 "),
                                  TextSpan(
                                      text: "${userProfile.followerCount}",
                                      style: const TextStyle(fontWeight: FontWeight.bold)
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: () => _navigateToFollowList(context, 1),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                                children: [
                                  const TextSpan(text: "팔로잉 "),
                                  TextSpan(
                                      text: "${userProfile.followingCount}",
                                      style: const TextStyle(fontWeight: FontWeight.bold)
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 24),

          // ✅ [수정] 더미 데이터(평균 별점) 삭제함. 실제 데이터인 신뢰도만 표시.
          Row(
            children: [
              // 신뢰도 (실제 데이터)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8A2BE2).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Color(0xFF8A2BE2), size: 16),
                    const SizedBox(width: 6),
                    Text(
                        "신뢰도 ${userProfile.reliability}%",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF8A2BE2))
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 팔로우/편집 버튼 (상황에 맞게 기능 연결 필요)
          ElevatedButton(
            onPressed: () {
              // 본인 프로필이면 편집, 타인이면 팔로우 로직 (여기선 UI만 유지)
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: const Color(0xFF8A2BE2),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("프로필 편집", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  // ✅ [수정] userId를 정상적으로 전달하여 이동하도록 수정
  void _navigateToFollowList(BuildContext context, int tabIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FollowListScreen(
          userId: userId, // ✅ 상위에서 받아온 진짜 ID 사용
          nickname: userProfile.nickname,
          initialTabIndex: tabIndex,
        ),
      ),
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
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

  Widget _buildReviewCard(BuildContext context, Review review) {
    final dateStr = "${review.createdAt.year}.${review.createdAt.month.toString().padLeft(2,'0')}.${review.createdAt.day.toString().padLeft(2,'0')}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            // 리뷰 상세 페이지로 이동하고 싶다면 여기에 연결
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 가게 정보 헤더
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                          color: const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(12)
                      ),
                      child: const Icon(Icons.store_rounded, color: Colors.grey, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(review.storeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(review.storeAddress ?? "주소 정보 없음", style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 2. 사진 (있을 경우)
                if (review.photoUrls.isNotEmpty) ...[
                  SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: review.photoUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            review.photoUrls[index],
                            width: 100, height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                                width: 100, height: 100, color: Colors.grey[200], child: const Icon(Icons.error)
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 3. 별점 및 날짜
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 18),
                    const SizedBox(width: 4),
                    Text(review.userRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 10, color: Colors.grey[300]),
                    const SizedBox(width: 8),
                    Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 10),

                // 4. 리뷰 내용
                Text(
                  review.reviewText,
                  style: const TextStyle(height: 1.6, fontSize: 15, color: Colors.black87),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF2F2F7)),
      ],
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(userProfile.nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.visibility_off_outlined, color: Colors.black87),
                    title: const Text("내 리뷰 숨기기", style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () => Navigator.pop(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.share_outlined, color: Color(0xFF8A2BE2)),
                    title: const Text("내 피드 공유", style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF8A2BE2))),
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}