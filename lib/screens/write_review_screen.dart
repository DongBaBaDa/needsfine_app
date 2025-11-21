import 'package:flutter/material.dart';
import '../models/app_data.dart';

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({super.key});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final TextEditingController _controller = TextEditingController();
  double _rating = 5.0;

  @override
  Widget build(BuildContext context) {
    // arguments로 가게 ID를 받음
    final String storeId = ModalRoute.of(context)!.settings.arguments as String;
    final store = AppData().stores.firstWhere((s) => s.id == storeId);

    return Scaffold(
      appBar: AppBar(title: const Text("리뷰 쓰기")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("${store.name} 어떠셨나요?", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // 별점 선택 (슬라이더로 대체)
            Row(
              children: [
                const Text("별점: "),
                Expanded(
                  child: Slider(
                    value: _rating,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _rating.toString(),
                    onChanged: (val) => setState(() => _rating = val),
                  ),
                ),
                Text("$_rating점"),
              ],
            ),
            const SizedBox(height: 20),

            // 내용 입력
            TextField(
              controller: _controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "솔직한 리뷰를 남겨주세요. (구체적으로 쓰면 니즈파인 점수가 올라갑니다!)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                if (_controller.text.isEmpty) return;

                // 로직 실행
                AppData().addReview(storeId, _controller.text, _rating);

                Navigator.pop(context); // 뒤로가기
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("리뷰가 등록되었습니다! F점수가 갱신됩니다.")),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text("등록하기"),
            )
          ],
        ),
      ),
    );
  }
}