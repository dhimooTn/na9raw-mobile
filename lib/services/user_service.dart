import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionName = 'users';

  /// Get the users collection reference
  CollectionReference get _usersCollection => _db.collection(_collectionName);

  /// -----------------------------
  /// Fetch all users
  /// -----------------------------
  Future<List<UserModel>> fetchUsers() async {
    try {
      final snapshot = await _usersCollection.get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (data == null) return null;
        return UserModel.fromMap(
          data as Map<String, dynamic>,
          doc.id,
        );
      }).whereType<UserModel>().toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  /// -----------------------------
  /// Get user by ID
  /// -----------------------------
  Future<UserModel?> getUserById(String uid) async {
    try {
      final docSnapshot = await _usersCollection.doc(uid).get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          return UserModel.fromMap(
            data as Map<String, dynamic>,
            docSnapshot.id,
          );
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  /// -----------------------------
  /// Create a new user
  /// -----------------------------
  Future<void> createUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  /// -----------------------------
  /// Update user (partial update)
  /// -----------------------------
  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      await _usersCollection.doc(uid).update(updates);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// -----------------------------
  /// Update entire user document
  /// -----------------------------
  Future<void> updateUserModel(UserModel user) async {
    try {
      await _usersCollection.doc(user.uid).set(
        user.toMap(),
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Failed to update user model: $e');
    }
  }

  /// -----------------------------
  /// Delete user
  /// -----------------------------
  Future<void> deleteUser(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// -----------------------------
  /// Stream of all users (real-time updates)
  /// -----------------------------
  Stream<List<UserModel>> usersStream() {
    return _usersCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (data == null) return null;
        return UserModel.fromMap(
          data as Map<String, dynamic>,
          doc.id,
        );
      }).whereType<UserModel>().toList();
    });
  }

  /// -----------------------------
  /// Stream of a single user (real-time updates)
  /// -----------------------------
  Stream<UserModel?> userStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((docSnapshot) {
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          return UserModel.fromMap(
            data as Map<String, dynamic>,
            docSnapshot.id,
          );
        }
      }
      return null;
    });
  }

  /// -----------------------------
  /// Query users by role
  /// -----------------------------
  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      final snapshot = await _usersCollection
          .where('role', isEqualTo: role)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (data == null) return null;
        return UserModel.fromMap(
          data as Map<String, dynamic>,
          doc.id,
        );
      }).whereType<UserModel>().toList();
    } catch (e) {
      throw Exception('Failed to fetch users by role: $e');
    }
  }

  /// -----------------------------
  /// Query users by email
  /// -----------------------------
  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final snapshot = await _usersCollection
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data();
        if (data != null) {
          return UserModel.fromMap(
            data as Map<String, dynamic>,
            doc.id,
          );
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user by email: $e');
    }
  }

  /// -----------------------------
  /// Check if user exists
  /// -----------------------------
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check user existence: $e');
    }
  }

  /// -----------------------------
  /// Add course to teacher's created courses
  /// -----------------------------
  Future<void> addCreatedCourse(String uid, DocumentReference courseRef) async {
    try {
      await _usersCollection.doc(uid).update({
        'coursesCreated': FieldValue.arrayUnion([courseRef]),
      });
    } catch (e) {
      throw Exception('Failed to add created course: $e');
    }
  }

  /// -----------------------------
  /// Remove course from teacher's created courses
  /// -----------------------------
  Future<void> removeCreatedCourse(String uid, DocumentReference courseRef) async {
    try {
      await _usersCollection.doc(uid).update({
        'coursesCreated': FieldValue.arrayRemove([courseRef]),
      });
    } catch (e) {
      throw Exception('Failed to remove created course: $e');
    }
  }

  /// -----------------------------
  /// Add enrollment to student's enrolled courses
  /// -----------------------------
  Future<void> addEnrolledCourse(String uid, DocumentReference enrollmentRef) async {
    try {
      await _usersCollection.doc(uid).update({
        'coursesEnrolled': FieldValue.arrayUnion([enrollmentRef]),
      });
    } catch (e) {
      throw Exception('Failed to add enrolled course: $e');
    }
  }

  /// -----------------------------
  /// Remove enrollment from student's enrolled courses
  /// -----------------------------
  Future<void> removeEnrolledCourse(String uid, DocumentReference enrollmentRef) async {
    try {
      await _usersCollection.doc(uid).update({
        'coursesEnrolled': FieldValue.arrayRemove([enrollmentRef]),
      });
    } catch (e) {
      throw Exception('Failed to remove enrolled course: $e');
    }
  }

  /// -----------------------------
  /// Update user profile (displayName, bio, photoURL)
  /// -----------------------------
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? bio,
    String? photoURL,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (displayName != null) updates['displayName'] = displayName;
      if (bio != null) updates['bio'] = bio;
      if (photoURL != null) updates['photoURL'] = photoURL;

      if (updates.isNotEmpty) {
        await _usersCollection.doc(uid).update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }
}