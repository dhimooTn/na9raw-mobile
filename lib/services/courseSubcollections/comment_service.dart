import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/course_subcollections_model.dart';

// ════════════════════════════════════════════════════════════════════════════
// COMMENT SERVICE
// ════════════════════════════════════════════════════════════════════════════

class CommentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _commentsCollection(String courseId) =>
      _db.collection('courses/$courseId/comments');

  // ──────────────────────────────────────────────────────────────────────────
  // GET COMMENTS
  // ──────────────────────────────────────────────────────────────────────────
  Future<List<CourseComment>> getComments(String courseId) async {
    try {
      final snapshot = await _commentsCollection(courseId).get();
      return snapshot.docs
          .map((doc) => CourseComment.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get comments: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ADD COMMENT
  // ──────────────────────────────────────────────────────────────────────────
  Future<String> addComment(
      String courseId,
      String userId,
      String text, {
        String? parentId,
        int? likes,
      }) async {
    try {
      final docRef = await _commentsCollection(courseId).add({
        'userRef': _db.collection('users').doc(userId),
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
        if (parentId != null) 'parentId': parentId,
        'likes': likes ?? 0,
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DELETE COMMENT
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> deleteComment(String courseId, String commentId) async {
    try {
      await _commentsCollection(courseId).doc(commentId).delete();
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }
}