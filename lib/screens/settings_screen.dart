import 'package:flutter/material.dart';

// '설정'
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("설정"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: const Text('로그아웃'),
            onTap: () {
              // TODO: Implement logout functionality
              print('로그아웃 Tapped');
            },
          ),
          ListTile(
            title: const Text('회원탈퇴'),
            onTap: () {
              // TODO: Implement account withdrawal functionality
              print('회원탈퇴 Tapped');
            },
          ),
        ],
      ),
    );
  }
}
