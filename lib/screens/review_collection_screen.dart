// lib/screens/review_collection_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/widgets/review_card.dart';
import 'package:needsfine_app/screens/review_detail_screen.dart';
import 'package:needsfine_app/screens/user_profile_screen.dart';

import 'package:needsfine_app/l10n/app_localizations.dart';

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

  final ScrollController _myReviewsScroll = ScrollController();
  final ScrollController _likedReviewsScroll = ScrollController();
  final ScrollController _commentedReviewsScroll = ScrollController();

  final int _pageSize = 20;
  bool _hasMoreMyReviews = true;
  bool _hasMoreLikedReviews = true;
  bool _hasMoreCommentedReviews = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    _myReviewsScroll.addListener(() {
      if (_myReviewsScroll.position.pixels >= _myReviewsScroll.position.maxScrollExtent - 200 && !_isLoading && _hasMoreMyReviews) {
        _fetchMyReviews(loadMore: true);
      }
    });
    _likedReviewsScroll.addListener(() {
      if (_likedReviewsScroll.position.pixels >= _likedReviewsScroll.position.maxScrollExtent - 200 && !_isLoading && _hasMoreLikedReviews) {
        _fetchLikedReviews(loadMore: true);
      }
    });
    _commentedReviewsScroll.addListener(() {
      if (_commentedReviewsScroll.position.pixels >= _commentedReviewsScroll.position.maxScrollExtent - 200 && !_isLoading && _hasMoreCommentedReviews) {
        _fetchCommentedReviews(loadMore: true);
      }
    });

    _fetchData();
  }

  @override
  void dispose() {
    _myReviewsScroll.dispose();
    _likedReviewsScroll.dispose();
    _commentedReviewsScroll.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchMyReviews(),
      _fetchLikedReviews(),
      _fetchCommentedReviews(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchMyReviews({bool loadMore = false}) async {
    if (!mounted) return;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    if (loadMore) {
      if (!_hasMoreMyReviews) return;
      setState(() => _isLoading = true);
    } else {
      _myReviews.clear();
      _hasMoreMyReviews = true;
    }

    try {
      final data = await _supabase
          .from('reviews')
          .select('*, profiles(*)')
          .eq('user_id', userId)
          .eq('is_hidden', false)
          .order('created_at', ascending: false)
          .range(_myReviews.length, _myReviews.length + _pageSize - 1);

      if (mounted) {
        setState(() {
          final newItems = (data as List).map((json) => Review.fromJson(json)).toList();
          _myReviews.addAll(newItems);
          if (newItems.length < _pageSize) _hasMoreMyReviews = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("내가 쓴 리뷰 로드 실패: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchLikedReviews({bool loadMore = false}) async {
    if (!mounted) return;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    if (loadMore) {
      if (!_hasMoreLikedReviews) return;
      setState(() => _isLoading = true);
    } else {
      _likedReviews.clear();
      _hasMoreLikedReviews = true;
    }

    try {
      final data = await _supabase
          .from('review_votes')
          .select('reviews(*, profiles(*))')
          .eq('user_id', userId)
          .eq('vote_type', 'like')
          .range(_likedReviews.length, _likedReviews.length + _pageSize - 1);

      if (mounted) {
        setState(() {
          final newItems = (data as List).map((item) {
            final reviewJson = item['reviews'];
            if (reviewJson == null) return null;
            try { return Review.fromJson(reviewJson); } catch (e) { return null; }
          }).whereType<Review>().toList();
          
          _likedReviews.addAll(newItems);
          if (newItems.length < _pageSize) _hasMoreLikedReviews = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("좋아요한 리뷰 로드 실패: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchCommentedReviews({bool loadMore = false}) async {
    if (!mounted) return;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;
    
    if (loadMore) {
      if (!_hasMoreCommentedReviews) return;
      setState(() => _isLoading = true);
    } else {
      _commentedReviews.clear();
      _hasMoreCommentedReviews = true;
    }

    try {
      final data = await _supabase
          .from('comments')
          .select('content, created_at, reviews(*, profiles(*))')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(_commentedReviews.length, _commentedReviews.length + _pageSize - 1);

      if (mounted) {
        setState(() {
          final newItems = (data as List).map((item) {
            final reviewJson = item['reviews'];
            if (reviewJson == null) return null;
            final combinedJson = Map<String, dynamic>.from(reviewJson);
            combinedJson['comment_content'] = item['content'];
            combinedJson['comment_created_at'] = item['created_at'];
            return Review.fromJson(combinedJson);
          }).whereType<Review>().toList();
          
          _commentedReviews.addAll(newItems);
          if (newItems.length < _pageSize) _hasMoreCommentedReviews = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("댓글 단 리뷰 로드 실패: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // Light Grey Background
      appBar: AppBar(
        title: Text(l10n.reviewCollection),
        bottom: TabBar(
          controller: _tabController,
          labelColor: kNeedsFinePurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: kNeedsFinePurple,
          tabs: [
            Tab(text: l10n.myReviews),
            Tab(text: l10n.helpfulReviews),
            Tab(text: l10n.commentedReviews),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReviewList(_myReviews, l10n.noReviewsWritten, false, _myReviewsScroll, () => _fetchMyReviews()),
          _buildReviewList(_likedReviews, l10n.noLikedReviews, false, _likedReviewsScroll, () => _fetchLikedReviews()),
          _buildReviewList(_commentedReviews, l10n.noCommentedReviews, true, _commentedReviewsScroll, () => _fetchCommentedReviews()),
        ],
      ),
    );
  }

  Widget _buildReviewList(List<Review> reviews, String emptyMessage, bool isCommentMode, ScrollController controller, Future<void> Function() onRefresh) {
    if (_isLoading && reviews.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (reviews.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: kNeedsFinePurple,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Center(child: Text(emptyMessage, style: const TextStyle(color: Colors.grey))),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: kNeedsFinePurple,
      child: ListView.separated(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16), // Padding all 16
        itemCount: reviews.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12), // Spacing 12
        itemBuilder: (context, index) {
          if (index == reviews.length) {
            bool hasMore = false;
            if (controller == _myReviewsScroll) hasMore = _hasMoreMyReviews;
            if (controller == _likedReviewsScroll) hasMore = _hasMoreLikedReviews;
            if (controller == _commentedReviewsScroll) hasMore = _hasMoreCommentedReviews;
            
            return hasMore
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox(height: 40);
          }
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
      ),
    );
  }

  Review _convertToCommentUi(Review original) {
    return Review(
      id: original.id,
      storeName: original.storeName,
      storeAddress: original.storeAddress,
      reviewText: original.myCommentText ?? "내용 없음",
      userRating: original.userRating,

      // 파라미터 전달 (이미 계산된 값 사용)
      needsfineScore: original.needsfineScore,
      trustLevel: original.trustLevel,
      dbTags: original.tags,
      isCritical: original.isCritical,

      photoUrls: original.photoUrls,
      isHidden: original.isHidden,
      createdAt: original.myCommentCreatedAt ?? original.createdAt,
      userId: original.userId,
      userEmail: original.userEmail,
      likeCount: original.likeCount,
      nickname: original.nickname,
      userProfileUrl: original.userProfileUrl,
      commentCount: original.commentCount,

      // ✅ [수정 완료] 누락되었던 필수 파라미터 추가
      storeLat: original.storeLat ?? 0.0,
      storeLng: original.storeLng ?? 0.0,
    );
  }
}