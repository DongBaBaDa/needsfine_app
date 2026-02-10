import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:needsfine_app/l10n/app_localizations.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'notice_write_screen.dart'; // ✅ 작성 화면 import

import 'package:shared_preferences/shared_preferences.dart';

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  final _supabase = Supabase.instance.client;
  final String _adminEmail = 'ineedsfine@gmail.com';
  
  // Design Tokens
  static const Color _brand = Color(0xFF8A2BE2);
  static const Color _bg = Colors.white;

  // Local State for Read Status
  Set<String> _readNoticeIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReadNotices();
  }

  Future<void> _loadReadNotices() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> readList = prefs.getStringList('read_notices') ?? [];
    if (mounted) {
      setState(() {
        _readNoticeIds = readList.toSet();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String noticeId) async {
    if (_readNoticeIds.contains(noticeId)) return;

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _readNoticeIds.add(noticeId);
    });
    await prefs.setStringList('read_notices', _readNoticeIds.toList());
  }

  // Mark All Read
  Future<void> _markAllAsRead(List<Map<String, dynamic>> notices) async {
    final prefs = await SharedPreferences.getInstance();
    final allIds = notices.map((n) => n['id'].toString()).toList();
    
    setState(() {
      _readNoticeIds.addAll(allIds);
    });
    await prefs.setStringList('read_notices', _readNoticeIds.toList());
  }

  Future<List<Map<String, dynamic>>> _fetchNotices() async {
    final data = await _supabase
        .from('notices')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  bool _isAdmin() {
    final user = _supabase.auth.currentUser;
    return user != null && user.email == _adminEmail;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          l10n.notices,
          style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.black,
              fontSize: 20,
              letterSpacing: -0.5
          ),
        ),
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
           TextButton(
             onPressed: () async {
                final notices = await _fetchNotices(); // Optimally pass from FutureBuilder data if possible, but fetch is quick
                await _markAllAsRead(notices);
             },
             child: Text(l10n.markAllRead, style: const TextStyle(color: Colors.grey, fontSize: 13)),
           ),
           const SizedBox(width: 8),
        ],
      ),

      floatingActionButton: _isAdmin()
          ? FloatingActionButton.extended(
        backgroundColor: _brand,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: Text(l10n.writeNotice, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NoticeWriteScreen()),
          );
          if (result == true) {
            setState(() {});
          }
        },
      )
          : null,

      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchNotices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _readNoticeIds.isEmpty && _isLoading) {
            return const Center(child: CircularProgressIndicator(color: _brand));
          }
          if (snapshot.hasError) {
            return Center(child: Text(l10n.loadFailed, style: TextStyle(color: Colors.grey[400])));
          }
          final notices = snapshot.data ?? [];

          if (notices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline_rounded, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(l10n.noNotices, style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notices.length,
            itemBuilder: (context, index) {
              final notice = notices[index];
              final noticeId = notice['id'].toString();
              final date = DateTime.parse(notice['created_at']);
              final formattedDate = DateFormat('yyyy.MM.dd').format(date);
              final isRead = _readNoticeIds.contains(noticeId);
              final isFirst = index == 0;

              return Column(
                children: [
                  if (isFirst) Divider(height: 1, thickness: 1, color: Colors.grey[100]),

                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      childrenPadding: EdgeInsets.zero,
                      iconColor: _brand,
                      collapsedIconColor: Colors.grey[400],
                      textColor: Colors.black,
                      collapsedTextColor: Colors.black87,
                      backgroundColor: Colors.grey[50], 
                      
                      // ✅ Mark as read when expanded
                      onExpansionChanged: (expanded) {
                        if (expanded) {
                          _markAsRead(noticeId);
                        }
                      },

                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // ✅ Unread Indicator (Red/Brand Dot)
                              if (!isRead)
                                Container(
                                  width: 6, height: 6,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent, // Changed to Red for better visibility or Keep Brand
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  notice['title'],
                                  style: TextStyle(
                                    fontWeight: isRead ? FontWeight.w500 : FontWeight.w800, // Bold if unread
                                    fontSize: 16,
                                    height: 1.4,
                                    color: isRead ? Colors.black87 : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: EdgeInsets.only(left: !isRead ? 14.0 : 0), // Adjust padding based on dot
                            child: Text(
                              formattedDate,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500
                              ),
                            ),
                          ),
                        ],
                      ),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               const SizedBox(height: 8), 
                               Text(
                                notice['content'],
                                style: const TextStyle(
                                  height: 1.8,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.grey[100]),
                ],
              );
            },
          );
        },
      ),
    );
  }
}