import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔥 Get current user
  User? get currentUser => _auth.currentUser;

  // 🧠 Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ✅ Sign Up with email and password + extra details
  Future<User?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      // 📝 Save additional user info to Firestore, INCLUDING ROLE
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'emailing': email,
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'role': 'customer', // 👈 THIS LINE makes new users customers!
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return user;
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
