import 'package:flutter/material.dart';
import 'home_screen.dart'; 
import 'ai_coach_screen.dart';
import 'relax_screen.dart'; 
import 'history_screen.dart';
import 'profile_screen.dart';

class Navigationbar extends StatefulWidget {
  const Navigationbar({Key? key}) : super(key: key);

  @override
  State<Navigationbar> createState() => _NavigationbarState();
}

class _NavigationbarState extends State<Navigationbar> {
  int _selectedIndex = 0; 

   // Κρατάει τις οθόνες φορτωμένες, ώστε να μη χάνεται το chat όταν αλλάζουμε tab
  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    AiCoachScreen(), 
    RelaxScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: const Color.fromARGB(255, 25, 96, 25),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Αρχική',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Ιστορικό',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology_alt_outlined),
            activeIcon: Icon(Icons.psychology_alt),
            label: 'AI Coach',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.spa_outlined),
            activeIcon: Icon(Icons.spa),
            label: 'Χαλάρωση',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Προφίλ',
          ),
        ],
      ),
    );
  }
}