import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔥 Get current user
  User? get currentUser => _auth.currentUser;

  // 🧠 Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ✅ Sign Up with email and password
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('❌ Sign Up Error: $e');
      rethrow;
    }
  }

  // 🔑 Sign In with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print('❌ Sign In Error: $e');
      rethrow;
    }
  }

  // ✉️ Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('❌ Password Reset Error: $e');
      rethrow;
    }
  }

  // 🚪 Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('❌ Sign Out Error: $e');
      rethrow;
    }
  }
}
