// lib/screens/store_management_screen.dart
// 관리자 전용 매장 관리 화면 — 오피셜 등록 요청 확인 + 매장 목록 관리
import 'package:flutter/material.dart';
import 'package:needsfine_app/screens/admin/store_edit_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoreManagementScreen extends StatefulWidget {
  const StoreManagementScreen({super.key});

  @override
  State<StoreManagementScreen> createState() => _StoreManagementScreenState();
}

class _StoreManagementScreenState extends State<StoreManagementScreen> with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  List<Map<String, dynamic>> _storeRequests = [];
  List<Map<String, dynamic>> _officialStores = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 오피셜 등록 요청 (store_registration_requests 테이블)
      // profiles 테이블과의 FK 연결이 없으면 에러가 날 수 있으므로, 
      // 일단 user_id로 profiles를 별도로 가져오거나, FK가 있다면 join 사용.
      // 여기서는 안전하게 join을 시도하되, 실패하면 단순 쿼리로 fallback 하거나 
      // SQL에서 FK를 profiles로 수정하는 것이 좋음. 
      // (시스템상 profiles가 auth.users를 참조하므로 1:1이지만 PostgREST는 명시적 FK 필요)
      
      // 일단 지금은 에러 방지를 위해 단순 조회 후 매핑 (또는 user_id로 개별 조회 - 비효율적이지만 안전)
      // 하지만 가장 좋은 건 SQL 고치기. 일단 UI 로직부터 잡는다.
      
      final requests = await _supabase
          .from('store_registration_requests')
          .select('*, profiles:user_id(nickname, email)')
          .eq('status', 'pending')
          .order('created_at', ascending: false);
          
      _storeRequests = List<Map<String, dynamic>>.from(requests);

      // 등록된 오피셜 매장 목록
      final stores = await _supabase
          .from('stores')
          .select()
          .eq('is_official', true)
          .order('created_at', ascending: false);
      _officialStores = List<Map<String, dynamic>>.from(stores);
    } catch (e) {
      debugPrint("매장 관리 데이터 로드 실패: $e");
      // 혹시 profiles join 실패일 수 있으니 재시도 (join 없이)
      if (e.toString().contains("profiles")) {
         try {
           final requests = await _supabase
            .from('store_registration_requests')
            .select()
            .eq('status', 'pending')
            .order('created_at', ascending: false);
           _storeRequests = List<Map<String, dynamic>>.from(requests);
         } catch (e2) {
            debugPrint("매장 관리 데이터 로드 실패 (재시도): $e2");
         }
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  // 오피셜 매장으로 직접 등록 (요청 승인)
  Future<void> _approveRequest(Map<String, dynamic> request) async {
    final storeName = request['store_name'] ?? '';
    final storeAddress = request['store_address'] ?? request['store_road_address'] ?? '';
    final lat = request['store_lat'] ?? 0.0;
    final lng = request['store_lng'] ?? 0.0;
    final requestId = request['id'];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('오피셜 매장 등록 승인'),
        content: Text('\'$storeName\'을(를) 오피셜 매장으로 등록하시겠습니까?\n\n주소: $storeAddress'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D2D3A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('승인', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // 1. 매장 등록
      await _supabase.from('stores').insert({
        'name': storeName,
        'address': storeAddress,
        'lat': lat,
        'lng': lng,
        'is_official': true,
        'registered_by': _supabase.auth.currentUser?.id,
        'description': request['store_intro'], 
        'phone_number': request['store_phone'],
        // New enhanced fields
        'images': request['store_images'], // Array
        'menu': request['store_menu_new'], // JSONB
        'business_hours_data': request['store_hours_new'], // JSONB
        // Legacy support if needed
        'business_hours': request['store_hours'], 
      });

      // 2. 요청 상태 업데이트 (승인됨)
      await _supabase.from('store_registration_requests').update({
        'status': 'approved'
      }).eq('id', requestId);

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$storeName이(가) 오피셜 매장으로 등록되었습니다 ✅')),
        );
      }
    } catch (e) {
      debugPrint("매장 승인 실패: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('등록 처리에 실패했습니다: $e')),
        );
      }
    }
  }

  // 요청 거절
  Future<void> _rejectRequest(Map<String, dynamic> request) async {
    final requestId = request['id'];
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('요청 거절'),
        content: const Text('이 등록 요청을 거절하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('거절', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // 상태 업데이트 (거절됨)
      await _supabase.from('store_registration_requests').update({
        'status': 'rejected'
      }).eq('id', requestId);
      
      await _loadData();
    } catch (e) {
      debugPrint("요청 거절 실패: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('거절 처리에 실패했습니다: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        title: const Text('매장 관리', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D2D3A),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2D2D3A),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2D2D3A),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            Tab(text: '등록 요청 (${_storeRequests.length})'),
            Tab(text: '오피셜 매장 (${_officialStores.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D2D3A)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsTab(),
                _buildOfficialStoresTab(),
              ],
            ),
    );
  }

  Widget _buildRequestsTab() {
    if (_storeRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('대기 중인 등록 요청이 없습니다', style: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF8A2BE2),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        itemCount: _storeRequests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final req = _storeRequests[index];
          final nickname = req['profiles']?['nickname'] ?? '사용자';
          final storeName = req['store_name'] ?? '이름 없음';
          final storeAddress = req['store_address'] ?? req['store_road_address'] ?? '주소 없음';
          final date = req['created_at']?.toString().substring(0, 10) ?? '';
          final contact = req['store_phone'] ?? '';

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8A2BE2).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('승인 대기', style: TextStyle(fontSize: 12, color: Color(0xFF8A2BE2), fontWeight: FontWeight.w700)),
                          ),
                          Text(date, style: TextStyle(fontSize: 13, color: Colors.grey[400], fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(storeName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2D2D3A))),
                      const SizedBox(height: 6),
                      Text(storeAddress, style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4)),
                      if (contact.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone_rounded, size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(contact, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F9FB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                             const Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey),
                             const SizedBox(width: 8),
                             Text('요청자: $nickname', style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF2F2F7))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _rejectRequest(req),
                            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              alignment: Alignment.center,
                              child: const Text('거절', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 15)),
                            ),
                          ),
                        ),
                      ),
                      Container(width: 1, height: 20, color: const Color(0xFFF2F2F7)),
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _approveRequest(req),
                            borderRadius: const BorderRadius.only(bottomRight: Radius.circular(20)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              alignment: Alignment.center,
                              child: const Text('승인', style: TextStyle(color: Color(0xFF8A2BE2), fontWeight: FontWeight.w700, fontSize: 15)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 매장 삭제
  Future<void> _deleteStore(String storeId, String storeName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('매장 삭제'),
        content: Text("'$storeName' 매장을 정말 삭제하시겠습니까?\n삭제 후에는 복구할 수 없습니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabase.from('stores').delete().eq('id', storeId);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('매장이 삭제되었습니다.')),
          );
        }
      } catch (e) {
        debugPrint("매장 삭제 실패: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('삭제 실패: $e')),
          );
        }
      }
    }
  }

  // 매장 정보 수정 (오피셜 매장 탭) - 새로운 전체 수정 화면으로 이동
  Future<void> _editStore(Map<String, dynamic> store) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoreEditScreen(storeData: store),
      ),
    );

    if (result == true) {
      _loadData(); // 수정 후 데이터 갱신
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 15, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF8A2BE2), size: 20),
        filled: true,
        fillColor: const Color(0xFFF9F9FB),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8A2BE2)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildOfficialStoresTab() {
    if (_officialStores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_mall_directory_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('등록된 오피셜 매장이 없습니다', style: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF8A2BE2),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        itemCount: _officialStores.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final store = _officialStores[index];
          return GestureDetector(
            onTap: () => _editStore(store), // 탭하면 수정 다이얼로그
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E5F5), // Light Purple
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.verified_rounded, color: Color(0xFF8A2BE2), size: 24), // Purple Icon
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(store['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF2D2D3A))),
                        const SizedBox(height: 4),
                        Text(store['address'] ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(Icons.edit_rounded, size: 20, color: Colors.grey[400]),
                      const SizedBox(height: 6),
                      Text('조회 ${store['view_count'] ?? 0}', style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
