// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to track authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // User registration with email/password
  Future<User?> register(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await result.user?.sendEmailVerification();
      return result.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getErrorMessage(e.code));
    }
  }

  // User login with email/password
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user?.emailVerified ?? false) {
        return result.user;
      } else {
        await logout();
        throw AuthException('Please verify your email first');
      }
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getErrorMessage(e.code));
    }
  }

  // User logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Error message handling
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'Password is too weak';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'Account disabled';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      default:
        return 'Authentication failed';
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}