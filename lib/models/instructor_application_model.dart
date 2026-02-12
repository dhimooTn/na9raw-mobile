import 'package:cloud_firestore/cloud_firestore.dart';

enum ApplicationStatus {
  pending,
  approved,
  rejected;

  String toJson() => name;

  static ApplicationStatus fromJson(String json) {
    return ApplicationStatus.values.firstWhere(
          (status) => status.name == json,
      orElse: () => ApplicationStatus.pending,
    );
  }
}

class InstructorApplicationModel {
  final String? id;
  final DocumentReference? userRef;
  final String? experience;
  final String? qualifications;
  final String? cvUrl;
  final ApplicationStatus? status;
  final Timestamp? createdAt;
  final DocumentReference? reviewedBy;
  final Timestamp? reviewDate;
  final String? rejectionReason;

  InstructorApplicationModel({
    this.id,
    this.userRef,
    this.experience,
    this.qualifications,
    this.cvUrl,
    this.status,
    this.createdAt,
    this.reviewedBy,
    this.reviewDate,
    this.rejectionReason,
  });

  // Convert from Firestore document
  factory InstructorApplicationModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> snapshot,
      SnapshotOptions? options,
      ) {
    final data = snapshot.data();
    return InstructorApplicationModel(
      id: snapshot.id,
      userRef: data?['userRef'] as DocumentReference?,
      experience: data?['experience'] as String?,
      qualifications: data?['qualifications'] as String?,
      cvUrl: data?['cvUrl'] as String?,
      status: data?['status'] != null
          ? ApplicationStatus.fromJson(data!['status'] as String)
          : null,
      createdAt: data?['createdAt'] as Timestamp?,
      reviewedBy: data?['reviewedBy'] as DocumentReference?,
      reviewDate: data?['reviewDate'] as Timestamp?,
      rejectionReason: data?['rejectionReason'] as String?,
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      if (userRef != null) 'userRef': userRef,
      if (experience != null) 'experience': experience,
      if (qualifications != null) 'qualifications': qualifications,
      if (cvUrl != null) 'cvUrl': cvUrl,
      if (status != null) 'status': status!.toJson(),
      if (createdAt != null) 'createdAt': createdAt,
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (reviewDate != null) 'reviewDate': reviewDate,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    };
  }

  // Convert from JSON map
  factory InstructorApplicationModel.fromJson(Map<String, dynamic> json) {
    return InstructorApplicationModel(
      id: json['id'] as String?,
      userRef: json['userRef'] as DocumentReference?,
      experience: json['experience'] as String?,
      qualifications: json['qualifications'] as String?,
      cvUrl: json['cvUrl'] as String?,
      status: json['status'] != null
          ? ApplicationStatus.fromJson(json['status'] as String)
          : null,
      createdAt: json['createdAt'] as Timestamp?,
      reviewedBy: json['reviewedBy'] as DocumentReference?,
      reviewDate: json['reviewDate'] as Timestamp?,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  // Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userRef != null) 'userRef': userRef,
      if (experience != null) 'experience': experience,
      if (qualifications != null) 'qualifications': qualifications,
      if (cvUrl != null) 'cvUrl': cvUrl,
      if (status != null) 'status': status!.toJson(),
      if (createdAt != null) 'createdAt': createdAt,
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (reviewDate != null) 'reviewDate': reviewDate,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
    };
  }

  // CopyWith method for immutability
  InstructorApplicationModel copyWith({
    String? id,
    DocumentReference? userRef,
    String? experience,
    String? qualifications,
    String? cvUrl,
    ApplicationStatus? status,
    Timestamp? createdAt,
    DocumentReference? reviewedBy,
    Timestamp? reviewDate,
    String? rejectionReason,
  }) {
    return InstructorApplicationModel(
      id: id ?? this.id,
      userRef: userRef ?? this.userRef,
      experience: experience ?? this.experience,
      qualifications: qualifications ?? this.qualifications,
      cvUrl: cvUrl ?? this.cvUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewDate: reviewDate ?? this.reviewDate,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}