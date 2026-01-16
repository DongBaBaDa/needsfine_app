// 예: lib/screens/swipe_card_screen.dart 내부

import 'package:flutter/material.dart';
import 'package:needsfine_app/services/nfps_service.dart'; // 방금 만든 파일 임포트

class SwipeCardScreen extends StatelessWidget {
  // ...

  // '좋아요' 스와이프 했을 때 실행되는 함수
  void onSwipeRight(String restaurantId) {

    // 비싼 가게인지 싼 가게인지 판별하는 로직이 있다고 가정
    bool isExpensive = true;

    // ✅ 여기서 서비스 호출!
    NfpsService.logUserAction(
      actionType: isExpensive ? 'SWIPE_LIKE_EXPENSIVE' : 'SWIPE_LIKE_CHEAP',
      targetId: restaurantId,
    );

    print("좋아요 처리됨!");
  }

// ...
}