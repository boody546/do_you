import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

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

  /// Sign in parent or child user
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

  /// Sign out current user
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
