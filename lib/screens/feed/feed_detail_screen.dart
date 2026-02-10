import 'package:flutter/material.dart';
import 'package:needsfine_app/services/feed_service.dart';
import 'package:needsfine_app/widgets/report_dialog.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/screens/user_profile_screen.dart';
import 'package:needsfine_app/screens/feed/feed_write_screen.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';

class FeedDetailScreen extends StatefulWidget {
  final Map<String, dynamic> post;

  const FeedDetailScreen({super.key, required this.post});

  @override
  State<FeedDetailScreen> createState() => _FeedDetailScreenState();
}

class _FeedDetailScreenState extends State<FeedDetailScreen> {
  late Map<String, dynamic> _post;
  bool _isLiked = false;
  bool _isSaved = false;
  int _likeCount = 0;
  List<Map<String, dynamic>> _votes = [];
  int? _myVoteIndex;
  int? _selectedOptionIndex;
  bool _isLoading = false;
  bool _isVoteLoading = false;

  // Comments
  List<Map<String, dynamic>> _comments = [];
  final TextEditingController _commentController = TextEditingController();
  bool _isCommentLoading = true;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _initPostState();
    _fetchComments();
    _incrementViewCount();
  }

  Future<void> _incrementViewCount() async {
    try {
      await FeedService.incrementViewCount(_post['id']);
    } catch (e) {
      debugPrint("조회수 증가 실패: $e");
    }
  }

  void _initPostState() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final myLike = _post['my_like'] as List?;
    final mySave = _post['my_save'] as List?;
    _isLiked = myLike != null && myLike.isNotEmpty;
    _isSaved = mySave != null && mySave.isNotEmpty;
    _likeCount = (_post['post_likes'] as List?)?.fold(0, (sum, item) => (sum as int) + (item['count'] as int)) ?? 0;
    
    final rawVotes = _post['post_votes'] as List?;
    _votes = List<Map<String, dynamic>>.from(rawVotes ?? []);
    
    // Check if I voted
    if (userId != null && _votes.isNotEmpty) {
      try {
        final myVote = _votes.firstWhere((v) => v['user_id'] == userId, orElse: () => {});
        if (myVote.isNotEmpty) {
          _myVoteIndex = myVote['option_index'];
        } else {
             _myVoteIndex = null;
        }
      } catch (e) {
        _myVoteIndex = null;
      }
    }
  }

  Future<void> _fetchComments() async {
    try {
      final comments = await FeedService.getComments(_post['id']);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isCommentLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isCommentLoading = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    _commentController.clear();
    FocusScope.of(context).unfocus();

    try {
      await FeedService.createComment(_post['id'], text);
      _fetchComments(); // Refresh comments
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('댓글 등록 실패: $e')));
    }
  }

  Future<void> _toggleLike() async {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
    try {
      await FeedService.toggleLike(_post['id']);
    } catch (e) {
      // Revert if needed
    }
  }

  Future<void> _toggleSave() async {
    setState(() {
      _isSaved = !_isSaved;
    });
    try {
      await FeedService.toggleSave(_post['id']);
      if (mounted) {
         if (_isSaved) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.saved)));
         }
      }
    } catch (e) {
      // Revert if error
      setState(() => _isSaved = !_isSaved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String type = _post['post_type'];
    final profile = _post['profiles'] as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (_post['user_id'] == Supabase.instance.client.auth.currentUser?.id)
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {
               // Show Action Sheet
               showModalBottomSheet(
                 context: context, 
                 backgroundColor: Colors.transparent,
                 builder: (context) => _buildActionSheet(context)
               );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(profile),
                  const SizedBox(height: 20),
                  _buildContent(type),
                  if ((_post['image_urls'] as List?)?.isNotEmpty ?? false)
                    _buildImages(_post['image_urls'].cast<String>()),
                  if (type == 'vote') 
                    Padding(
                      padding: const EdgeInsets.only(top: 40), // Increased spacing
                      child: _buildVoteUI(),
                    ),
                  const SizedBox(height: 20),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        "${AppLocalizations.of(context)!.viewCount} ${_post['view_count'] ?? 0}",
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildStats(),
                  const Divider(height: 32),
                  _buildCommentsList(),
                ],
              ),
            ),
          ),
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> profile) {
    final timeStr = DateFormat('MM/dd HH:mm').format(DateTime.parse(_post['created_at']).toLocal());
    final type = _post['post_type'];

    return Row(
      children: [
        GestureDetector(
          onTap: () {
            // Navigate to User Profile
            Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: _post['user_id'])));
          },
          child: CircleAvatar(
            backgroundColor: Colors.grey[200],
            backgroundImage: profile['profile_image_url'] != null ? NetworkImage(profile['profile_image_url']) : null,
            radius: 20,
            child: profile['profile_image_url'] == null ? const Icon(Icons.person, color: Colors.grey) : null,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(profile['nickname'] ?? '알 수 없음', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(timeStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        const Spacer(),
        _buildTypeBadge(type),
      ],
    );
  }

  Widget _buildContent(String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_post['store_name'] != null)
           Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                const Icon(Icons.store_rounded, size: 20, color: Color(0xFFC87CFF)),
                const SizedBox(width: 8),
                Text(_post['store_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFC87CFF))),
              ],
            ),
          ),
        Text(_post['content'] ?? '', style: const TextStyle(fontSize: 16, height: 1.6)),
      ],
    );
  }

  Widget _buildImages(List<String> images) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        children: images.map((url) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(url, fit: BoxFit.cover, width: double.infinity),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    Color color;
    String text;
    switch (type) {
      case 'recommendation': color = const Color(0xFFC87CFF); text = "맛집 정보"; break;
      case 'question': color = Colors.blue; text = "질문"; break;
      case 'vote': color = Colors.orange; text = "투표"; break;
      default: color = Colors.grey; text = "일반";
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _refreshPost() async {
    final updatedPost = await FeedService.getPostById(_post['id']);
    if (updatedPost != null && mounted) {
      setState(() {
        _post = updatedPost;
        _initPostState();
      });
    }
  }

  Future<void> _vote() async {
    if (_selectedOptionIndex == null) return;
    if (_myVoteIndex != null) return; // Already voted

    setState(() => _isVoteLoading = true);

    try {
      await FeedService.vote(_post['id'], _selectedOptionIndex!);
      await _refreshPost();
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("투표 실패")));
    } finally {
      if(mounted) setState(() => _isVoteLoading = false);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("게시물 삭제"),
        content: const Text("정말로 삭제하시겠습니까?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("취소")),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Close dialog
              try {
                await FeedService.deletePost(_post['id']);
                if (mounted) Navigator.pop(context, true); // Return to list with refresh signal
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("삭제 실패: $e")));
              }
            },
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteUI() {
    final List<dynamic> options = _post['vote_options'] ?? [];
    if (options.isEmpty) return const SizedBox.shrink();

    // Already voted?
    bool hasVoted = _myVoteIndex != null;

    if (hasVoted) {
      // --- Result View (Original style) ---
      Map<int, int> counts = {};
      for (var v in _votes) {
        int idx = v['option_index'];
        counts[idx] = (counts[idx] ?? 0) + 1;
      }
      int total = _votes.length;

      return Column(
        children: [
          ...options.asMap().entries.map((entry) {
            int idx = entry.key;
            String text = entry.value;
            int count = counts[idx] ?? 0;
            double percent = total == 0 ? 0 : count / total;
            bool isSelected = _myVoteIndex == idx;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 56,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFC87CFF).withOpacity(0.1) : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? const Color(0xFFC87CFF) : Colors.grey[200]!),
              ),
              child: Stack(
                children: [
                   FractionallySizedBox(
                    widthFactor: percent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFC87CFF).withOpacity(0.2) : Colors.grey[300],
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(text, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? const Color(0xFFC87CFF) : Colors.black87))),
                          Text("${(percent * 100).toStringAsFixed(0)}% ($count)", style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFFC87CFF) : Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: null, // Disabled
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[400],
                disabledBackgroundColor: Colors.grey[400],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text("투표완료", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    } else {
      // --- Selection View (Select -> Vote Button) ---
      return Column(
        children: [
          ...options.asMap().entries.map((entry) {
            int idx = entry.key;
            String text = entry.value;
            bool isSelected = _selectedOptionIndex == idx;

            return GestureDetector(
              onTap: () => setState(() => _selectedOptionIndex = idx),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFC87CFF).withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFC87CFF) : Colors.grey[300]!, 
                    width: isSelected ? 2 : 1
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isSelected ? const Color(0xFFC87CFF) : Colors.grey[400],
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(text, style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFFC87CFF) : Colors.black87))),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _selectedOptionIndex != null && !_isVoteLoading ? _vote : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC87CFF),
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isVoteLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text("투표하기", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildStats() {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center, 
        children: [
          _buildActionButton(
            label: l10n.helpful,
            isActive: _isLiked,
            icon: _isLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
            activeColor: const Color(0xFFC87CFF),
            onTap: _toggleLike,
            count: _likeCount,
          ),
          const SizedBox(width: 20),
          _buildActionButton(
            label: l10n.save,
            isActive: _isSaved,
            icon: _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            activeColor: const Color(0xFFC87CFF),
            onTap: _toggleSave,
          ),
          const SizedBox(width: 20),
          _buildActionButton(
            label: "신고하기",
            isActive: false,
            icon: Icons.campaign_outlined,
            activeColor: Colors.red,
            onTap: () {
               showDialog(context: context, builder: (_) => ReportDialog(targetType: 'post', targetId: _post['id']));
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required String label,
    required bool isActive,
    required IconData icon,
    required Color activeColor,
    required VoidCallback onTap,
    int? count,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Icon(icon, size: 28, color: isActive ? activeColor : Colors.grey[400]), // Increased size
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? activeColor : Colors.grey[500],
                    fontWeight: FontWeight.w600,
                    fontSize: 14, // Increased size
                  ),
                ),
                if (count != null && count > 0)
                  Text(" $count", style: TextStyle(color: isActive ? activeColor : Colors.grey[500], fontWeight: FontWeight.bold, fontSize: 13)), // Increased size
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsList() {
    if (_isCommentLoading) return const Center(child: CircularProgressIndicator());
    if (_comments.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("첫 번째 댓글을 남겨보세요!", style: TextStyle(color: Colors.grey))));
    
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _comments.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final comment = _comments[index];
        final profile = comment['profiles'] as Map<String, dynamic>;
        final date = DateTime.parse(comment['created_at']).toLocal();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             GestureDetector(
               onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileScreen(userId: comment['user_id']))),
               child: CircleAvatar(
                backgroundImage: profile['profile_image_url'] != null ? NetworkImage(profile['profile_image_url']) : null,
                radius: 16,
                backgroundColor: Colors.grey[200],
                child: profile['profile_image_url'] == null ? const Icon(Icons.person, size: 16, color: Colors.grey) : null,
               ),
             ),
             const SizedBox(width: 12),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(children: [
                     Text(profile['nickname'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                     const SizedBox(width: 8),
                     Text(DateFormat('MM/dd HH:mm').format(date), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                   ]),
                   const SizedBox(height: 4),
                   Text(comment['content'], style: const TextStyle(fontSize: 14)),
                 ],
               ),
             ),
          ],
        );
      },
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))], // Slight shadow
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: "댓글을 입력하세요...",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: Color(0xFFC87CFF)),
              onPressed: _submitComment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionSheet(BuildContext context) {
    final isAuthor = _post['user_id'] == Supabase.instance.client.auth.currentUser?.id;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            if (isAuthor) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.grey),
                title: const Text("수정하기"),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => FeedWriteScreen(post: _post))
                  );
                  if (result == true) {
                    _refreshPost();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text("삭제하기", style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete();
                },
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
