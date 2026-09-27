import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static const String adminEmail = 'admin';
  static const String adminPassword = 'admin';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  bool isAdminEmail(String? email) => email?.trim() == adminEmail;

  Future<UserCredential> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign_in_canceled',
        message: 'Google girişi iptal edildi.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<UserCredential> signInAdmin() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null && isAdminEmail(currentUser.email)) {
      return await _auth.signInAnonymously();
    }

    try {
      return await _auth.createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return await _auth.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );
      }
      rethrow;
    }
  }

  Future<UserCredential> register({required String email, required String password}) {
    return _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() {
    return _auth.signOut();
  }
}
