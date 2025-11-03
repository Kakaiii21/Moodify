import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = await authService.signInWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    setState(() => _loading = false);

    if (user == null) {
      setState(() => _error = "Login failed. Please check your credentials.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
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

              const SizedBox(height: 1),

              // Login button
              _loading
                  ? const CircularProgressIndicator()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 1),
                      child: SizedBox(
                        width: double.infinity, // makes it full width
                        height: 50, // increases height
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.inversePrimary,
                          ),
                          child: Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer,
                            ),
                          ),
                        ),
                      ),
                    ),
              Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    "Forgot Password?",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      decoration: TextDecoration.underline,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Register navigation
              TextButton(
                onPressed: () {
                  context.go(
                    '/register',
                  ); // or context.push('/register') if you want back button support
                },
                child: Text(
                  "Don't have an account? Register",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
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
