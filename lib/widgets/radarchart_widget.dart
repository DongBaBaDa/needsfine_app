import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart'; // fl_chart 패키지 사용 가정

class RadarChartWidget extends StatelessWidget {
  const RadarChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) return const SizedBox();

    return StreamBuilder<List<Map<String, dynamic>>>(
      // ✅ Supabase Realtime: 내 스탯이 변하면 즉시 반응
      stream: Supabase.instance.client
          .from('user_stats')
          .stream(primaryKey: ['user_id'])
          .eq('user_id', userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("분석 데이터가 부족합니다.")); // 초기 상태
        }

        final data = snapshot.data![0];
        // DB 컬럼 값을 double로 변환
        final tongue = (data['tongue'] as num).toDouble();
        final vibe = (data['vibe'] as num).toDouble();
        final grid = (data['grid'] as num).toDouble();
        final wallet = (data['wallet'] as num).toDouble();
        final voice = (data['voice'] as num).toDouble();

        return SizedBox(
          height: 300,
          child: RadarChart(
            RadarChartData(
              radarShape: RadarShape.polygon,
              ticksTextStyle: const TextStyle(color: Colors.transparent),
              gridBorderData: BorderSide(color: Colors.grey.withOpacity(0.3)),
              titlePositionPercentageOffset: 0.2,
              titleTextStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),

              // 5각 축 타이틀
              getTitle: (index, angle) {
                switch (index) {
                  case 0: return RadarChartTitle(text: '미각(Tongue)');
                  case 1: return RadarChartTitle(text: '감성(Vibe)');
                  case 2: return RadarChartTitle(text: '발굴(Grid)');
                  case 3: return RadarChartTitle(text: '가성비(Wallet)');
                  case 4: return RadarChartTitle(text: '전파(Voice)');
                  default: return const RadarChartTitle(text: '');
                }
              },

              // 실제 데이터 그래프
              dataSets: [
                RadarDataSet(
                  fillColor: Colors.deepPurple.withOpacity(0.4),
                  borderColor: Colors.deepPurple,
                  entryRadius: 3,
                  dataEntries: [
                    RadarEntry(value: tongue),
                    RadarEntry(value: vibe),
                    RadarEntry(value: grid),
                    RadarEntry(value: wallet),
                    RadarEntry(value: voice),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}