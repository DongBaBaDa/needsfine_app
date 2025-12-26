import 'package:flutter/material.dart';
import 'package:needsfine_app/models/app_data.dart';

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({super.key});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _reviewController = TextEditingController();
  double _rating = 3.0;

  @override
  Widget build(BuildContext context) {
    final String storeId = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text('리뷰 작성'),
        actions: [
          TextButton(
            onPressed: () {
              if (_reviewController.text.length < 10) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('리뷰는 10자 이상 작성해주세요.')),
                );
                return;
              }
              // [수정] 변경된 addReview 메서드 호출
              AppData().addReview(storeId, _reviewController.text, _rating);
              Navigator.pop(context);
            },
            child: const Text('게시', style: TextStyle(color: Colors.blue)),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('별점: $_rating', style: const TextStyle(fontSize: 16)),
            Slider(
              value: _rating,
              min: 1.0,
              max: 5.0,
              divisions: 8,
              label: _rating.toString(),
              onChanged: (double value) {
                setState(() {
                  _rating = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _reviewController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: '솔직한 리뷰를 작성해주세요...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
