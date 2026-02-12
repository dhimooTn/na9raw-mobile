import 'package:cloud_firestore/cloud_firestore.dart';

// ════════════════════════════════════════════════════════════════════════════
// COURSE MODEL
// ════════════════════════════════════════════════════════════════════════════

enum CourseLevel { beginner, intermediate, advanced }

class CourseModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final CourseLevel level;
  final DocumentReference teacherRef;
  final double price;
  final String? thumbnail;
  final double? rating;
  final int? studentsCount;
  final Timestamp createdAt;

  CourseModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.level,
    required this.teacherRef,
    required this.price,
    this.thumbnail,
    this.rating,
    this.studentsCount,
    required this.createdAt,
  });

  // Factory constructor to create CourseModel from Firestore document
  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CourseModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      level: _parseCourseLevel(data['level']),
      teacherRef: data['teacherRef'] as DocumentReference,
      price: (data['price'] ?? 0).toDouble(),
      thumbnail: data['thumbnail'],
      rating: data['rating']?.toDouble(),
      studentsCount: data['studentsCount'],
      createdAt: data['createdAt'] as Timestamp,
    );
  }

  // Convert CourseModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'level': level.name.capitalize(),
      'teacherRef': teacherRef,
      'price': price,
      'thumbnail': thumbnail,
      'rating': rating,
      'studentsCount': studentsCount,
      'createdAt': createdAt,
    };
  }

  static CourseLevel _parseCourseLevel(String? level) {
    switch (level?.toLowerCase()) {
      case 'beginner':
        return CourseLevel.beginner;
      case 'intermediate':
        return CourseLevel.intermediate;
      case 'advanced':
        return CourseLevel.advanced;
      default:
        return CourseLevel.beginner;
    }
  }

  CourseModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    CourseLevel? level,
    DocumentReference? teacherRef,
    double? price,
    String? thumbnail,
    double? rating,
    int? studentsCount,
    Timestamp? createdAt,
  }) {
    return CourseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      level: level ?? this.level,
      teacherRef: teacherRef ?? this.teacherRef,
      price: price ?? this.price,
      thumbnail: thumbnail ?? this.thumbnail,
      rating: rating ?? this.rating,
      studentsCount: studentsCount ?? this.studentsCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HELPER EXTENSION
// ════════════════════════════════════════════════════════════════════════════

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}