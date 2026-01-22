// 파일 이름: lib/screens/store_reviews_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ Review 충돌 방지: app_data에서는 Store만 가져오기
import 'package:needsfine_app/models/app_data.dart' show Store;

// ✅ Review는 ranking_models의 Review만 사용
import 'package:needsfine_app/models/ranking_models.dart' show Review;

import 'package:needsfine_app/widgets/review_card.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';

import 'package:needsfine_app/screens/notice_screen.dart';
import 'package:needsfine_app/screens/user_profile_screen.dart';

enum StoreReviewFilter { latest, needsfineHigh, trustHigh, bitter }

class StoreReviewsScreen extends StatefulWidget {
  final Store store;

  const StoreReviewsScreen({super.key, required this.store});

  @override
  State<StoreReviewsScreen> createState() => _StoreReviewsScreenState();
}

class _StoreReviewsScreenState extends State<StoreReviewsScreen> {
  final SupabaseClient _sb = Supabase.instance.client;

  bool _loading = true;
  bool _paging = false;

  StoreReviewFilter _filter = StoreReviewFilter.latest;

  // 헤더
  int _totalReviewCount = 0;
  int _storeSaveCount = 0;
  double _avgNeedsFine = 0.0;

  // ✅ 타입 명시
  List<Review> _reviews = <Review>[];

  // 페이징
  final int _pageSize = 20;
  int _page = 0;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  // ---- 유틸: 안전 문자열/리스트 변환 ----
  String _s(dynamic v, [String fallback = ""]) {
    if (v == null) return fallback;
    return v.toString();
  }

  double _d(dynamic v, [double fallback = 0.0]) {
    if (v is num) return v.toDouble();
    final parsed = double.tryParse(_s(v));
    return parsed ?? fallback;
  }

  int _i(dynamic v, [int fallback = 0]) {
    if (v is num) return v.toInt();
    final parsed = int.tryParse(_s(v));
    return parsed ?? fallback;
  }

  List<String> _strList(dynamic v) {
    if (v is List) {
      return v.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
    }
    return <String>[];
  }

  // 프로필 join 결과에서 nickname 추출 (object or list 모두 대응)
  String _nicknameFromProfiles(dynamic profiles) {
    if (profiles is Map) {
      final n = profiles['nickname'];
      if (n != null && n.toString().trim().isNotEmpty) return n.toString();
    }
    if (profiles is List && profiles.isNotEmpty) {
      final first = profiles.first;
      if (first is Map) {
        final n = first['nickname'];
        if (n != null && n.toString().trim().isNotEmpty) return n.toString();
      }
    }
    return "익명 사용자";
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _page = 0;
      _hasMore = true;
      _reviews = <Review>[];
    });

    try {
      await Future.wait([
        _loadHeaderMetrics(),
        _loadReviews(reset: true),
      ]);
    } catch (e, st) {
      // ✅ 여기서 스택트레이스까지 찍혀야 “정확히 어느 줄에서 bool 캐스팅” 터지는지 확정 가능
      debugPrint("StoreReviews reload error: $e");
      debugPrint("StoreReviews reload stack:\n$st");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("리뷰 로딩 중 오류가 발생했습니다.")),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _loadHeaderMetrics() async {
    final storeName = widget.store.name;
    final storeAddr = (widget.store.address ?? "").trim();

    // ✅ 핵심: is_hidden을 “select로 가져오지 않는다”
    // 숨김 제외는 WHERE 쿼리에서만 처리 (null/false만 포함)
    final rows = await _sb
        .from('reviews')
        .select('needsfine_score')
        .eq('store_name', storeName)
        .or('is_hidden.is.null,is_hidden.eq.false');

    final list = (rows is List) ? rows : <dynamic>[];

    int cnt = list.length;
    double sumNF = 0.0;

    for (final r in list) {
      final m = (r is Map) ? r : <dynamic, dynamic>{};
      sumNF += _d(m['needsfine_score'], 0.0);
    }

    final avg = (cnt == 0) ? 0.0 : (sumNF / cnt);

    // ✅ 저장됨 수: (기존 로직 유지) 이름/주소 기반
    dynamic savesRows;
    if (storeAddr.isNotEmpty) {
      savesRows = await _sb
          .from('store_saves')
          .select('id')
          .eq('store_name', storeName)
          .eq('store_address', storeAddr);
    } else {
      savesRows = await _sb
          .from('store_saves')
          .select('id')
          .eq('store_name', storeName);
    }
    final saveCount = (savesRows is List) ? savesRows.length : 0;

    if (!mounted) return;
    setState(() {
      _totalReviewCount = cnt;
      _avgNeedsFine = avg;
      _storeSaveCount = saveCount;
    });
  }

  Future<void> _loadMoreIfNeeded() async {
    if (_paging || !_hasMore) return;
    setState(() => _paging = true);

    try {
      await _loadReviews(reset: false);
    } finally {
      if (mounted) setState(() => _paging = false);
    }
  }

  Future<void> _loadReviews({required bool reset}) async {
    final storeName = widget.store.name;

    // ✅ 핵심: reviews 테이블에 없는 컬럼(nickname/user_profile_url 등) 직접 select 금지
    // nickname은 profiles join으로만 가져옴
    // ✅ 핵심2: is_hidden을 select로 가져오지 않고, 쿼리 조건으로만 숨김 제외 처리
    dynamic query = _sb
        .from('reviews')
        .select('''
          id,
          user_id,
          store_name,
          store_address,
          review_text,
          user_rating,
          needsfine_score,
          trust_level,
          photo_urls,
          tags,
          like_count,
          comment_count,
          created_at,
          store_lat,
          store_lng,
          profiles:profiles ( nickname )
        ''')
        .eq('store_name', storeName);

    // 필터별 조건
    switch (_filter) {
      case StoreReviewFilter.latest:
      // 숨김 제외: null/false만 포함
        query = query.or('is_hidden.is.null,is_hidden.eq.false');
        query = query.order('created_at', ascending: false);
        break;

      case StoreReviewFilter.needsfineHigh:
        query = query.or('is_hidden.is.null,is_hidden.eq.false');
        query = query.order('needsfine_score', ascending: false).order('created_at', ascending: false);
        break;

      case StoreReviewFilter.trustHigh:
        query = query.or('is_hidden.is.null,is_hidden.eq.false');
        query = query.order('trust_level', ascending: false).order('created_at', ascending: false);
        break;

      case StoreReviewFilter.bitter:
      // ✅ (숨김 제외) AND (user_rating<=3 OR needsfine_score<=6)
      // PostgREST는 or= 파라미터 1개에 and(...)를 조합해 해결
        query = query.or(
          'and(is_hidden.is.null,user_rating.lte.3),'
              'and(is_hidden.is.null,needsfine_score.lte.6),'
              'and(is_hidden.eq.false,user_rating.lte.3),'
              'and(is_hidden.eq.false,needsfine_score.lte.6)',
        );
        query = query.order('needsfine_score', ascending: true).order('created_at', ascending: false);
        break;
    }

    final from = _page * _pageSize;
    final to = from + _pageSize - 1;

    final rows = await query.range(from, to);
    final list = (rows is List) ? rows : <dynamic>[];

    final List<Review> mapped = <Review>[];

    for (final r in list) {
      final m = (r is Map) ? r : <dynamic, dynamic>{};
      mapped.add(_mapToReview(m));
    }

    if (!mounted) return;

    setState(() {
      if (reset) {
        _reviews = mapped;
      } else {
        _reviews.addAll(mapped);
      }

      if (list.length < _pageSize) {
        _hasMore = false;
      } else {
        _page += 1;
      }
    });
  }

  Review _mapToReview(Map m) {
    final nickname = _nicknameFromProfiles(m['profiles']);

    return Review(
      id: _s(m['id']),
      storeName: _s(m['store_name']),
      storeAddress: _s(m['store_address']),
      reviewText: _s(m['review_text']),
      userRating: _d(m['user_rating'], 0.0),
      photoUrls: _strList(m['photo_urls']),
      userId: _s(m['user_id']),
      nickname: nickname,

      // ✅ reviews에 user_profile_url 컬럼이 없으니 null로 고정
      userProfileUrl: null,

      storeLat: _d(m['store_lat'], 0.0),
      storeLng: _d(m['store_lng'], 0.0),
      createdAt: DateTime.tryParse(_s(m['created_at'])) ?? DateTime.now(),
      likeCount: _i(m['like_count'], 0),
      commentCount: _i(m['comment_count'], 0),

      needsfineScore: (m['needsfine_score'] is num) ? (m['needsfine_score'] as num).toDouble() : null,
      trustLevel: (m['trust_level'] is num) ? (m['trust_level'] as num).toInt() : null,

      tags: _strList(m['tags']),
    );
  }

  String _filterLabel(StoreReviewFilter f) {
    switch (f) {
      case StoreReviewFilter.latest:
        return "최신순";
      case StoreReviewFilter.needsfineHigh:
        return "니즈파인 점수순";
      case StoreReviewFilter.trustHigh:
        return "신뢰도순";
      case StoreReviewFilter.bitter:
        return "쓴소리";
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(widget.store.name, style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black)),
        actions: [
          IconButton(
            tooltip: "새로고침",
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
          ),
          IconButton(
            tooltip: "알림",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NoticeScreen()));
            },
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.black87),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
            _loadMoreIfNeeded();
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: () async => _reload(),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _HeaderSummaryCard(
                  totalReviews: _totalReviewCount,
                  storeSaves: _storeSaveCount,
                  avgNeedsFine: _avgNeedsFine,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _FilterBar(
                  current: _filter,
                  onChanged: (next) async {
                    setState(() => _filter = next);
                    await _reload();
                  },
                  labelBuilder: _filterLabel,
                ),
              ),
              const SizedBox(height: 6),

              if (_reviews.isEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text("아직 등록된 ${l10n.review}가 없습니다.",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      const Text("첫 번째 리뷰를 기다리고 있어요.", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              else
                ..._reviews.map((Review r) {
                  return ReviewCard(
                    review: r,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(r.nickname),
                          content: SingleChildScrollView(child: Text(r.reviewText)),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text("닫기")),
                          ],
                        ),
                      );
                    },
                    onTapStore: () {},
                    onTapProfile: () {
                      if (r.userId.isEmpty) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => UserProfileScreen(userId: r.userId)),
                      );
                    },
                  );
                }).toList(),

              if (_paging) ...[
                const SizedBox(height: 14),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderSummaryCard extends StatelessWidget {
  final int totalReviews;
  final int storeSaves;
  final double avgNeedsFine;

  const _HeaderSummaryCard({
    required this.totalReviews,
    required this.storeSaves,
    required this.avgNeedsFine,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Expanded(child: _MetricTile(label: "총 리뷰", value: "$totalReviews", valueColor: Colors.black87)),
          const SizedBox(width: 10),
          Expanded(child: _MetricTile(label: "저장됨", value: "$storeSaves", valueColor: const Color(0xFF7C4DFF))),
          const SizedBox(width: 10),
          // ✅ 요청: 평균 NF → 평균 니즈파인
          Expanded(child: _MetricTile(label: "평균 니즈파인", value: avgNeedsFine.toStringAsFixed(1), valueColor: const Color(0xFF7C4DFF))),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MetricTile({required this.label, required this.value, required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F4FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E2FF)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black.withOpacity(0.55), height: 1.1)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: valueColor, height: 1.0)),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final StoreReviewFilter current;
  final ValueChanged<StoreReviewFilter> onChanged;
  final String Function(StoreReviewFilter) labelBuilder;

  const _FilterBar({
    required this.current,
    required this.onChanged,
    required this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final items = StoreReviewFilter.values;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF7C4DFF)),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: items.map((f) {
                  final selected = f == current;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        labelBuilder(f),
                        style: TextStyle(fontWeight: FontWeight.w800, color: selected ? Colors.white : const Color(0xFF7C4DFF)),
                      ),
                      selected: selected,
                      onSelected: (_) => onChanged(f),
                      selectedColor: const Color(0xFF7C4DFF),
                      backgroundColor: const Color(0xFFF0E9FF),
                      side: BorderSide(color: selected ? const Color(0xFF7C4DFF) : const Color(0xFFE8E2FF)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
