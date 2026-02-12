import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role; // "student", "teacher", "admin"
  final String? photoURL;
  final String? bio;
  final Timestamp createdAt;

  final DocumentReference? subscriptionRef;
  final List<DocumentReference>? coursesCreated;
  final List<DocumentReference>? coursesEnrolled;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.photoURL,
    this.bio,
    required this.createdAt,
    this.subscriptionRef,
    this.coursesCreated,
    this.coursesEnrolled,
  });

  /// -----------------------------
  /// Convert Firestore → Dart Object
  /// -----------------------------
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      role: map['role'] ?? 'student',
      photoURL: map['photoURL'],
      bio: map['bio'],
      createdAt: map['createdAt'] ?? Timestamp.now(),

      subscriptionRef: map['subscriptionRef'],

      coursesCreated: map['coursesCreated'] != null
          ? List<DocumentReference>.from(map['coursesCreated'])
          : null,

      coursesEnrolled: map['coursesEnrolled'] != null
          ? List<DocumentReference>.from(map['coursesEnrolled'])
          : null,
    );
  }

  /// -----------------------------
  /// Convert Dart Object → Firestore
  /// -----------------------------
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'photoURL': photoURL,
      'bio': bio,
      'createdAt': createdAt,
      'subscriptionRef': subscriptionRef,
      'coursesCreated': coursesCreated,
      'coursesEnrolled': coursesEnrolled,
    };
  }
}

