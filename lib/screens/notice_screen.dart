import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:needsfine_app/core/needsfine_theme.dart';
import 'notice_write_screen.dart'; // ✅ 작성 화면 import

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  final _supabase = Supabase.instance.client;

  // 🔴 관리자 이메일 설정 (기존 유지)
  final String _adminEmail = 'ineedsfine@gmail.com';

  // 디자인 토큰
  static const Color _brand = Color(0xFF8A2BE2);
  static const Color _bg = Colors.white; // ✅ 배경을 완전한 흰색으로 변경 (Clean)

  Future<List<Map<String, dynamic>>> _fetchNotices() async {
    final data = await _supabase
        .from('notices')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  // 관리자인지 확인하는 함수
  bool _isAdmin() {
    final user = _supabase.auth.currentUser;
    return user != null && user.email == _adminEmail;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      // ✅ AppBar: 그림자 없이 깔끔하게, 타이틀을 크고 명확하게
      appBar: AppBar(
        title: const Text(
          "공지사항",
          style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.black,
              fontSize: 20, // 폰트 사이즈 키움
              letterSpacing: -0.5
          ),
        ),
        backgroundColor: _bg,
        elevation: 0,
        centerTitle: false, // 왼쪽 정렬로 변경하여 매거진 느낌 부여
        titleSpacing: 20,   // 왼쪽 여백 확보
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      // ✅ 관리자일 때만 글쓰기 버튼 표시 (유지)
      floatingActionButton: _isAdmin()
          ? FloatingActionButton.extended(
        backgroundColor: _brand,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text("글쓰기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: _brand));
          }
          if (snapshot.hasError) {
            return Center(child: Text("정보를 불러오지 못했습니다.", style: TextStyle(color: Colors.grey[400])));
          }
          final notices = snapshot.data ?? [];

          if (notices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline_rounded, size: 48, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text("아직 등록된 공지사항이 없어요.", style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                ],
              ),
            );
          }

          // ✅ 리스트뷰 디자인 리뉴얼
          return ListView.builder(
            itemCount: notices.length,
            // separatorBuilder 대신 item 내부에서 border를 그리는 방식이 더 깔끔함
            itemBuilder: (context, index) {
              final notice = notices[index];
              final date = DateTime.parse(notice['created_at']);
              final formattedDate = DateFormat('yyyy.MM.dd').format(date);

              // 첫 번째 아이템인지 확인 (상단 라인 처리용)
              final isFirst = index == 0;

              return Column(
                children: [
                  if (isFirst) Divider(height: 1, thickness: 1, color: Colors.grey[100]),

                  // ✅ Theme 위젯을 사용하여 ExpansionTile의 기본 지저분한 선 제거
                  Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      childrenPadding: EdgeInsets.zero,
                      // 펼쳐졌을 때 아이콘과 텍스트 색상
                      iconColor: _brand,
                      collapsedIconColor: Colors.grey[400],
                      textColor: Colors.black,
                      collapsedTextColor: Colors.black87,
                      backgroundColor: Colors.grey[50], // 펼쳐졌을 때 배경색 (아주 연한 회색)

                      // 1. 헤더 (제목 + 날짜)
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // 브랜드 포인트 점 (최신 글 강조 느낌)
                              Container(
                                width: 6, height: 6,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: index == 0 ? _brand : Colors.transparent, // 첫번째 글만 보라색 점
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  notice['title'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.only(left: 14.0), // 점 크기만큼 들여쓰기
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

                      // 2. 내용 (펼쳐지는 부분)
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(38, 0, 24, 32), // 들여쓰기로 계층 구조 표현
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8), // 타이틀과 간격
                              Text(
                                notice['content'],
                                style: const TextStyle(
                                  height: 1.8, // 줄간격 넓게 (가독성)
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

                  // 하단 구분선 (아주 얇게)
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