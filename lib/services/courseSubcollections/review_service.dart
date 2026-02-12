import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/course_subcollections_model.dart';
class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _reviewsCollection(String courseId) =>
      _db.collection('courses/$courseId/reviews');

  // ──────────────────────────────────────────────────────────────────────────
  // GET REVIEWS
  // ──────────────────────────────────────────────────────────────────────────
  Future<List<CourseReview>> getReviews(String courseId) async {
    try {
      final snapshot = await _reviewsCollection(courseId).get();
      return snapshot.docs
          .map((doc) => CourseReview.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reviews: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ADD OR UPDATE REVIEW
  // ──────────────────────────────────────────────────────────────────────────
  Future<CourseReview> addOrUpdateReview(
      String courseId,
      String userId,
      int rating,
      String comment,
      ) async {
    try {
      final reviewRef = _reviewsCollection(courseId).doc(userId);
      final reviewDoc = await reviewRef.get();

      final payload = {
        'userRef': _db.collection('users').doc(userId),
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (reviewDoc.exists) {
        await reviewRef.update(payload);
      } else {
        await reviewRef.set(payload);
      }

      final updatedDoc = await reviewRef.get();
      return CourseReview.fromFirestore(updatedDoc);
    } catch (e) {
      throw Exception('Failed to add/update review: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DELETE REVIEW
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> deleteReview(String courseId, String reviewId) async {
    try {
      await _reviewsCollection(courseId).doc(reviewId).delete();
    } catch (e) {
      throw Exception('Failed to delete review: $e');
    }
  }
}