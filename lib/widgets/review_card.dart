import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/models/ranking_models.dart';
import 'package:needsfine_app/screens/review_detail_screen.dart';
import 'package:needsfine_app/services/review_service.dart';

class ReviewCard extends StatefulWidget {
  final Review review;
  final VoidCallback onTap;
  final VoidCallback onTapStore;

  const ReviewCard({
    super.key,
    required this.review,
    required this.onTap,
    required this.onTapStore,
  });

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isCommentExpanded = false;
  final Set<String> _blockedUserIds = {};

  @override
  void initState() {
    super.initState();
    _likeCount = widget.review.likeCount;
    _checkInitialLikeStatus();
  }

  Future<void> _checkInitialLikeStatus() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final res = await Supabase.instance.client
        .from('review_votes')
        .select()
        .eq('review_id', widget.review.id)
        .eq('user_id', userId)
        .maybeSingle();

    if (mounted && res != null) {
      setState(() => _isLiked = true);
    }
  }

  Future<void> _toggleLike() async {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    try {
      await ReviewService.toggleLike(widget.review.id);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likeCount += _isLiked ? 1 : -1;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("오류가 발생했습니다.")));
      }
    }
  }

  void _toggleComment() {
    setState(() {
      _isCommentExpanded = !_isCommentExpanded;
    });
  }

  void _goToDetail() {
    widget.onTap();
  }

  void _showUserOptionModal(String userId, String nickname) async {
    if (userId == Supabase.instance.client.auth.currentUser?.id) return;

    final myId = Supabase.instance.client.auth.currentUser?.id;
    bool isFollowing = false;

    if (myId != null) {
      final data = await Supabase.instance.client
          .from('follows')
          .select()
          .eq('follower_id', myId)
          .eq('following_id', userId)
          .maybeSingle();
      if (data != null) {
        isFollowing = true;
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[200],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('유저 정보 보기'),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$nickname 님의 피드로 이동합니다.')),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(
                        isFollowing ? Icons.person_remove : Icons.person_add,
                        color: isFollowing ? Colors.red : Colors.black
                    ),
                    title: Text(
                        isFollowing ? '팔로우 취소' : '팔로우 하기',
                        style: TextStyle(color: isFollowing ? Colors.red : Colors.black)
                    ),
                    onTap: () async {
                      if (isFollowing) {
                        await _unfollowUser(userId, nickname);
                      } else {
                        await _followUser(userId, nickname);
                      }
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.block, color: Colors.red),
                    title: const Text('차단하기', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      _blockUser(userId, nickname);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.report, color: Colors.grey),
                    title: const Text('신고하기', style: TextStyle(color: Colors.grey)),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('신고 기능은 추후 도입 예정입니다.')),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _followUser(String targetUserId, String nickname) async {
    try {
      final myId = Supabase.instance.client.auth.currentUser?.id;
      if (myId == null) return;

      await Supabase.instance.client.from('follows').insert({
        'follower_id': myId,
        'following_id': targetUserId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$nickname 님을 팔로우했습니다!')));
      }
    } catch (e) {
      debugPrint("팔로우 에러: $e");
    }
  }

  Future<void> _unfollowUser(String targetUserId, String nickname) async {
    try {
      final myId = Supabase.instance.client.auth.currentUser?.id;
      if (myId == null) return;

      await Supabase.instance.client.from('follows').delete()
          .eq('follower_id', myId)
          .eq('following_id', targetUserId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$nickname 님 팔로우를 취소했습니다.')));
      }
    } catch (e) {
      debugPrint("언팔로우 에러: $e");
    }
  }

  Future<void> _blockUser(String targetUserId, String nickname) async {
    setState(() => _blockedUserIds.add(targetUserId));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$nickname 님을 차단했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color kPrimary = Color(0xFFC87CFF);

    ImageProvider avatarImage;
    if (widget.review.userProfileUrl != null && widget.review.userProfileUrl!.isNotEmpty) {
      avatarImage = NetworkImage(widget.review.userProfileUrl!);
    } else {
      avatarImage = const AssetImage('assets/images/default_profile.png');
    }

    return Material(
      color: const Color(0xFFFFFDF9),
      child: InkWell(
        onTap: _goToDetail,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: widget.onTapStore,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.review.storeName,
                      style: const TextStyle(
                        fontFamily: 'NotoSansKR',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
                  ],
                ),
              ),
              if (widget.review.storeAddress != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2.0, bottom: 12.0),
                  child: Text(
                    widget.review.storeAddress!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                )
              else
                const SizedBox(height: 12),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      if (widget.review.userId != null) {
                        _showUserOptionModal(widget.review.userId!, widget.review.nickname);
                      }
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: avatarImage,
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            if (widget.review.userId != null) {
                              _showUserOptionModal(widget.review.userId!, widget.review.nickname);
                            }
                          },
                          child: Text(
                            widget.review.nickname,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black87
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.grey[400], size: 14),
                            const SizedBox(width: 2),
                            Text(
                              "${widget.review.userRating}",
                              style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "|  사용자 평가",
                              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9C7CFF),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9C7CFF).withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "니즈파인 점수",
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text("NF", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70)),
                            const SizedBox(width: 2),
                            Text(
                              widget.review.needsfineScore.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, height: 1.0),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(width: 30, height: 1, color: Colors.white30),
                        const SizedBox(height: 4),
                        Text(
                          "${widget.review.trustLevel}% 신뢰도",
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                widget.review.reviewText,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),

              if (widget.review.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.review.tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                      child: Text("#$tag", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    )).toList(),
                  ),
                ),

              const SizedBox(height: 16),

              if (widget.review.photoUrls.isNotEmpty)
                Container(
                  height: 150,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.review.photoUrls.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: _goToDetail,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.review.photoUrls[index],
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(width: 150, color: Colors.grey[200], child: const Icon(Icons.broken_image)),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const Divider(height: 24, thickness: 0.5, color: Color(0xFFEEEEEE)),

              Row(
                children: [
                  InkWell(
                    onTap: _toggleLike,
                    child: Row(
                      children: [
                        Icon(
                          _isLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                          size: 18,
                          color: _isLiked ? kPrimary.withOpacity(0.7) : Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "도움이 돼요 $_likeCount",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _isLiked ? FontWeight.bold : FontWeight.normal,
                            color: _isLiked ? kPrimary.withOpacity(0.7) : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  InkWell(
                    onTap: _toggleComment,
                    child: Row(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text("댓글", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.review.createdAt.year}.${widget.review.createdAt.month}.${widget.review.createdAt.day}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                ],
              ),

              if (_isCommentExpanded)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: _goToDetail,
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text("댓글을 입력하세요...", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _goToDetail,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            child: const Text(
                              "댓글 더보기 +",
                              style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}