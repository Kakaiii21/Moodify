import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of authentication state
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current logged-in user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      debugPrint('Sign in error: $e');
      return null;
    }
  }

  // Register with email and password
  Future<User?> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null) {
        // Save user data to Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'username': '', // You’ll fill this in from registration.dart
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
    } catch (e) {
      debugPrint('Registration error: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
