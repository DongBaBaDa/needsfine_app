import 'package:flutter/material.dart';
import 'package:needsfine_app/screens/home_screen.dart';
import 'package:needsfine_app/screens/ranking_screen.dart'; 
import 'package:needsfine_app/screens/nearby_screen.dart';
import 'package:needsfine_app/screens/sanctuary_screen.dart';
import 'package:needsfine_app/screens/user_mypage_screen.dart';
import 'package:needsfine_app/main.dart'; 

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    RankingScreen(), // Changed from MenuScreen
    NearbyScreen(),
    SanctuaryScreen(),
    UserMyPageScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 4 && !isLoggedIn.value) {
      Navigator.pushNamed(context, '/login');
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard_outlined), // Changed Icon
            label: '랭킹', // Changed Label
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: '내 주변',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield_outlined),
            label: '성지',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '마이파인',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, 
      ),
    );
  }
}
