import 'package:cloud_firestore/cloud_firestore.dart';

// ════════════════════════════════════════════════════════════════════════════
// COURSE MODULE (Subcollection)
// ════════════════════════════════════════════════════════════════════════════

class Module {
  final String id;
  final String title;
  final int order;
  final List<Lesson> lessons;

  Module({
    required this.id,
    required this.title,
    required this.order,
    required this.lessons,
  });

  factory Module.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Module(
      id: doc.id,
      title: data['title'] ?? '',
      order: data['order'] ?? 0,
      lessons: (data['lessons'] as List<dynamic>?)
          ?.map((lesson) => Lesson.fromMap(lesson as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'order': order,
      'lessons': lessons.map((lesson) => lesson.toMap()).toList(),
    };
  }

  Module copyWith({
    String? id,
    String? title,
    int? order,
    List<Lesson>? lessons,
  }) {
    return Module(
      id: id ?? this.id,
      title: title ?? this.title,
      order: order ?? this.order,
      lessons: lessons ?? this.lessons,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// LESSON MODEL
// ════════════════════════════════════════════════════════════════════════════

enum LessonLockStatus { locked, unlocked }

class Lesson {
  final String id;
  final String type;
  final String title;
  final String? videoUrl;
  final String? thumbnailUrl;
  final int? duration; // in seconds
  final String? description;
  final String? resourceUrl;
  final String? content;
  final int order;
  final LessonLockStatus locked;

  Lesson({
    required this.id,
    required this.type,
    required this.title,
    this.videoUrl,
    this.thumbnailUrl,
    this.duration,
    this.description,
    this.resourceUrl,
    this.content,
    required this.order,
    required this.locked,
  });

  factory Lesson.fromMap(Map<String, dynamic> data) {
    return Lesson(
      id: data['id'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      videoUrl: data['videoUrl'],
      thumbnailUrl: data['thumbnailUrl'],
      duration: data['duration'],
      description: data['description'],
      resourceUrl: data['resourceUrl'],
      content: data['content'],
      order: data['order'] ?? 0,
      locked: data['locked'] == 'locked'
          ? LessonLockStatus.locked
          : LessonLockStatus.unlocked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration,
      'description': description,
      'resourceUrl': resourceUrl,
      'content': content,
      'order': order,
      'locked': locked == LessonLockStatus.locked ? 'locked' : 'unlocked',
    };
  }

  Lesson copyWith({
    String? id,
    String? type,
    String? title,
    String? videoUrl,
    String? thumbnailUrl,
    int? duration,
    String? description,
    String? resourceUrl,
    String? content,
    int? order,
    LessonLockStatus? locked,
  }) {
    return Lesson(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      description: description ?? this.description,
      resourceUrl: resourceUrl ?? this.resourceUrl,
      content: content ?? this.content,
      order: order ?? this.order,
      locked: locked ?? this.locked,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// QUIZ MODEL (Subcollection)
// ════════════════════════════════════════════════════════════════════════════

class Quiz {
  final String id;
  final String title;
  final String description;
  final List<QuizQuestion> questions;
  final int duration; // in minutes
  final int attempts;
  final int passingScore;
  final Timestamp createdAt;

  Quiz({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
    required this.duration,
    required this.attempts,
    required this.passingScore,
    required this.createdAt,
  });

  factory Quiz.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Quiz(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      questions: (data['questions'] as List<dynamic>?)
          ?.map((q) => QuizQuestion.fromMap(q as Map<String, dynamic>))
          .toList() ??
          [],
      duration: data['duration'] ?? 0,
      attempts: data['attempts'] ?? 0,
      passingScore: data['passingScore'] ?? 0,
      createdAt: data['createdAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toMap()).toList(),
      'duration': duration,
      'attempts': attempts,
      'passingScore': passingScore,
      'createdAt': createdAt,
    };
  }

  Quiz copyWith({
    String? id,
    String? title,
    String? description,
    List<QuizQuestion>? questions,
    int? duration,
    int? attempts,
    int? passingScore,
    Timestamp? createdAt,
  }) {
    return Quiz(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      questions: questions ?? this.questions,
      duration: duration ?? this.duration,
      attempts: attempts ?? this.attempts,
      passingScore: passingScore ?? this.passingScore,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// QUIZ QUESTION MODEL
// ════════════════════════════════════════════════════════════════════════════

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> data) {
    return QuizQuestion(
      question: data['question'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctIndex: data['correctIndex'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
    };
  }

  QuizQuestion copyWith({
    String? question,
    List<String>? options,
    int? correctIndex,
  }) {
    return QuizQuestion(
      question: question ?? this.question,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// COURSE REVIEW MODEL (Subcollection)
// ════════════════════════════════════════════════════════════════════════════

class CourseReview {
  final String id;
  final DocumentReference userRef;
  final int rating;
  final String comment;
  final Timestamp createdAt;

  CourseReview({
    required this.id,
    required this.userRef,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory CourseReview.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CourseReview(
      id: doc.id,
      userRef: data['userRef'] as DocumentReference,
      rating: data['rating'] ?? 0,
      comment: data['comment'] ?? '',
      createdAt: data['createdAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userRef': userRef,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
    };
  }

  CourseReview copyWith({
    String? id,
    DocumentReference? userRef,
    int? rating,
    String? comment,
    Timestamp? createdAt,
  }) {
    return CourseReview(
      id: id ?? this.id,
      userRef: userRef ?? this.userRef,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// COURSE COMMENT MODEL (Subcollection)
// ════════════════════════════════════════════════════════════════════════════

class CourseComment {
  final String id;
  final DocumentReference userRef;
  final String text;
  final Timestamp createdAt;
  final String? parentId;
  final int? likes;

  CourseComment({
    required this.id,
    required this.userRef,
    required this.text,
    required this.createdAt,
    this.parentId,
    this.likes,
  });

  factory CourseComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CourseComment(
      id: doc.id,
      userRef: data['userRef'] as DocumentReference,
      text: data['text'] ?? '',
      createdAt: data['createdAt'] as Timestamp,
      parentId: data['parentId'],
      likes: data['likes'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userRef': userRef,
      'text': text,
      'createdAt': createdAt,
      'parentId': parentId,
      'likes': likes,
    };
  }

  CourseComment copyWith({
    String? id,
    DocumentReference? userRef,
    String? text,
    Timestamp? createdAt,
    String? parentId,
    int? likes,
  }) {
    return CourseComment(
      id: id ?? this.id,
      userRef: userRef ?? this.userRef,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      parentId: parentId ?? this.parentId,
      likes: likes ?? this.likes,
    );
  }
}