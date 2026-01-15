import 'package:flutter/material.dart';

class InquiryDetailScreen extends StatelessWidget {
  const InquiryDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("문의 내역", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: const Center(
        child: Text("문의 상세 페이지 준비 중입니다."),
      ),
    );
  }
}