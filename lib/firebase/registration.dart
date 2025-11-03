import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'auth_service.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = await authService.registerWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (user != null) {
      final username = _usernameController.text.trim();

      // ✅ Update Firebase Auth display name
      await user.updateDisplayName(username);
      await user.reload();

      // ✅ Update Firestore document with username
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'username': username},
      );

      context.go('/home');
    } else {
      setState(() => _error = "Registration failed. Please try again.");
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 30, 30),
                child: Image.asset("assets/images/logo.png", height: 250),
              ),
              // Username input
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: "Username",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Email input
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Password input
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Error message
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),

              const SizedBox(height: 16),

              // Register button
              _loading
                  ? CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 20),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.inversePrimary,
                          ),
                          child: Text(
                            "Register",
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ),

              // Back to login
              TextButton(
                onPressed: () {
                  context.go('/login');
                },
                child: Text(
                  "Already have an account? Login",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
