// lib/config/supabase_config.dart
/// NEEDSFINE Supabase 서버 설정
/// 웹 프로젝트와 동일한 서버를 사용합니다.
class SupabaseConfig {
  // 🔥 실제 프로젝트 정보 (웹과 동일)
  static const String projectId = "hokjkmapqbinhsivkbnj";
  
  static const String supabaseUrl = 
    "https://hokjkmapqbinhsivkbnj.supabase.co";
  
  static const String anonKey = 
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhva2prbWFwcWJpbmhzaXZrYm5qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQxMDAzMDgsImV4cCI6MjA3OTY3NjMwOH0.2QEm4vp65dReMyWhSOm8_ZnQj3Sqh2fB84DM0rTfWzg";
  
  // API 엔드포인트 (Edge Functions)
  static const String apiBaseUrl = 
    "https://hokjkmapqbinhsivkbnj.supabase.co/functions/v1/make-server-26899706";
  
  // 관리자 비밀번호
  static const String adminPassword = "needsfine2953";
}
