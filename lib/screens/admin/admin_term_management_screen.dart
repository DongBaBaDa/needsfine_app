import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminTermManagementScreen extends StatefulWidget {
  const AdminTermManagementScreen({super.key});

  @override
  State<AdminTermManagementScreen> createState() => _AdminTermManagementScreenState();
}

class _AdminTermManagementScreenState extends State<AdminTermManagementScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _candidates = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchCandidates();
  }

  Future<void> _fetchCandidates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final res = await _supabase.functions.invoke(
        'make-server-26899706/term-candidates',
        method: HttpMethod.get,
        headers: {'X-Admin-Password': 'needsfine2953'},
      );
      
      if (res.status == 200) {
        setState(() {
          _candidates = res.data ?? [];
        });
      } else {
        setState(() {
          _errorMessage = '서버 오류가 발생했습니다: ${res.status}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '데이터를 불러오는 데 실패했습니다: $e';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAction(String term, String action) async {
    try {
      final res = await _supabase.functions.invoke(
        'make-server-26899706/term-candidates/action',
        method: HttpMethod.post,
        body: {'term': term, 'action': action},
        headers: {'X-Admin-Password': 'needsfine2953'},
      );
      
      if (res.status == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('[$term] 단어가 ${action == 'approve' ? '승인' : '거절'}되었습니다.')),
          );
        }
        _fetchCandidates();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('처리 실패: ${res.status}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('에러 발생: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('단어 풀 관리 (Term Management)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : _candidates.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('새로운 후보 단어가 없습니다.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      )
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _candidates.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _candidates[index];
                        final term = item['term'] ?? '';
                        final count = item['occurrences'] ?? 0;
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.abc, color: Colors.blue),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(term, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text('발견 횟수: $count', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => _handleAction(term, 'reject'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                child: const Text('거절', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _handleAction(term, 'approve'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2D2D3A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('승인', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
