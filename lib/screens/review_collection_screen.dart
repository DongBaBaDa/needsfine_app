import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/widgets/review_card.dart';
import 'package:needsfine_app/screens/review_detail_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // 1. 내가 쓴 리뷰
      final myReviewsData = await _supabase
          .from('reviews')
          .select('*, profiles(nickname, user_number, email, profile_image_url)')
          .eq('user_id', userId)
          .eq('is_hidden', false)
          .order('created_at', ascending: false);

      // 2. 좋아요한 리뷰 (JSON 구조 파싱 주의)
      final likedReviewsData = await _supabase
          .from('review_votes')
          .select('reviews(*, profiles(nickname, user_number, email, profile_image_url))')
          .eq('user_id', userId)
          .eq('vote_type', 'like');

      if (mounted) {
        setState(() {
          _myReviews = (myReviewsData as List).map((json) => Review.fromJson(json)).toList();

          // ✅ [Fix] 중첩된 JSON 구조를 안전하게 파싱
          _likedReviews = (likedReviewsData as List).map((item) {
            final reviewJson = item['reviews'];
            // 삭제된 리뷰거나 데이터가 없으면 null 반환
            if (reviewJson == null) return null;
            try {
              return Review.fromJson(reviewJson);
            } catch (e) {
              return null; // 파싱 에러 시 무시
            }
          }).whereType<Review>().toList(); // null 제거
        });
      }
    } catch (e) {
      debugPrint("리뷰 모음 로드 실패: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
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
          _buildReviewList(_myReviews, "작성한 리뷰가 없습니다."),
          _buildReviewList(_likedReviews, "도움이 된다고 표시한 리뷰가 없습니다."),
          const Center(child: Text("댓글 기능 준비 중입니다.")),
        ],
      ),
    );
  }

  Widget _buildReviewList(List<Review> reviews, String emptyMessage) {
    if (reviews.isEmpty) {
      return Center(child: Text(emptyMessage, style: const TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      itemCount: reviews.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
      itemBuilder: (context, index) {
        return ReviewCard(
          review: reviews[index],
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewDetailScreen(review: reviews[index])));
          },
          onTapStore: () {},
        );
      },
    );
  }
}