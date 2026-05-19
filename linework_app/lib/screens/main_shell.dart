import 'package:flutter/material.dart';
import 'package:linework_app/screens/home_screen.dart';
import 'package:linework_app/screens/map_screen.dart';
import 'package:linework_app/screens/rating_screen.dart';
import 'package:linework_app/screens/status_screen.dart';
import 'package:linework_app/screens/task_posting_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    MapScreen(),
    RatingScreen(),
    StatusScreen(),
  ];

  static const List<BottomNavigationBarItem> _navItems =
      <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Peta'),
        BottomNavigationBarItem(icon: Icon(Icons.star_rate), label: 'Rating'),
        BottomNavigationBarItem(icon: Icon(Icons.timeline), label: 'Status'),
      ];

  void _onTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openTaskPosting() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TaskPostingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF1B3D6E),
        unselectedItemColor: const Color(0xFF94A3B8),
        type: BottomNavigationBarType.fixed,
        items: _navItems,
        onTap: _onTap,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openTaskPosting,
        backgroundColor: const Color(0xFF1B3D6E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
