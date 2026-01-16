import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // 디버그 프린트용

class NfpsService {
  // Supabase 클라이언트 인스턴스 (편의상 static getter로 사용하거나 직접 호출)
  static final _supabase = Supabase.instance.client;

  /// 사용자 행동 로그 적재 함수
  /// [actionType]: SQL에 등록된 행동 규칙 이름 (예: 'SWIPE_LIKE_EXPENSIVE')
  /// [targetId]: (선택) 가게 ID, 메뉴 ID 등 대상 정보
  static Future<void> logUserAction({
    required String actionType,
    String? targetId,
  }) async {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      debugPrint("❌ 로그 적재 실패: 로그인된 사용자가 없습니다.");
      return;
    }

    try {
      // 1. 로그 테이블에 데이터 삽입 (이 순간 DB 트리거가 발동되어 스탯이 갱신됨)
      await _supabase.from('action_logs').insert({
        'user_id': userId,
        'action_type': actionType,
        'target_id': targetId,
        // created_at은 DB에서 자동으로 now() 처리됨
      });

      debugPrint("✅ NFPS 로그 적재 완료: $actionType (Target: $targetId)");

    } catch (e) {
      debugPrint("❌ NFPS 로그 적재 실패: $e");
      // 필요하다면 에러를 다시 던져서 UI에서 스낵바를 띄우게 할 수도 있음
      // throw e;
    }
  }
}