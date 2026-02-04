// lib/widgets/user_profile_link.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:needsfine_app/screens/user_profile_screen.dart'; // 방금 만든 피드 화면 import

class UserProfileLink extends StatelessWidget {
  final String? userId;           // 이동할 유저 ID (null이면 클릭 안됨)
  final String nickname;          // 표시할 닉네임
  final String? profileImageUrl;  // 이미지 URL
  final double avatarSize;        // 아바타 크기 (기본 20)
  final double fontSize;          // 폰트 크기 (기본 14)
  final bool showNickname;        // 닉네임 표시 여부 (false면 사진만 나옴)

  const UserProfileLink({
    super.key,
    required this.userId,
    required this.nickname,
    this.profileImageUrl,
    this.avatarSize = 20,
    this.fontSize = 14,
    this.showNickname = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (userId == null) return;

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UserProfileScreen(userId: userId!)),
        );
      },
      borderRadius: BorderRadius.circular(avatarSize),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: avatarSize,
            backgroundColor: Colors.grey[200],
            backgroundImage: (profileImageUrl != null && profileImageUrl!.isNotEmpty) 
                ? NetworkImage(profileImageUrl!) 
                : null,
            child: (profileImageUrl == null || profileImageUrl!.isEmpty)
                ? Icon(Icons.person, size: avatarSize * 0.9, color: Colors.grey)
                : null,
          ),
          if (showNickname) ...[
            const SizedBox(width: 8),
            Text(
              nickname,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: fontSize,
                color: Colors.black87,
              ),
            ),
          ],
        ],
      ),
    );
  }
}