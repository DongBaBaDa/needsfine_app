import 'package:flutter/material.dart';
import 'package:carousel_slider_plus/carousel_slider_plus.dart';

class RankingWidget extends StatelessWidget {
  RankingWidget({super.key});

  final List<Map<String, dynamic>> rankings = [
    {'rank': 1, 'term': "강남역 맛집", 'change': 1, 'status': 'up'},
    {'rank': 2, 'term': "홍대 찐맛집", 'change': 0, 'status': 'same'},
    {'rank': 3, 'term': "부산 국밥", 'change': 2, 'status': 'down'},
    {'rank': 4, 'term': "성수동 카페", 'change': 3, 'status': 'up'},
    {'rank': 5, 'term': "여의도 점심", 'change': 1, 'status': 'down'},
    {'rank': 6, 'term': "제주 흑돼지", 'change': 0, 'status': 'same'},
    {'rank': 7, 'term': "가로수길", 'change': 1, 'status': 'up'},
    {'rank': 8, 'term': "을지로", 'change': 1, 'status': 'up'},
    {'rank': 9, 'term': "광안리", 'change': 4, 'status': 'down'},
  ];

  @override
  Widget build(BuildContext context) {
    List<List<Map<String, dynamic>>> chunks = [];
    for (var i = 0; i < rankings.length; i += 3) {
      chunks.add(rankings.sublist(i, i + 3 > rankings.length ? rankings.length : i + 3));
    }

    return Container(
      height: 150,
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 130,
          autoPlay: true,
          enlargeCenterPage: false,
          viewportFraction: 1.0,
          autoPlayInterval: const Duration(seconds: 5),
          pauseAutoPlayOnTouch: true, // 2. Pause auto-play on touch
        ),
        items: chunks.map((chunk) {
          return Builder(
            builder: (BuildContext context) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: chunk.map((item) => RankingItem(item: item)).toList(),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

class RankingItem extends StatelessWidget {
  final Map<String, dynamic> item;
  const RankingItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    Widget changeWidget;
    if (item['status'] == 'up') {
      changeWidget = Row(
        children: [
          const Icon(Icons.arrow_drop_up, color: Colors.red, size: 20),
          Text(item['change'].toString(), style: const TextStyle(color: Colors.red)),
        ],
      );
    } else if (item['status'] == 'down') {
      changeWidget = Row(
        children: [
          const Icon(Icons.arrow_drop_down, color: Colors.blue, size: 20),
          Text(item['change'].toString(), style: const TextStyle(color: Colors.blue)),
        ],
      );
    } else {
      changeWidget = const Text("-", style: TextStyle(color: Colors.grey));
    }

    return InkWell(
      onTap: () {
        // 3. Navigate to search screen with the search term
        Navigator.pushNamed(context, '/search', arguments: item['term']);
      },
      child: Row(
        children: [
          Text("${item['rank']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(child: Text(item['term'], style: const TextStyle(fontSize: 16))),
          changeWidget,
        ],
      ),
    );
  }
}
