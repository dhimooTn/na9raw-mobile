import 'package:flutter/foundation.dart';
import '/models/course_model.dart';
import '/services/course_service.dart';
import '/services/enrollment_service.dart';

class StudentViewModel extends ChangeNotifier {
  final CourseService _courseService = CourseService();
  final EnrollmentService _enrollmentService = EnrollmentService();

  List<CourseModel> _allCourses = [];
  List<CourseModel> _availableCourses = [];
  List<CourseModel> _displayedCourses = [];
  List<String> _categories = ['All'];

  String _selectedCategory = 'All';
  String _searchQuery = '';
  String _sortOption = 'none';
  bool _isLoading = false;

  // Getters
  List<CourseModel> get displayedCourses => _displayedCourses;
  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  String get sortOption => _sortOption;
  bool get isLoading => _isLoading;

  /// Load courses that the user is NOT enrolled in
  Future<void> loadAvailableCourses(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch all courses
      _allCourses = await _courseService.fetchCourses();

      // Fetch user's enrollments using the correct method
      final enrollments = await _enrollmentService.getUserEnrollments(userId);

      // Extract enrolled course IDs from DocumentReferences
      final enrolledCourseIds = <String>{};
      for (var enrollment in enrollments) {
        // Get the course ID from the DocumentReference
        final courseId = enrollment.courseRef.id;
        enrolledCourseIds.add(courseId);
      }

      // Filter out enrolled courses
      _availableCourses = _allCourses
          .where((course) => !enrolledCourseIds.contains(course.id))
          .toList();

      // Extract unique categories from available courses only
      _categories = ['All'];
      final categorySet = _availableCourses
          .map((c) => c.category)
          .where((cat) => cat.isNotEmpty)
          .toSet();
      _categories.addAll(categorySet.toList()..sort());

      // Apply initial filters
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading available courses: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update category filter
  void updateCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  /// Update search query
  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    _applyFilters();
  }

  /// Update sort option
  void updateSortOption(String option) {
    _sortOption = option;
    _applyFilters();
  }

  /// Apply all filters and sorting
  void _applyFilters() {
    var filtered = List<CourseModel>.from(_availableCourses);

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((course) => course.category == _selectedCategory)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((course) {
        final titleMatch = course.title.toLowerCase().contains(_searchQuery);
        final descMatch = course.description.toLowerCase().contains(_searchQuery);
        final categoryMatch = course.category.toLowerCase().contains(_searchQuery);
        return titleMatch || descMatch || categoryMatch;
      }).toList();
    }

    // Sort
    switch (_sortOption) {
      case 'newest':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'rating':
        filtered.sort((a, b) {
          final ratingA = a.rating ?? 0;
          final ratingB = b.rating ?? 0;
          return ratingB.compareTo(ratingA);
        });
        break;
      case 'studentsCount':
        filtered.sort((a, b) {
          final countA = a.studentsCount ?? 0;
          final countB = b.studentsCount ?? 0;
          return countB.compareTo(countA);
        });
        break;
      case 'none':
      default:
      // Keep original order
        break;
    }

    _displayedCourses = filtered;
    notifyListeners();
  }
}