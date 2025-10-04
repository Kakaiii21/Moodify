import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:moodify/pages/music.dart';

import '../pages/settings.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Playlist(),
    Center(child: Text("Weather Page")),
    Center(child: Text("Diary Page")),
    const SettingsPage(), // index 3
  ];

  final List<String> _titles = [
    "P   L   A   Y   L   I   S   T",
    "W   E   A   T   H   E   R",
    "D   I   A   R   Y",
    "S   E   T   T   I   N   G   S",
  ];

  void _navigateTo(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigator.pop(context);  // remove this if you don’t use a drawer
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      extendBodyBehindAppBar: true, // 🟢 allow content behind status bar

      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
        ), // 👈 dynamic title
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),

      body: _pages[_selectedIndex], // show selected page

      bottomNavigationBar: Container(
        color: Theme.of(context).colorScheme.primary,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: GNav(
            selectedIndex: _selectedIndex,
            backgroundColor: Theme.of(context).colorScheme.primary,
            color: Theme.of(context).colorScheme.inversePrimary,
            activeColor: Theme.of(context).colorScheme.inversePrimary,
            tabBackgroundColor: Theme.of(
              context,
            ).colorScheme.secondaryContainer,
            gap: 8,
            onTabChange: (index) => _navigateTo(index),
            padding: const EdgeInsets.all(16),
            tabs: const [
              GButton(icon: Icons.my_library_music_rounded, text: 'Music'),
              GButton(icon: Icons.cloudy_snowing, text: 'Weather'),
              GButton(icon: Icons.note_alt_sharp, text: 'Diary'),
              GButton(icon: Icons.settings, text: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
}
