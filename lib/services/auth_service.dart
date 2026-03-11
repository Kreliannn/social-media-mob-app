import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Register ────────────────────────────────────────────────────────────────
  Future<String?> register(String email, String password, String name) async {
    try {
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      await _firestore.collection('users').doc(userCred.user!.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // success
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e.code);
    } catch (_) {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // ─── Login ───────────────────────────────────────────────────────────────────
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // success
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e.code);
    } catch (_) {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  // ─── Update Profile (name + optional password) ───────────────────────────────
  Future<String?> updateProfile({
    required String name,
    String? currentPassword,
    String? newPassword,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return 'No user is currently logged in.';

    try {
      // Update name in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update password if provided
      if (newPassword != null &&
          newPassword.isNotEmpty &&
          currentPassword != null &&
          currentPassword.isNotEmpty) {
        // Re-authenticate first (required by Firebase before sensitive operations)
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);
      }

      return null; // success
    } on FirebaseAuthException catch (e) {
      return _authErrorMessage(e.code);
    } catch (_) {
      return 'Failed to update profile. Please try again.';
    }
  }

  // ─── Get Profile ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot snap =
          await _firestore.collection('users').doc(user.uid).get();
      if (snap.exists) {
        return snap.data() as Map<String, dynamic>;
      }
    }
    return null;
  }

  // ─── Get Current User ────────────────────────────────────────────────────────
  User? getCurrentUser() => _auth.currentUser;

  // ─── Logout ──────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ─── Auth State Stream ───────────────────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Friendly Error Messages ─────────────────────────────────────────────────
  String _authErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'requires-recent-login':
        return 'Please log out and log in again before changing your password.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return 'Something went wrong ($code). Please try again.';
    }
  }
}