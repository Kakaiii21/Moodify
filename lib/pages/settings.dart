import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:moodify/theme/theme_provider.dart';
import 'package:provider/provider.dart';

import '../firebase/auth_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.inversePrimary;
    final lineColor = Theme.of(context).colorScheme.surface;

    // Get the currently logged-in user
    final authService = Provider.of<AuthService>(context);
    final userEmail = authService.currentUser?.email ?? "No Email";
    final userName = authService.currentUser?.displayName ?? "User";

    return Scaffold(
      extendBodyBehindAppBar: true, // 🟢 allow content behind status bar

      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Profile section with cover and avatar
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Cover photo
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/cover.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Profile picture (centered above cover)
                  Positioned(
                    bottom: -40,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: const AssetImage(
                        'assets/images/profile.png',
                      ),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              // Name and email (centered)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Dark Mode toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Dark Mode", style: TextStyle(color: textColor)),
                    CupertinoSwitch(
                      value: Provider.of<ThemeProvider>(context).isDarkMode,
                      onChanged: (value) {
                        Provider.of<ThemeProvider>(
                          context,
                          listen: false,
                        ).toggleTheme();
                      },
                    ),
                  ],
                ),
              ),
              Container(
                height: 0.5,
                color: lineColor,
                margin: const EdgeInsets.symmetric(vertical: 12),
              ),
              // Logout row
              InkWell(
                onTap: () async {
                  await authService.signOut();
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Logout",
                        style: TextStyle(fontSize: 15, color: textColor),
                      ),
                      Icon(Icons.logout, color: textColor),
                    ],
                  ),
                ),
              ),
              Container(
                height: 0.5,
                color: lineColor,
                margin: const EdgeInsets.symmetric(vertical: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
