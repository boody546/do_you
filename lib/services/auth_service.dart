import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId:
        '648842993184-06mit1tpor7dnelgq8cnrncj30igdnh4.apps.googleusercontent.com',
  );

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up parent user with Email & Password
  Future<UserModel?> signUpParent({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final userModel = UserModel(
          uid: credential.user!.uid,
          email: email,
          role: 'parent',
          createdAt: DateTime.now(),
        );

        await _firestoreService.saveUserProfile(userModel);
        return userModel;
      }
    } catch (e) {
      print('Auth error in signUpParent: $e');
      rethrow;
    }
    return null;
  }

  /// Sign in parent with Email & Password
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Auth error in signIn: $e');
      rethrow;
    }
  }

  /// Sign in with Google One-Tap / OAuth
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        final userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          role: 'parent',
          createdAt: DateTime.now(),
        );
        await _firestoreService.saveUserProfile(userModel);
        return userModel;
      }
    } catch (e) {
      print('Google Sign-In Error: $e');
      rethrow;
    }
    return null;
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
