import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn? _googleSignIn;
  
  User? get user => _auth.currentUser;
  bool get isLoggedIn => user != null;

  AuthProvider() {
    _auth.authStateChanges().listen((_) => notifyListeners());
    // Initialize Google Sign-In lazily (avoids web client ID error on startup)
    _initGoogleSignIn();
  }
  
  void _initGoogleSignIn() {
    try {
      _googleSignIn = GoogleSignIn();
    } catch (e) {
      debugPrint('Google Sign-In initialization failed (normal on web without client ID): $e');
      _googleSignIn = null;
    }
  }

  Future<void> signOut() async {
    debugPrint('Signing out user...');
    
    try {
      // Only try Google sign-out if initialized
      if (_googleSignIn != null) {
        await _googleSignIn!.signOut();
        debugPrint('Google sign-out successful');
      }
    } catch (e) {
      // Ignore Google sign-out errors on web (expected without client ID)
      // This is non-critical - Firebase sign-out is what matters
      debugPrint('Google sign-out skipped (non-critical): ${e.toString().split('\n').first}');
    }
    
    // Always sign out from Firebase (this is what matters)
    await _auth.signOut();
    debugPrint('Firebase sign-out successful - user logged out');
    notifyListeners();
  }

  Future<void> signInAnonymously() async {
    await _auth.signInAnonymously();
    notifyListeners();
  }

  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    notifyListeners();
  }

  Future<void> registerWithEmail(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(email: email, password: password);
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    if (_googleSignIn == null) {
      throw Exception(
        kIsWeb 
          ? 'Google Sign-In not configured for web. Please use Email/Password login or configure Google Client ID.'
          : 'Google Sign-In not available'
      );
    }
    
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
      if (googleUser == null) return; // User canceled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      notifyListeners();
    } catch (e) {
      debugPrint('Google sign-in error: $e');
      rethrow;
    }
  }

  // Facebook sign-in would require facebook_login package and Facebook App setup
  // Placeholder for future implementation
  Future<void> signInWithFacebook() async {
    // TODO: Implement Facebook sign-in when needed
    throw UnimplementedError('Facebook sign-in not yet implemented');
  }
}


