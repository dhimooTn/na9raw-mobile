import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/firebase_auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  final UserService _userService = UserService();
  final FirebaseAuthService _firebaseAuthService = FirebaseAuthService();
  UserModel? currentUser;

  bool isLoading = false;
  String? errorMessage;

  /// -----------------------------------------
  ///   CHARGER L'UTILISATEUR ACTUEL AU DEMARRAGE
  /// -----------------------------------------
  Future<void> autoLogin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await getCurrentUser(user.uid);
  }

  /// -----------------------------------------
  ///             GET USER DATA
  /// -----------------------------------------
  Future<void> getCurrentUser(String uid) async {
    try {
      final userModel = await _userService.getUserById(uid);

      if (userModel == null) {
        errorMessage = "Profil utilisateur introuvable";
        notifyListeners();
        return;
      }

      currentUser = userModel;
      notifyListeners();
    } catch (e) {
      errorMessage = "Erreur lors du chargement du profil: ${e.toString()}";
      notifyListeners();
    }
  }

  /// -----------------------------------------
  ///                 LOGIN
  /// -----------------------------------------
  Future<bool> signIn(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final user = await _firebaseAuthService.signIn(email, password);

      if (user == null) {
        errorMessage = "Erreur de connexion";
        isLoading = false;
        notifyListeners();
        return false;
      }

      // Load user data
      await getCurrentUser(user.uid);

      isLoading = false;
      notifyListeners();
      return currentUser != null;

    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          errorMessage = "Aucun utilisateur trouvé avec cet email";
          break;
        case 'wrong-password':
          errorMessage = "Mot de passe incorrect";
          break;
        case 'invalid-email':
          errorMessage = "Email invalide";
          break;
        case 'invalid-credential':
          errorMessage = "Email ou mot de passe incorrect";
          break;
        default:
          errorMessage = "Erreur de connexion: ${e.message}";
      }
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = "Erreur inattendue: ${e.toString()}";
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// -----------------------------------------
  ///                 SIGN UP
  /// -----------------------------------------
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
    required String role, // "student", "teacher", or "admin"
    String? photoURL,
    String? bio,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Create Firebase Auth account
      final user = await _firebaseAuthService.signUp(email, password);

      if (user == null) {
        errorMessage = "Erreur lors de la création du compte";
        isLoading = false;
        notifyListeners();
        return false;
      }

      final uid = user.uid;

      // Create user document in Firestore matching UserModel structure
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        'email': email,
        'displayName': displayName,
        'role': role,
        'photoURL': photoURL,
        'bio': bio,
        'createdAt': FieldValue.serverTimestamp(),
        'subscriptionRef': null,
        'coursesCreated': [],
        'coursesEnrolled': [],
      });

      // Load the newly created user data
      await getCurrentUser(uid);

      isLoading = false;
      notifyListeners();
      return currentUser != null;

    } on FirebaseAuthException catch (e) {
      // Rollback: delete auth user if Firestore creation fails
      try {
        await FirebaseAuth.instance.currentUser?.delete();
      } catch (_) {}

      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = "Cet email est déjà utilisé";
          break;
        case 'weak-password':
          errorMessage = "Le mot de passe est trop faible (min. 6 caractères)";
          break;
        case 'invalid-email':
          errorMessage = "Email invalide";
          break;
        default:
          errorMessage = "Erreur d'inscription: ${e.message}";
      }
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      // Rollback on any error
      try {
        await FirebaseAuth.instance.currentUser?.delete();
      } catch (_) {}

      errorMessage = "Erreur inattendue: ${e.toString()}";
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// -----------------------------------------
  ///           SIGN IN WITH GOOGLE (FIXED)
  /// -----------------------------------------
  Future<bool> signInWithGoogle() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await _firebaseAuthService.signInWithGoogle();

      if (userCredential == null) {
        errorMessage = "Google Sign-In échoué";
        isLoading = false;
        notifyListeners();
        return false;
      }

      final uid = userCredential.user!.uid;

      // Check if user document exists
      final userModel = await _userService.getUserById(uid);

      if (userModel == null) {
        // Create new user document for first-time Google sign-in
        // FIX: Use userCredential.user instead of userModel (which is null!)
        await FirebaseFirestore.instance.collection("users").doc(uid).set({
          'email': userCredential.user?.email ?? '',
          'displayName': userCredential.user?.displayName ?? 'User',
          'role': 'student', // Default role
          'photoURL': userCredential.user?.photoURL,
          'bio': null,
          'createdAt': FieldValue.serverTimestamp(),
          'subscriptionRef': null,
          'coursesCreated': [],
          'coursesEnrolled': [],
        });
      }

      await getCurrentUser(uid);

      isLoading = false;
      notifyListeners();
      return currentUser != null;

    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = "Un compte existe avec cet email";
          break;
        case 'invalid-credential':
          errorMessage = "Identifiants Google invalides";
          break;
        case 'operation-not-allowed':
          errorMessage = "Google Sign-In non activé";
          break;
        case 'user-disabled':
          errorMessage = "Cet utilisateur a été désactivé";
          break;
        default:
          errorMessage = "Erreur Google Sign-In: ${e.message}";
      }
      isLoading = false;
      notifyListeners();
      return false;

    } catch (e) {
      errorMessage = "Erreur inattendue: ${e.toString()}";
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// -----------------------------------------
  ///             SIGN OUT
  /// -----------------------------------------
  Future<void> signOut() async {
    try {
      await _firebaseAuthService.signOut();
      currentUser = null;
      errorMessage = null;
      notifyListeners();
    } catch (e) {
      errorMessage = "Erreur lors de la déconnexion";
      notifyListeners();
    }
  }

  /// -----------------------------------------
  ///     NAVIGATION APRÈS LOGIN SELON RÔLE
  /// -----------------------------------------
  void navigateAfterLogin(BuildContext context) {
    if (currentUser == null) return;

    final role = currentUser!.role.toLowerCase();

    switch (role) {
      case "student":
        context.go("/student");
        break;
      case "teacher":
        context.go("/teacher");
        break;
      case "admin":
        context.go("/admin");
        break;
      default:
        context.go("/");
        break;
    }
  }
}