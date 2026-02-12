import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/enrollment_model.dart';

class EnrollmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionPath = 'enrollments';

  // Get reference to enrollments collection
  CollectionReference get _enrollmentsCollection =>
      _firestore.collection(collectionPath);

  // ✅ Get all enrollments
  Future<List<EnrollmentModel>> fetchEnrollments() async {
    try {
      final snapshot = await _enrollmentsCollection.get();
      return snapshot.docs
          .map((doc) => EnrollmentModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Error fetching enrollments: $e');
    }
  }

  // ✅ Get enrollment by ID
  Future<EnrollmentModel?> getEnrollmentById(String id) async {
    try {
      final doc = await _enrollmentsCollection.doc(id).get();
      if (!doc.exists) return null;
      return EnrollmentModel.fromSnapshot(doc);
    } catch (e) {
      throw Exception('Error getting enrollment by ID: $e');
    }
  }

  // ✅ Create enrollment
  Future<DocumentReference> createEnrollment({
    required DocumentReference userRef,
    required DocumentReference courseRef,
    required AccessType accessType,
    DocumentReference? subscriptionRef,
    DocumentReference? paymentRef,
    double progress = 0.0,
    List<String> completedLessons = const [],
    EnrollmentStatus status = EnrollmentStatus.active,
    List<String> completedQuizzes = const [],
    List<QuizAttempt> quizAttempts = const [],
  }) async {
    try {
      // Create the document without ID first
      final docRef = await _enrollmentsCollection.add({
        'userRef': userRef,
        'courseRef': courseRef,
        'accessType': accessType.toJson(),
        'subscriptionRef': subscriptionRef,
        'paymentRef': paymentRef,
        'progress': progress,
        'completedLessons': completedLessons,
        'status': status.toJson(),
        'enrolledAt': FieldValue.serverTimestamp(),
        'completedQuizzes': completedQuizzes,
        'quizAttempts': quizAttempts.map((e) => e.toJson()).toList(),
      });

      // Update the document to include its own ID
      await docRef.update({'id': docRef.id});

      return docRef;
    } catch (e) {
      throw Exception('Error creating enrollment: $e');
    }
  }

  // ✅ Create enrollment from model
  Future<String> createEnrollmentFromModel(EnrollmentModel enrollment) async {
    try {
      final docRef = await _enrollmentsCollection.add({
        'userRef': enrollment.userRef,
        'courseRef': enrollment.courseRef,
        'accessType': enrollment.accessType.toJson(),
        'subscriptionRef': enrollment.subscriptionRef,
        'paymentRef': enrollment.paymentRef,
        'progress': enrollment.progress,
        'completedLessons': enrollment.completedLessons,
        'status': enrollment.status.toJson(),
        'enrolledAt': Timestamp.fromDate(enrollment.enrolledAt),
        'completedQuizzes': enrollment.completedQuizzes,
        'quizAttempts': enrollment.quizAttempts.map((e) => e.toJson()).toList(),
      });

      await docRef.update({'id': docRef.id});
      return docRef.id;
    } catch (e) {
      throw Exception('Error creating enrollment from model: $e');
    }
  }

  // ✅ Update enrollment
  Future<void> updateEnrollment(
      String id,
      Map<String, dynamic> updates,
      ) async {
    try {
      await _enrollmentsCollection.doc(id).update(updates);
    } catch (e) {
      throw Exception('Error updating enrollment: $e');
    }
  }

  // ✅ Update enrollment with partial model
  Future<void> updateEnrollmentPartial(
      String id, {
        DocumentReference? userRef,
        DocumentReference? courseRef,
        AccessType? accessType,
        DocumentReference? subscriptionRef,
        DocumentReference? paymentRef,
        double? progress,
        List<String>? completedLessons,
        EnrollmentStatus? status,
        List<String>? completedQuizzes,
        List<QuizAttempt>? quizAttempts,
      }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (userRef != null) updates['userRef'] = userRef;
      if (courseRef != null) updates['courseRef'] = courseRef;
      if (accessType != null) updates['accessType'] = accessType.toJson();
      if (subscriptionRef != null) updates['subscriptionRef'] = subscriptionRef;
      if (paymentRef != null) updates['paymentRef'] = paymentRef;
      if (progress != null) updates['progress'] = progress;
      if (completedLessons != null) updates['completedLessons'] = completedLessons;
      if (status != null) updates['status'] = status.toJson();
      if (completedQuizzes != null) updates['completedQuizzes'] = completedQuizzes;
      if (quizAttempts != null) {
        updates['quizAttempts'] = quizAttempts.map((e) => e.toJson()).toList();
      }

      if (updates.isNotEmpty) {
        await _enrollmentsCollection.doc(id).update(updates);
      }
    } catch (e) {
      throw Exception('Error updating enrollment: $e');
    }
  }

  // ✅ Delete enrollment
  Future<void> deleteEnrollment(String id) async {
    try {
      await _enrollmentsCollection.doc(id).delete();
    } catch (e) {
      throw Exception('Error deleting enrollment: $e');
    }
  }

  // 📊 Additional useful methods

  // Get enrollments for a specific user
  Future<List<EnrollmentModel>> getUserEnrollments(String userId) async {
    try {
      final userRef = _firestore.doc('users/$userId');
      final snapshot = await _enrollmentsCollection
          .where('userRef', isEqualTo: userRef)
          .get();

      return snapshot.docs
          .map((doc) => EnrollmentModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Error getting user enrollments: $e');
    }
  }

  // Stream of user enrollments (real-time updates)
  Stream<List<EnrollmentModel>> getUserEnrollmentsStream(String userId) {
    final userRef = _firestore.doc('users/$userId');
    return _enrollmentsCollection
        .where('userRef', isEqualTo: userRef)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => EnrollmentModel.fromSnapshot(doc))
        .toList());
  }

  // Get enrollments for a specific course
  Future<List<EnrollmentModel>> getCourseEnrollments(String courseId) async {
    try {
      final courseRef = _firestore.doc('courses/$courseId');
      final snapshot = await _enrollmentsCollection
          .where('courseRef', isEqualTo: courseRef)
          .get();

      return snapshot.docs
          .map((doc) => EnrollmentModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Error getting course enrollments: $e');
    }
  }

  // Check if user is enrolled in a course
  Future<EnrollmentModel?> getUserCourseEnrollment(
      String userId,
      String courseId,
      ) async {
    try {
      final userRef = _firestore.doc('users/$userId');
      final courseRef = _firestore.doc('courses/$courseId');

      final snapshot = await _enrollmentsCollection
          .where('userRef', isEqualTo: userRef)
          .where('courseRef', isEqualTo: courseRef)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return EnrollmentModel.fromSnapshot(snapshot.docs.first);
    } catch (e) {
      throw Exception('Error checking user course enrollment: $e');
    }
  }

  // Update progress
  Future<void> updateProgress(String id, double progress) async {
    try {
      await _enrollmentsCollection.doc(id).update({'progress': progress});
    } catch (e) {
      throw Exception('Error updating progress: $e');
    }
  }

  // Mark lesson as completed
  Future<void> markLessonCompleted(String id, String lessonId) async {
    try {
      await _enrollmentsCollection.doc(id).update({
        'completedLessons': FieldValue.arrayUnion([lessonId]),
      });
    } catch (e) {
      throw Exception('Error marking lesson completed: $e');
    }
  }

  // Mark quiz as completed
  Future<void> markQuizCompleted(String id, String quizId) async {
    try {
      await _enrollmentsCollection.doc(id).update({
        'completedQuizzes': FieldValue.arrayUnion([quizId]),
      });
    } catch (e) {
      throw Exception('Error marking quiz completed: $e');
    }
  }

  // Add quiz attempt
  Future<void> addQuizAttempt(String id, QuizAttempt attempt) async {
    try {
      await _enrollmentsCollection.doc(id).update({
        'quizAttempts': FieldValue.arrayUnion([attempt.toJson()]),
      });
    } catch (e) {
      throw Exception('Error adding quiz attempt: $e');
    }
  }

  // Update enrollment status
  Future<void> updateStatus(String id, EnrollmentStatus status) async {
    try {
      await _enrollmentsCollection.doc(id).update({
        'status': status.toJson(),
      });
    } catch (e) {
      throw Exception('Error updating status: $e');
    }
  }
}