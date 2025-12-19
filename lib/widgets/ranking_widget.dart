import 'package:flutter/material.dart' hide CarouselController; // [오류 수정] 이름 충돌 해결
import 'package:carousel_slider/carousel_slider.dart';

class RankingWidget extends StatelessWidget {
  RankingWidget({super.key});

  final List<String> imgList = [
    'https://via.placeholder.com/400x150/FFC107/000000?Text=Ranking+1',
    'https://via.placeholder.com/400x150/03A9F4/FFFFFF?Text=Ranking+2',
    'https://via.placeholder.com/400x150/4CAF50/FFFFFF?Text=Ranking+3',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16.0, top: 24.0, bottom: 16.0),
          child: Text(
            "🔥 지금 HOT한 니즈파인 랭킹",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 150,
          child: CarouselSlider(
            options: CarouselOptions(
              autoPlay: true,
              aspectRatio: 2.0,
              enlargeCenterPage: true,
            ),
            items: imgList.map((item) => Container(
              margin: const EdgeInsets.all(5.0),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                child: Image.network(item, fit: BoxFit.cover, width: 1000.0),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }
}
