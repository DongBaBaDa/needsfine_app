import 'package:flutter/material.dart';
import 'package:needsfine_app/main.dart'; // Reverted import

class StoreMyPageScreen extends StatelessWidget {
  const StoreMyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("가게 마이페이지"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () {
            isLoggedIn.value = false;
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          })
        ],
      ),
      body: const Center(child: Text("가게 마이페이지입니다.")),
    );
  }
}
