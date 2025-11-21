import 'package:flutter/material.dart';

// --- [ ✅ ✅ 3-1. '위치' '화면' ] ---
class LocationScreen extends StatelessWidget {
  const LocationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: InputDecoration(
            hintText: "주소로 검색...",
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            suffixIcon: const Icon(Icons.search),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.grey[300],
            alignment: Alignment.center,
            child: const Text(
              "'Google Maps' '지도' '영역'\n('API 키' '설정' '필요')",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ),
          const Center(
            child: Icon(
              Icons.location_pin,
              color: Colors.red,
              size: 40,
            ),
          )
        ],
      ),
    );
  }
}