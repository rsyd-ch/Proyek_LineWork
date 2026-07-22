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

  void _onTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openTaskPosting() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TaskPostingScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: _LineWorkBottomBar(
        currentIndex: _selectedIndex,
        onTap: _onTap,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openTaskPosting,
        tooltip: 'Buat pekerjaan',
        elevation: 4,
        backgroundColor: const Color(0xFF0B4778),
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _LineWorkBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _LineWorkBottomBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BottomAppBar(
      color: colorScheme.surface,
      elevation: 18,
      shadowColor: const Color(0x33000000),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      padding: EdgeInsets.zero,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 74,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomBarItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Beranda',
                selected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _BottomBarItem(
                icon: Icons.map_outlined,
                activeIcon: Icons.map_rounded,
                label: 'Peta',
                selected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              const SizedBox(width: 64),
              _BottomBarItem(
                icon: Icons.star_border_rounded,
                activeIcon: Icons.star_rounded,
                label: 'Rating',
                selected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _BottomBarItem(
                icon: Icons.timeline_outlined,
                activeIcon: Icons.timeline_rounded,
                label: 'Status',
                selected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = selected ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 64,
          height: 54,
          decoration: BoxDecoration(
            color: selected ? colorScheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? activeIcon : icon, color: color, size: 23),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
