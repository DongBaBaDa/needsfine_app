import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/widgets/review_card.dart';
import 'package:needsfine_app/screens/review_detail_screen.dart';
import 'package:needsfine_app/screens/user_profile_screen.dart';

class ReviewCollectionScreen extends StatefulWidget {
  const ReviewCollectionScreen({super.key});

  @override
  State<ReviewCollectionScreen> createState() => _ReviewCollectionScreenState();
}

class _ReviewCollectionScreenState extends State<ReviewCollectionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  List<Review> _myReviews = [];
  List<Review> _likedReviews = [];
  List<Review> _commentedReviews = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // 1. 내가 쓴 리뷰 로드
      final myReviewsData = await _supabase
          .from('reviews')
          .select('*, profiles(*)')
          .eq('user_id', userId)
          .eq('is_hidden', false)
          .order('created_at', ascending: false);

      // 2. 도움이 됐어요 (좋아요한 리뷰) 로드
      final likedReviewsData = await _supabase
          .from('review_votes')
          .select('reviews(*, profiles(*))')
          .eq('user_id', userId)
          .eq('vote_type', 'like');

      // 3. 내가 댓글을 단 리뷰 로드
      final commentedData = await _supabase
          .from('comments')
          .select('content, created_at, reviews(*, profiles(*))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _myReviews = (myReviewsData as List).map((json) => Review.fromJson(json)).toList();

          _likedReviews = (likedReviewsData as List).map((item) {
            final reviewJson = item['reviews'];
            if (reviewJson == null) return null;
            try {
              return Review.fromJson(reviewJson);
            } catch (e) {
              return null;
            }
          }).whereType<Review>().toList();

          _commentedReviews = (commentedData as List).map((item) {
            final reviewJson = item['reviews'];
            if (reviewJson == null) return null;

            final combinedJson = Map<String, dynamic>.from(reviewJson);
            combinedJson['comment_content'] = item['content'];
            combinedJson['comment_created_at'] = item['created_at'];

            return Review.fromJson(combinedJson);
          }).whereType<Review>().toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("데이터 로드 실패: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // Light Grey Background
      appBar: AppBar(
        title: const Text("리뷰 모음"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: kNeedsFinePurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: kNeedsFinePurple,
          tabs: const [
            Tab(text: "내가 쓴 리뷰"),
            Tab(text: "도움이 됐어요"),
            Tab(text: "댓글 단 리뷰"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildReviewList(_myReviews, "작성한 리뷰가 없습니다.", false),
          _buildReviewList(_likedReviews, "도움이 됐어요 표시한 리뷰가 없습니다.", false),
          _buildReviewList(_commentedReviews, "댓글을 작성한 리뷰가 없습니다.", true),
        ],
      ),
    );
  }

  Widget _buildReviewList(List<Review> reviews, String emptyMessage, bool isCommentMode) {
    if (reviews.isEmpty) {
      return Center(child: Text(emptyMessage, style: const TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16), // Padding all 16
      itemCount: reviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12), // Spacing 12
      itemBuilder: (context, index) {
        final review = reviews[index];
        return ReviewCard(
          review: isCommentMode ? _convertToCommentUi(review) : review,
          onTap: () async {
            final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ReviewDetailScreen(review: review))
            );
            if (result == true) _fetchData();
          },
          onTapStore: () {},
          onTapProfile: () {
            if (review.userId != null) {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UserProfileScreen(userId: review.userId!))
              );
            }
          },
        );
      },
    );
  }

  Review _convertToCommentUi(Review original) {
    return Review(
      id: original.id,
      storeName: original.storeName,
      storeAddress: original.storeAddress,
      reviewText: original.myCommentText ?? "내용 없음",
      userRating: original.userRating,
      needsfineScore: original.needsfineScore,
      trustLevel: original.trustLevel,
      tags: original.tags,
      photoUrls: original.photoUrls,
      isCritical: original.isCritical,
      isHidden: original.isHidden,
      createdAt: original.myCommentCreatedAt ?? original.createdAt,
      userId: original.userId,
      userEmail: original.userEmail,
      likeCount: original.likeCount,
      nickname: original.nickname,
      userProfileUrl: original.userProfileUrl,
      commentCount: original.commentCount,
    );
  }
}