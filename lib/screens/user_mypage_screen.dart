import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'profile_edit_screen.dart';
import 'dart:math';

class UserMyPageScreen extends StatefulWidget {
  const UserMyPageScreen({super.key});

  @override
  State<UserMyPageScreen> createState() => _UserMyPageScreenState();
}

class _UserMyPageScreenState extends State<UserMyPageScreen> {
  late UserProfile _userProfile;

  @override
  void initState() {
    super.initState();

    // 레벨1 + 경험치 초기화
    _userProfile = UserProfile(
      nickname: "니즈파인",
      title: "맛잘알🔥",
      level: 1,
      currentExp: 0,
      maxExp: 100,
      introduction: "'안녕하세요', '니즈파인입니다'.",
      influence: 12345,
      points: 17231,
      profileImagePath: null,
    );
  }

  // 프로필 편집 이동
  Future<void> _navigateAndEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditScreen(currentProfile: _userProfile),
      ),
    );
    if (result != null) {
      setState(() => _userProfile = result);
    }
  }

  // 화면 없는 경우 기본 템플릿 이동
  void _goToPlaceholderPage(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: Center(
            child: Text(
              "$title 화면 (추후 개발 예정)",
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 톱니바퀴 제거
        title: const Text("마이파인"),
      ),
      body: ListView(
        children: [
          _buildProfileHeader(context),
          _buildSelfIntroduction(_userProfile.introduction),

          const SizedBox(height: 20),
          _buildInfoBoxes(context),

          const SizedBox(height: 20),
          const Divider(thickness: 8, color: Color(0xFFF0F0F0)),

          // 내 리뷰 Top 3
          _buildReviewTop3Section(),

          const Divider(thickness: 8, color: Color(0xFFF0F0F0)),

          // "나의 입맛"
          _buildMenuListItem(
            icon: Icons.restaurant_menu,
            title: "나의 입맛",
            onTap: () =>
                Navigator.pushNamed(context, '/mytaste'),
          ),

          _buildMenuListItem(
            icon: Icons.payment,
            title: "결제관리",
            onTap: () => _goToPlaceholderPage("결제관리"),
          ),
          _buildMenuListItem(
            icon: Icons.support_agent,
            title: "고객센터",
            onTap: () => _goToPlaceholderPage("고객센터"),
          ),
          _buildMenuListItem(
            icon: Icons.event,
            title: "이벤트",
            onTap: () => _goToPlaceholderPage("이벤트"),
          ),
          _buildMenuListItem(
            icon: Icons.policy_outlined,
            title: "약관 및 정책",
            onTap: () => _goToPlaceholderPage("약관 및 정책"),
          ),
          _buildMenuListItem(
            icon: Icons.settings,
            title: "설정",
            onTap: () => _goToPlaceholderPage("설정"),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // =========================
  // 프로필 헤더
  // =========================

  Widget _buildProfileHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 50,
                child: Icon(Icons.person, size: 50),
              ),
              const SizedBox(width: 16),

              // 칭호 + 아이콘 + 닉네임 한 줄
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _userProfile.title,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.emoji_events,
                            color: Colors.amber, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          _userProfile.nickname,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        // LV
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "LV.${_userProfile.level}",
                            style: const TextStyle(
                              color: Colors.yellowAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        // 경험치바
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildExpBar(_userProfile.expPercent),
                              const SizedBox(height: 4),
                              Text(
                                "${_userProfile.currentExp.toInt()} / ${_userProfile.maxExp.toInt()} EXP",
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // "내 정보 보기" & "프로필 변경" 버튼 (위로 조금 더 올림)
          Positioned(
            top: -26, // ← 여기 때문에 닉네임과 안 겹치도록 위로 올렸다
            right: 0,
            child: Row(
              children: [
                TextButton(
                  onPressed: () => _goToPlaceholderPage("내 정보 보기"),
                  child: const Text(
                    "내 정보 보기",
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
                Container(
                  width: 1,
                  height: 12,
                  color: Colors.grey[300],
                ),
                TextButton(
                  onPressed: _navigateAndEditProfile,
                  child: const Text(
                    "프로필 변경",
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  // 경험치바
  // =========================

  Widget _buildExpBar(double percent) {
    percent = percent.clamp(0.0, 1.0);

    final colors = <Color>[
      Colors.green,
      Colors.lightGreen,
      Colors.yellow,
      Colors.orange,
      Colors.red,
    ];

    final index = percent * (colors.length - 1);
    final low = index.floor();
    final high = min(low + 1, colors.length - 1);
    final t = index - low;

    final barColor = Color.lerp(colors[low], colors[high], t)!;

    return Stack(
      children: [
        Container(
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        FractionallySizedBox(
          widthFactor: percent,
          child: Container(
            height: 16,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: barColor,
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Text(
              "${(percent * 100).toStringAsFixed(1)}%",
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
      ],
    );
  }

  // =========================
  // 자기소개
  // =========================

  Widget _buildSelfIntroduction(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[700]),
        ),
      ),
    );
  }

  // =========================
  // 영향력 / 포인트
  // =========================

  Widget _buildInfoBoxes(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoBox(
              title: "나의 영향력",
              value: "${_userProfile.influence}명",
              onTap: () => _goToPlaceholderPage("나의 영향력"),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildInfoBox(
              title: "마이 포인트",
              value: "${_userProfile.points} P",
              onTap: () => _goToPlaceholderPage("포인트"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // 내 리뷰 Top 3 + 더보기
  // =========================

  Widget _buildReviewTop3Section() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "내 리뷰 Top 3",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => _goToPlaceholderPage("리뷰 관리"),
                child: const Text("+ 더보기"),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildReviewItem("인생 맛집 찾았다", "니즈파인 점수 4.8", 102),
          _buildReviewItem("다신 안 시킨다", "니즈파인 점수 4.1", 89),
          _buildReviewItem("존맛탱 노트북", "니즈파인 점수 4.5", 75),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String title, String subtitle, int likes) {
    return ListTile(
      leading: const Icon(Icons.store),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Text("👍 $likes"),
    );
  }

  // =========================
  // 하단 메뉴 아이템
  // =========================

  Widget _buildMenuListItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}