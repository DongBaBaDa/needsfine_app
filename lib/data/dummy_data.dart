import 'dart:math';
import 'package:needsfine_app/features/sanctuary/data/store_model.dart';

Map<String, List<Store>> generateDummyData(List<String> categories) {
  final random = Random();
  final Map<String, List<Store>> data = {};
  final List<String> allTags = [
      "가성비", "가심비", "혼밥", "혼술", "데이트", "기념일", "소개팅", "상견례", "가족외식", "단체모임", "회식", "접대", 
      "조용한", "분위기 좋은", "시끄러운", "활기찬", "힙한", "감성적인", "이국적인", "전통적인",
      "전망좋은", "야경", "루프탑", "테라스", "야외", "주차가능", "발렛파킹", "예약가능", "콜키지프리",
      "룸", "애견동반", "유아동반", "유아시설", "장애인시설", "신규오픈", "현지인맛집", "노포",
      "대체불가", "사장님존잘", "사장님존예", "친절한", "매장청결", "음식빨리나옴",
      "재료신선", "양많음", "존맛탱", "인생맛집"
  ];

  for (var category in categories) {
    data[category] = List.generate(10, (index) {
      final tagCount = random.nextInt(10) + 1;
      final shuffledTags = [...allTags]..shuffle(random);
      return Store(
        rank: index + 1,
        name: "$category 맛집 ${index + 1}호점",
        distance: double.parse((random.nextDouble() * 10).toStringAsFixed(1)),
        reviewCount: random.nextInt(1000) + 20,
        needsFineScore: double.parse((random.nextDouble() * 2 + 2.5).toStringAsFixed(1)),
        tags: shuffledTags.sublist(0, tagCount),
      );
    });
  }
  return data;
}
