import 'package:flutter/material.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'package:needsfine_app/services/feed_service.dart';
import 'package:needsfine_app/screens/feed/feed_list_screen.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';

class FeedCollectionScreen extends StatefulWidget {
  const FeedCollectionScreen({super.key});

  @override
  State<FeedCollectionScreen> createState() => _FeedCollectionScreenState();
}

class _FeedCollectionScreenState extends State<FeedCollectionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _savedFeeds = [];
  List<Map<String, dynamic>> _likedFeeds = [];
  List<Map<String, dynamic>> _commentedFeeds = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final saved = await FeedService.getSavedFeeds();
      final liked = await FeedService.getLikedFeeds();
      final commented = await FeedService.getCommentedFeeds();

      if (mounted) {
        setState(() {
          _savedFeeds = saved;
          _likedFeeds = liked;
          _commentedFeeds = commented;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: Text(l10n.myFeed), // Using 'My Feed' or similar key
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          labelColor: kNeedsFinePurple,
          unselectedLabelColor: Colors.grey,
          indicatorColor: kNeedsFinePurple,
          tabs: [
            Tab(text: l10n.savedStores), // Reusing 'Saved Stores' key or similar for 'Saved'
            Tab(text: l10n.helpful),     // Helpful (Liked)
            Tab(text: l10n.comments),    // Comments
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_savedFeeds, l10n.noSavedStoresHint), // Placeholder hint
                _buildList(_likedFeeds, l10n.noLikedReviews),    // Placeholder hint
                _buildList(_commentedFeeds, l10n.noCommentedReviews), // Placeholder hint
              ],
            ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> posts, String emptyMessage) {
    if (posts.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final post = posts[index];
        // Ensure ID is int
        if (post['id'] is! int) {
           return const SizedBox.shrink(); 
        }
        
        return FeedPostCard(
          post: post,
          onDelete: (id) {
            setState(() {
              posts.removeWhere((p) => p['id'] == id);
            });
          },
        );
      },
    );
  }
}
