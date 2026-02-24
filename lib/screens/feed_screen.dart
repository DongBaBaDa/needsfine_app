
import 'package:flutter/material.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';
import 'package:needsfine_app/screens/feed/feed_write_screen.dart';
import 'package:needsfine_app/screens/feed/feed_list_screen.dart';
import 'package:needsfine_app/widgets/draggable_fab.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _refreshKey = 0; // Trigger rebuild/refresh

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openFeedWriteScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FeedWriteScreen()),
    );
    if (result == true && mounted) {
      setState(() => _refreshKey++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // labels: 팔로잉 / 전체 / 내주변
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFC87CFF), // Primary color
          indicatorWeight: 3,
          isScrollable: false, // 3 tabs fit screen
          tabs: [
            Tab(text: l10n.all),
            Tab(text: l10n.following),
            Tab(text: l10n.nearMe),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              TabBarView(
                controller: _tabController,
                children: [
                  FeedListScreen(key: ValueKey("all-$_refreshKey"), filter: FeedFilter.all),
                  FeedListScreen(key: ValueKey("following-$_refreshKey"), filter: FeedFilter.following),
                  FeedListScreen(key: ValueKey("nearMe-$_refreshKey"), filter: FeedFilter.nearMe),
                ],
              ),
              DraggableFloatingActionButton(
                heroTag: 'feed_write_fab',
                initialOffset: Offset(constraints.maxWidth - 80, constraints.maxHeight - 100), 
                parentHeight: constraints.maxHeight,
                onPressed: _openFeedWriteScreen,
                child: const Icon(Icons.edit, color: Colors.white),
              ),
            ],
          );
        }
      ),
      // floatingActionButton: Removed in favor of Draggable
    );
  }
}
