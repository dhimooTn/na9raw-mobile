import 'package:cloud_firestore/cloud_firestore.dart';

// Enum pour le type d'accès
enum AccessType {
  subscription,
  single;

  String toJson() => name;

  static AccessType fromJson(String json) {
    return AccessType.values.firstWhere((e) => e.name == json);
  }
}

// Enum pour le statut
enum EnrollmentStatus {
  active,
  completed,
  expired;

  String toJson() => name;

  static EnrollmentStatus fromJson(String json) {
    return EnrollmentStatus.values.firstWhere((e) => e.name == json);
  }
}

// Model pour QuizAttempt (à adapter selon votre structure)
class QuizAttempt {
  final String quizId;
  final int score;
  final DateTime attemptedAt;

  QuizAttempt({
    required this.quizId,
    required this.score,
    required this.attemptedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'score': score,
      'attemptedAt': Timestamp.fromDate(attemptedAt),
    };
  }

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      quizId: json['quizId'] as String,
      score: json['score'] as int,
      attemptedAt: (json['attemptedAt'] as Timestamp).toDate(),
    );
  }
}

// Model principal EnrollmentModel
class EnrollmentModel {
  final String id;
  final DocumentReference userRef;
  final DocumentReference courseRef;
  final AccessType accessType;
  final DocumentReference? subscriptionRef;
  final DocumentReference? paymentRef;
  final double progress;
  final List<String> completedLessons;
  final EnrollmentStatus status;
  final DateTime enrolledAt;
  final List<String> completedQuizzes;
  final List<QuizAttempt> quizAttempts;

  EnrollmentModel({
    required this.id,
    required this.userRef,
    required this.courseRef,
    required this.accessType,
    this.subscriptionRef,
    this.paymentRef,
    required this.progress,
    this.completedLessons = const [],
    required this.status,
    required this.enrolledAt,
    this.completedQuizzes = const [],
    this.quizAttempts = const [],
  });

  // Conversion vers Map pour Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userRef': userRef,
      'courseRef': courseRef,
      'accessType': accessType.toJson(),
      'subscriptionRef': subscriptionRef,
      'paymentRef': paymentRef,
      'progress': progress,
      'completedLessons': completedLessons,
      'status': status.toJson(),
      'enrolledAt': Timestamp.fromDate(enrolledAt),
      'completedQuizzes': completedQuizzes,
      'quizAttempts': quizAttempts.map((e) => e.toJson()).toList(),
    };
  }

  // Création depuis Firestore DocumentSnapshot
  factory EnrollmentModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EnrollmentModel.fromJson(data, doc.id);
  }

  // Création depuis Map
  factory EnrollmentModel.fromJson(Map<String, dynamic> json, String docId) {
    return EnrollmentModel(
      id: docId,
      userRef: json['userRef'] as DocumentReference,
      courseRef: json['courseRef'] as DocumentReference,
      accessType: AccessType.fromJson(json['accessType'] as String),
      subscriptionRef: json['subscriptionRef'] as DocumentReference?,
      paymentRef: json['paymentRef'] as DocumentReference?,
      progress: (json['progress'] as num).toDouble(),
      completedLessons: List<String>.from(json['completedLessons'] ?? []),
      status: EnrollmentStatus.fromJson(json['status'] as String),
      enrolledAt: (json['enrolledAt'] as Timestamp).toDate(),
      completedQuizzes: List<String>.from(json['completedQuizzes'] ?? []),
      quizAttempts: (json['quizAttempts'] as List?)
          ?.map((e) => QuizAttempt.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  // Méthode copyWith pour la mutation immutable
  EnrollmentModel copyWith({
    String? id,
    DocumentReference? userRef,
    DocumentReference? courseRef,
    AccessType? accessType,
    DocumentReference? subscriptionRef,
    DocumentReference? paymentRef,
    double? progress,
    List<String>? completedLessons,
    EnrollmentStatus? status,
    DateTime? enrolledAt,
    List<String>? completedQuizzes,
    List<QuizAttempt>? quizAttempts,
  }) {
    return EnrollmentModel(
      id: id ?? this.id,
      userRef: userRef ?? this.userRef,
      courseRef: courseRef ?? this.courseRef,
      accessType: accessType ?? this.accessType,
      subscriptionRef: subscriptionRef ?? this.subscriptionRef,
      paymentRef: paymentRef ?? this.paymentRef,
      progress: progress ?? this.progress,
      completedLessons: completedLessons ?? this.completedLessons,
      status: status ?? this.status,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      completedQuizzes: completedQuizzes ?? this.completedQuizzes,
      quizAttempts: quizAttempts ?? this.quizAttempts,
    );
  }
}

