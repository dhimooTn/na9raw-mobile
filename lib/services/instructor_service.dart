import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '/models/instructor_application_model.dart';
import '/services/user_service.dart';

class InstructorService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  /// Submit a new instructor application
  Future<Map<String, dynamic>> submitInstructorApplication({
    required String userId,
    required String experience,
    required String qualifications,
    PlatformFile? cvFile,
  }) async {
    // Check for existing application
    final existingApp = await getInstructorApplication(userId);
    if (existingApp != null) {
      throw Exception('You already have an existing application');
    }

    final userRef = _db.collection('users').doc(userId);

    final instructorApplication = InstructorApplicationModel(
      userRef: userRef,
      experience: experience,
      qualifications: qualifications,
      cvUrl: cvFile?.name ?? 'unknown',
      status: ApplicationStatus.pending,
      createdAt: Timestamp.now(),
    );

    final applicationRef = await _db
        .collection('instructorApplications')
        .add(instructorApplication.toFirestore());

    // Update the document with its own ID
    await applicationRef.update({'id': applicationRef.id});

    return {
      'id': applicationRef.id,
      'success': true,
    };
  }

  /// Get instructor application by user ID
  Future<InstructorApplicationModel?> getInstructorApplication(
      String userId,
      ) async {
    final userRef = _db.collection('users').doc(userId);

    final querySnapshot = await _db
        .collection('instructorApplications')
        .where('userRef', isEqualTo: userRef)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    return InstructorApplicationModel.fromFirestore(
      querySnapshot.docs.first,
      null,
    );
  }

  /// Get all pending instructor applications
  Future<List<InstructorApplicationModel>> getPendingInstructorApplications() async {
    final querySnapshot = await _db
        .collection('instructorApplications')
        .where('status', isEqualTo: 'pending')
        .get();

    final apps = <InstructorApplicationModel>[];

    for (final docSnap in querySnapshot.docs) {
      final app = InstructorApplicationModel.fromFirestore(docSnap, null);
      apps.add(app);
    }

    return apps;
  }

  /// Update instructor application status
  /// Automatically changes user role to "teacher" when approved
  Future<void> updateInstructorApplicationStatus({
    required String id,
    required ApplicationStatus status,
    required DocumentReference reviewedByRef,
    String? rejectionReason,
  }) async {
    final docRef = _db.collection('instructorApplications').doc(id);

    // Get the application to access user reference
    final appDoc = await docRef.get();
    if (!appDoc.exists) {
      throw Exception('Application not found');
    }

    final appData = InstructorApplicationModel.fromFirestore(
      appDoc,
      null,
    );

    final payload = <String, dynamic>{
      'status': status.toJson(),
      'reviewedBy': reviewedByRef,
      'reviewDate': Timestamp.now(),
    };

    if (status == ApplicationStatus.rejected && rejectionReason != null) {
      payload['rejectionReason'] = rejectionReason;
    }

    // Update application status
    await docRef.update(payload);

    // If approved, change user role to teacher
    if (status == ApplicationStatus.approved && appData.userRef != null) {
      final userId = appData.userRef!.id;
      await _userService.updateUser(userId, {'role': 'teacher'});
    }
  }

  /// Activate teacher role for approved user
  /// This method is called when user clicks "Go to Teacher Dashboard" button
  Future<void> activateTeacherRole(String userId) async {
    // Verify the user has an approved application
    final application = await getInstructorApplication(userId);

    if (application == null) {
      throw Exception('No instructor application found');
    }

    if (application.status != ApplicationStatus.approved) {
      throw Exception('Your application is not approved yet');
    }

    // Update user role to teacher
    await _userService.updateUser(userId, {'role': 'teacher'});
  }

  /// Get instructor application by ID
  Future<InstructorApplicationModel?> getInstructorApplicationById(
      String id,
      ) async {
    final docSnapshot = await _db
        .collection('instructorApplications')
        .doc(id)
        .get();

    if (!docSnapshot.exists) {
      return null;
    }

    return InstructorApplicationModel.fromFirestore(docSnapshot, null);
  }

  /// Get all instructor applications with optional status filter
  Future<List<InstructorApplicationModel>> getAllInstructorApplications({
    ApplicationStatus? statusFilter,
  }) async {
    Query query = _db.collection('instructorApplications');

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter.toJson());
    }

    final querySnapshot = await query.get();

    return querySnapshot.docs
        .map((doc) => InstructorApplicationModel.fromFirestore(
      doc as DocumentSnapshot<Map<String, dynamic>>,
      null,
    ))
        .toList();
  }

  /// Delete instructor application
  Future<void> deleteInstructorApplication(String id) async {
    await _db.collection('instructorApplications').doc(id).delete();
  }

  /// Approve instructor application (helper method)
  Future<void> approveInstructorApplication({
    required String applicationId,
    required DocumentReference reviewedByRef,
  }) async {
    await updateInstructorApplicationStatus(
      id: applicationId,
      status: ApplicationStatus.approved,
      reviewedByRef: reviewedByRef,
    );
  }

  /// Reject instructor application (helper method)
  Future<void> rejectInstructorApplication({
    required String applicationId,
    required DocumentReference reviewedByRef,
    required String rejectionReason,
  }) async {
    await updateInstructorApplicationStatus(
      id: applicationId,
      status: ApplicationStatus.rejected,
      reviewedByRef: reviewedByRef,
      rejectionReason: rejectionReason,
    );
  }
}