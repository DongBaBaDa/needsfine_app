import 'package:flutter/foundation.dart';

class SearchTarget {
  final String query;      // 검색어 (가게 이름)
  final double? lat;       // 위도 (옵션)
  final double? lng;       // 경도 (옵션)

  SearchTarget({required this.query, this.lat, this.lng});
}

// 기존: ValueNotifier<String?> searchTrigger = ValueNotifier(null);
// 변경: SearchTarget 객체를 전달
final ValueNotifier<SearchTarget?> searchTrigger = ValueNotifier(null);