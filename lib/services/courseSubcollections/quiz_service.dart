import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/course_subcollections_model.dart';

// ════════════════════════════════════════════════════════════════════════════
// QUIZ SERVICE
// ════════════════════════════════════════════════════════════════════════════

class QuizService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _quizzesCollection(String courseId) =>
      _db.collection('courses/$courseId/quizzes');

  // ──────────────────────────────────────────────────────────────────────────
  // GET ALL QUIZZES FOR A COURSE
  // ──────────────────────────────────────────────────────────────────────────
  Future<List<Quiz>> getQuizzes(String courseId) async {
    try {
      final snapshot = await _quizzesCollection(courseId).get();
      return snapshot.docs.map((doc) => Quiz.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get quizzes: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GET A SPECIFIC QUIZ BY ID
  // ──────────────────────────────────────────────────────────────────────────
  Future<Quiz?> getQuiz(String courseId, String quizId) async {
    try {
      final doc = await _quizzesCollection(courseId).doc(quizId).get();
      return doc.exists ? Quiz.fromFirestore(doc) : null;
    } catch (e) {
      throw Exception('Failed to get quiz: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ADD A NEW QUIZ
  // ──────────────────────────────────────────────────────────────────────────
  Future<String> addQuiz(String courseId, Quiz quiz) async {
    try {
      final docRef = await _quizzesCollection(courseId).add({
        ...quiz.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add quiz: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UPDATE AN EXISTING QUIZ
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> updateQuiz(
      String courseId,
      String quizId,
      Map<String, dynamic> data,
      ) async {
    try {
      await _quizzesCollection(courseId).doc(quizId).update(data);
    } catch (e) {
      throw Exception('Failed to update quiz: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DELETE A QUIZ
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> deleteQuiz(String courseId, String quizId) async {
    try {
      await _quizzesCollection(courseId).doc(quizId).delete();
    } catch (e) {
      throw Exception('Failed to delete quiz: $e');
    }
  }
}