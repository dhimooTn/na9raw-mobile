import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';

class TeacherViewModel extends ChangeNotifier {
  final CourseService _courseService = CourseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _teacherId;
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  String? get teacherId => _teacherId;

  void initialize() {
    _getCurrentTeacherId();
  }

  Future<void> _getCurrentTeacherId() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _teacherId = currentUser.uid;
    } else {
      _teacherId = 'demo_teacher_id';
    }
    notifyListeners();
  }

  Stream<List<CourseModel>> getTeacherCoursesStream() {
    if (_teacherId == null || _teacherId == 'demo_teacher_id') {
      return _firestore.collection('courses').snapshots().map((snapshot) {
        try {
          final courses = snapshot.docs
              .map((doc) {
            try {
              return CourseModel.fromFirestore(doc);
            } catch (e) {
              debugPrint('Error parsing course ${doc.id}: $e');
              return null;
            }
          })
              .whereType<CourseModel>()
              .toList();
          courses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return courses;
        } catch (e) {
          debugPrint('Error in stream: $e');
          return <CourseModel>[];
        }
      });
    }

    return _firestore.collection('courses').snapshots().map((snapshot) {
      try {
        final courses = snapshot.docs
            .map((doc) {
          try {
            final course = CourseModel.fromFirestore(doc);
            if (course.teacherRef.id == _teacherId) {
              return course;
            }
            return null;
          } catch (e) {
            debugPrint('Error parsing course ${doc.id}: $e');
            return null;
          }
        })
            .whereType<CourseModel>()
            .toList();
        courses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return courses;
      } catch (e) {
        debugPrint('Error in stream: $e');
        return <CourseModel>[];
      }
    });
  }

  Future<void> refreshCourses() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    _isLoading = false;
    notifyListeners();
  }

  List<CourseModel> filterCourses(
      List<CourseModel> courses,
      String searchText,
      String selectedStatus,
      String selectedCategory,
      ) {
    var filtered = courses;

    if (searchText.isNotEmpty) {
      filtered = filtered
          .where((course) =>
      course.title.toLowerCase().contains(searchText.toLowerCase()) ||
          course.description
              .toLowerCase()
              .contains(searchText.toLowerCase()))
          .toList();
    }

    if (selectedStatus != 'All') {
      filtered = filtered.where((course) {
        final status = getStatusLabel(course);
        return status == selectedStatus;
      }).toList();
    }

    if (selectedCategory != 'All') {
      filtered = filtered
          .where((course) => course.category == selectedCategory)
          .toList();
    }

    return filtered;
  }

  String getStatusLabel(CourseModel course) {
    if ((course.studentsCount ?? 0) > 0) {
      return 'Published';
    } else if (course.rating != null && course.rating! < 1.0) {
      return 'Rejected';
    } else {
      return 'Draft';
    }
  }

  Color getStatusColor(String status, BuildContext context) {
    final brightness = Theme.of(context).brightness;

    switch (status.toLowerCase()) {
      case 'published':
        return brightness == Brightness.dark
            ? const Color(0xFF4CAF50)
            : const Color(0xFF2E7D32);
      case 'draft':
        return brightness == Brightness.dark
            ? const Color(0xFFFFA726)
            : const Color(0xFFEF6C00);
      case 'rejected':
        return brightness == Brightness.dark
            ? const Color(0xFFEF5350)
            : const Color(0xFFC62828);
      default:
        return Colors.grey;
    }
  }

  Future<void> deleteCourse(BuildContext context, CourseModel course) async {
    try {
      await _courseService.deleteCourse(course.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Course deleted successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete course: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void navigateToCreateCourse(BuildContext context, [CourseModel? course]) {
    if (course != null) {
      context.push('/teacher/create-course', extra: {
        'course': course,
        'isEditing': true,
      });
    } else {
      context.push('/teacher/create-course');
    }
  }

  void navigateToCourseDetails(BuildContext context, CourseModel course) {
    context.push('/teacher/course/${course.id}', extra: course);
  }

  // ============ DASHBOARD SPECIFIC METHODS ============

  /// Calculer les statistiques à partir de la liste de cours
  Map<String, dynamic> calculateStats(List<CourseModel> courses) {
    int totalStudents = 0;
    int activeCourses = 0;
    int draftCourses = 0;
    double totalRating = 0.0;
    int ratedCourses = 0;
    double totalRevenue = 0.0;

    for (var course in courses) {
      final studentsCount = course.studentsCount ?? 0;
      totalStudents += studentsCount;

      // Un cours est considéré comme actif s'il a au moins 1 étudiant
      if (studentsCount > 0) {
        activeCourses++;
      } else {
        draftCourses++;
      }

      // Calculer la note moyenne
      if (course.rating != null && course.rating! > 0) {
        totalRating += course.rating!;
        ratedCourses++;
      }

      // Calculer le revenu (prix × nombre d'étudiants)
      totalRevenue += studentsCount * course.price;
    }

    return {
      'totalStudents': totalStudents,
      'totalCourses': courses.length,
      'activeCourses': activeCourses,
      'draftCourses': draftCourses,
      'averageRating': ratedCourses > 0 ? totalRating / ratedCourses : 0.0,
      'totalRevenue': totalRevenue,
      'ratedCourses': ratedCourses,
    };
  }

  /// Obtenir une couleur aléatoire pour les cours
  Color getRandomCourseColor(int index) {
    final colors = [
      const Color(0xFF4CAF50),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFE91E63),
      const Color(0xFF00BCD4),
      const Color(0xFFFF5722),
      const Color(0xFF3F51B5),
    ];
    return colors[index % colors.length];
  }

  /// Obtenir les cours récents (3 premiers)
  List<CourseModel> getRecentCourses(List<CourseModel> courses) {
    return courses.take(3).toList();
  }
}