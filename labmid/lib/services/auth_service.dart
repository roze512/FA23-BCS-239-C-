import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

/// Authentication service for Firebase
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Login timeout - Please check your internet connection and try again');
        },
      );

      final User? user = result.user;
      if (user == null) {
        throw Exception('Sign in failed');
      }

      // Update last login time
      await _firestore.collection(AppConstants.usersCollection).doc(user.uid).update({
        'lastLoginAt': DateTime.now().toIso8601String(),
      }).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          // Non-critical operation, continue even if it fails
          print('Warning: Last login time update timed out for user ${user.uid}');
        },
      );

      // Get user data from Firestore
      final userData = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get()
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Failed to retrieve user data - Please try again');
        },
      );

      return UserModel.fromJson(userData.data()!);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  /// Sign up with email and password
  Future<UserModel> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Sign up timeout - Please check your internet connection and try again');
        },
      );

      final User? user = result.user;
      if (user == null) {
        throw Exception('Sign up failed');
      }

      // Update display name
      await user.updateDisplayName(name).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          // Non-critical operation, continue even if it fails
          print('Warning: Display name update timed out for user ${user.uid}');
        },
      );

      // Create user document in Firestore
      final UserModel userModel = UserModel(
        uid: user.uid,
        email: email,
        name: name,
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(userModel.toJson())
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Failed to save user data - Please try again');
        },
      );

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  /// Sign in with Google
  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Google sign in timeout - Please try again');
        },
      );
      
      if (googleUser == null) {
        throw Exception('Google sign in cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Google authentication timeout - Please try again');
        },
      );
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(credential).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Firebase authentication timeout - Please try again');
        },
      );
      
      final User? user = result.user;

      if (user == null) {
        throw Exception('Google sign in failed');
      }

      // Check if user document exists
      final docSnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get()
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Failed to retrieve user data - Please try again');
        },
      );

      UserModel userModel;
      if (!docSnapshot.exists) {
        // Create new user document
        userModel = UserModel(
          uid: user.uid,
          email: user.email!,
          name: user.displayName ?? 'User',
          photoUrl: user.photoURL,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .set(userModel.toJson())
            .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception('Failed to save user data - Please try again');
          },
        );
      } else {
        // Update last login time
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .update({
          'lastLoginAt': DateTime.now().toIso8601String(),
        }).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            // Non-critical operation, continue even if it fails
            print('Warning: Last login time update timed out for Google sign-in user ${user.uid}');
          },
        );
        userModel = UserModel.fromJson(docSnapshot.data()!);
      }

      return userModel;
    } catch (e) {
      throw Exception('Google sign in failed: ${e.toString()}');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  /// Reset password - Now checks if user exists first
  Future<void> resetPassword(String email) async {
    try {
      // Check if user exists in Firestore first
      final querySnapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('email', isEqualTo: email)
          .get()
          .timeout(const Duration(seconds: 10));

      if (querySnapshot.docs.isEmpty) {
        throw Exception('No account found with this email address');
      }

      await _auth.sendPasswordResetEmail(email: email).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout - Please check your internet connection and try again');
        },
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      // Re-throw the "No account found" error or other custom exceptions
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists) {
        return null;
      }

      return UserModel.fromJson(doc.data()!);
    } catch (e) {
      throw Exception('Failed to get user data: ${e.toString()}');
    }
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many requests. Please try again later';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      default:
        return 'Authentication error: ${e.message ?? e.code}';
    }
  }
}
