import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../models/course_subcollections_model.dart';
import '/services/courseSubcollections/module_service.dart';
import '/services/courseSubcollections/quiz_service.dart';
import '/services/courseSubcollections/review_service.dart';
import '/services/courseSubcollections/comment_service.dart';

// ════════════════════════════════════════════════════════════════════════════
// COURSE SERVICE
// ════════════════════════════════════════════════════════════════════════════

class CourseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _coursesCollection => _db.collection('courses');

  // ──────────────────────────────────────────────────────────────────────────
  // FETCH ALL COURSES
  // ──────────────────────────────────────────────────────────────────────────
  Future<List<CourseModel>> fetchCourses() async {
    try {
      final snapshot = await _coursesCollection.get();
      return snapshot.docs
          .map((doc) => CourseModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch courses: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GET COURSE BY ID
  // ──────────────────────────────────────────────────────────────────────────
  Future<CourseModel?> getCourseById(String id) async {
    try {
      final doc = await _coursesCollection.doc(id).get();
      return doc.exists ? CourseModel.fromFirestore(doc) : null;
    } catch (e) {
      throw Exception('Failed to get course: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ADD COURSE
  // ──────────────────────────────────────────────────────────────────────────
  Future<String> addCourse(CourseModel course) async {
    try {
      final docRef = await _coursesCollection.add({
        ...course.toFirestore(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update with the generated ID
      await updateCourse(docRef.id, {'id': docRef.id});

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add course: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // UPDATE COURSE
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> updateCourse(String id, Map<String, dynamic> updates) async {
    try {
      await _coursesCollection.doc(id).update(updates);
    } catch (e) {
      throw Exception('Failed to update course: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DELETE COURSE
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> deleteCourse(String id) async {
    try {
      await _coursesCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete course: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // GET COURSE WITH DETAILS (including subcollections)
  // ──────────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getCourseWithDetails(String id) async {
    try {
      final doc = await _coursesCollection.doc(id).get();

      if (!doc.exists) return null;

      final course = CourseModel.fromFirestore(doc);

      final results = await Future.wait([
        ModuleService().getModules(id),
        QuizService().getQuizzes(id),
        ReviewService().getReviews(id),
      ]);

      return {
        'course': course,
        'modules': results[0],
        'quizzes': results[1],
        'reviews': results[2],
      };
    } catch (e) {
      throw Exception('Failed to get course with details: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DELETE COURSE CASCADE (with all subcollections)
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> deleteCourseCascade(String id) async {
    try {
      final results = await Future.wait([
        ModuleService().getModules(id),
        QuizService().getQuizzes(id),
        ReviewService().getReviews(id),
        CommentService().getComments(id),
      ]);

      final modules = results[0] as List<Module>;
      final quizzes = results[1] as List<Quiz>;
      final reviews = results[2] as List<CourseReview>;
      final comments = results[3] as List<CourseComment>;

      await Future.wait([
        ...modules.map((m) => ModuleService().deleteModule(id, m.id)),
        ...quizzes.map((q) => QuizService().deleteQuiz(id, q.id)),
        ...reviews.map((r) => ReviewService().deleteReview(id, r.id)),
        ...comments.map((c) => CommentService().deleteComment(id, c.id)),
      ]);

      await _coursesCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete course cascade: $e');
    }
  }
}