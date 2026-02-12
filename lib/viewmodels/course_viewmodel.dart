import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/models/course_model.dart';
import '/models/course_subcollections_model.dart';
import '/models/user_model.dart';
import '/models/enrollment_model.dart';
import '/services/course_service.dart';
import '/services/user_service.dart';
import '/services/courseSubcollections/module_service.dart'; // FIXED: Typo
import '/services/courseSubcollections/review_service.dart';
import '/services/cart_service.dart';
import '/services/enrollment_service.dart';

/// ViewModel for Course Detail functionality
class CourseDetailViewModel extends ChangeNotifier {
  final CourseService _courseService = CourseService();
  final UserService _userService = UserService();
  final ModuleService _moduleService = ModuleService();
  final ReviewService _reviewService = ReviewService();
  final CartService _cartService = CartService();
  final EnrollmentService _enrollmentService = EnrollmentService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CourseModel? _course;
  UserModel? _teacher;
  List<Module> _modules = [];
  List<CourseReview> _reviews = [];
  Map<String, UserModel> _reviewUsers = {};
  bool _isLoading = true;
  EnrollmentModel? _userEnrollment;

  VideoPlayerController? _videoController;
  String? _currentLessonId;
  bool _isPlaying = false;

  Map<String, double> _ratingDistribution = {
    '5': 0,
    '4': 0,
    '3': 0,
    '2': 0,
    '1': 0,
  };
  double _averageRating = 0.0;
  int _totalReviews = 0;

  // Getters
  CourseModel? get course => _course;
  UserModel? get teacher => _teacher;
  List<Module> get modules => _modules;
  List<CourseReview> get reviews => _reviews;
  Map<String, UserModel> get reviewUsers => _reviewUsers;
  bool get isLoading => _isLoading;
  VideoPlayerController? get videoController => _videoController;
  String? get currentLessonId => _currentLessonId;
  bool get isPlaying => _isPlaying;
  Map<String, double> get ratingDistribution => _ratingDistribution;
  double get averageRating => _averageRating;
  int get totalReviews => _totalReviews;
  bool get isEnrolled => _userEnrollment != null;
  EnrollmentModel? get userEnrollment => _userEnrollment;

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  /// Load all course data
  Future<void> loadCourseData(String courseId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final course = await _courseService.getCourseById(courseId);

      if (course == null) {
        throw Exception('Course not found');
      }

      final teacherId = course.teacherRef.id;
      final teacher = await _userService.getUserById(teacherId);

      // Check if current user is enrolled
      final currentUser = _auth.currentUser;
      EnrollmentModel? enrollment;
      if (currentUser != null) {
        enrollment = await _enrollmentService.getUserCourseEnrollment(
          currentUser.uid,
          courseId,
        );
      }

      final results = await Future.wait([
        _moduleService.getModules(courseId),
        _reviewService.getReviews(courseId),
      ]);

      final modules = results[0] as List<Module>;
      final reviews = results[1] as List<CourseReview>;

      final Map<String, UserModel> reviewUsers = {};
      for (var review in reviews) {
        try {
          final userId = review.userRef.id;
          if (!reviewUsers.containsKey(userId)) {
            final user = await _userService.getUserById(userId);
            if (user != null) {
              reviewUsers[userId] = user;
            }
          }
        } catch (e) {
          debugPrint('Error fetching user for review: $e');
        }
      }

      _calculateRatingStats(reviews);

      _course = course;
      _teacher = teacher;
      _modules = modules;
      _reviews = reviews;
      _reviewUsers = reviewUsers;
      _userEnrollment = enrollment;
      _isLoading = false;

      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Calculate rating statistics
  void _calculateRatingStats(List<CourseReview> reviews) {
    if (reviews.isEmpty) {
      _averageRating = 0.0;
      _totalReviews = 0;
      _ratingDistribution = {'5': 0, '4': 0, '3': 0, '2': 0, '1': 0};
      return;
    }

    _totalReviews = reviews.length;
    double sum = 0;
    Map<int, int> counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

    for (var review in reviews) {
      sum += review.rating;
      counts[review.rating] = (counts[review.rating] ?? 0) + 1;
    }

    _averageRating = double.parse((sum / _totalReviews).toStringAsFixed(1));

    _ratingDistribution = {
      '5': (counts[5]! / _totalReviews * 100),
      '4': (counts[4]! / _totalReviews * 100),
      '3': (counts[3]! / _totalReviews * 100),
      '2': (counts[2]! / _totalReviews * 100),
      '1': (counts[1]! / _totalReviews * 100),
    };
  }

  /// Check if user has already reviewed this course
  bool hasUserReviewed() {
    final currentUser = _auth.currentUser;
    if (currentUser == null || _course == null) return false;

    return _reviews.any((review) => review.userRef.id == currentUser.uid);
  }

  /// Submit a review
  Future<String?> submitReview(int rating, String comment) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return 'You must be logged in to submit a review';
      }

      if (_course == null) {
        return 'Course not found';
      }

      if (!isEnrolled) {
        return 'You must be enrolled in this course to leave a review';
      }

      // Only check if user has reviewed if we're not allowing updates
      // If you want to allow updates, remove this check
      if (hasUserReviewed()) {
        return 'You have already reviewed this course';
      }

      if (rating < 1 || rating > 5) {
        return 'Rating must be between 1 and 5';
      }

      // FIXED: Use positional parameters as defined in ReviewService
      await _reviewService.addOrUpdateReview(
        _course!.id,      // courseId
        currentUser.uid,  // userId
        rating,           // rating
        comment,          // comment
      );

      // Reload course data to refresh reviews
      await loadCourseData(_course!.id);

      return null; // Success
    } catch (e) {
      return 'Error submitting review: $e';
    }
  }

  /// Handle lesson click and video playback
  Future<String?> handleLessonClick(Lesson lesson) async {
    // Check if user is enrolled before checking lesson status
    if (!isEnrolled) {
      // If not enrolled, check if this is the first lesson (usually free preview)
      if (_modules.isNotEmpty && _modules.first.lessons.isNotEmpty) {
        final firstLesson = _modules.first.lessons.first;
        if (lesson.id != firstLesson.id) {
          return 'Please enroll in the course to access all lessons';
        }
      } else {
        return 'Please enroll in the course to access lessons';
      }
    }

    // Check lesson lock status only if enrolled
    if (isEnrolled && lesson.locked == LessonLockStatus.locked) {
      return 'This lesson is locked. Complete previous lessons first.';
    }

    if (lesson.videoUrl == null || lesson.videoUrl!.isEmpty) {
      return 'Video not available for this lesson';
    }

    if (lesson.id == _currentLessonId && _videoController != null) {
      if (_isPlaying) {
        await _videoController!.pause();
        _isPlaying = false;
      } else {
        await _videoController!.play();
        _isPlaying = true;
      }
      notifyListeners();
      return null;
    }

    await _videoController?.dispose();

    _currentLessonId = lesson.id;
    _isPlaying = true;
    _videoController = null;
    notifyListeners();

    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(lesson.videoUrl!),
      );

      await _videoController!.initialize();

      _videoController!.addListener(() {
        if (_videoController!.value.position == _videoController!.value.duration) {
          _isPlaying = false;
          notifyListeners();
        }
      });

      await _videoController!.play();
      notifyListeners();
      return null;
    } catch (e) {
      _isPlaying = false;
      _currentLessonId = null;
      notifyListeners();
      return 'Error loading video: $e';
    }
  }

  /// Toggle video playback
  Future<void> togglePlayback() async {
    if (_videoController == null) return;

    if (_isPlaying) {
      await _videoController!.pause();
      _isPlaying = false;
    } else {
      await _videoController!.play();
      _isPlaying = true;
    }
    notifyListeners();
  }

  /// Stop video and reset
  Future<void> stopVideo() async {
    if (_videoController == null) return;

    await _videoController!.pause();
    await _videoController!.seekTo(Duration.zero);
    _isPlaying = false;
    _currentLessonId = null;
    await _videoController?.dispose();
    _videoController = null;
    notifyListeners();
  }

  /// Add course to cart
  String? addToCart() {
    if (_course == null) return 'Course not found';

    if (_cartService.isInCart(_course!.id)) {
      return 'This course is already in your cart';
    }

    _cartService.addToCart(_course!);
    notifyListeners(); // Notify that cart state might have changed
    return null; // Success
  }

  /// Buy now (add to cart if not already there)
  String? buyNow() {
    if (_course == null) return 'Course not found';

    if (!_cartService.isInCart(_course!.id)) {
      _cartService.addToCart(_course!);
    }
    notifyListeners(); // Notify that cart state might have changed
    return null;
  }

  /// Check if course is in cart
  bool isInCart() {
    if (_course == null) return false;
    return _cartService.isInCart(_course!.id);
  }

  /// Get course level display string
  String getCourseLevelDisplay(CourseLevel level) {
    switch (level) {
      case CourseLevel.beginner:
        return 'Beginner';
      case CourseLevel.intermediate:
        return 'Intermediate';
      case CourseLevel.advanced:
        return 'Advanced';
    }
  }

  /// Format duration for display
  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours > 0 ? '${duration.inHours}:' : '';
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours.isNotEmpty ? '$hours$minutes:$seconds' : '$minutes:$seconds';
  }

  /// Get current user's review if exists
  CourseReview? getCurrentUserReview() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    return _reviews.firstWhere(
          (review) => review.userRef.id == currentUser.uid
    );
  }
}

/// ViewModel for Explore Courses functionality
class ExploreCourseViewModel extends ChangeNotifier {
  final CourseService _courseService = CourseService();

  List<CourseModel> _allCourses = [];
  List<CourseModel> _displayedCourses = [];
  List<String> _categories = ['All'];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortOption = 'none'; // none, newest, rating, studentsCount
  String _selectedCategory = 'All';

  // Getters
  List<CourseModel> get displayedCourses => _displayedCourses;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get sortOption => _sortOption;
  String get selectedCategory => _selectedCategory;

  /// Load all courses
  Future<void> loadCourses({String? initialCategory}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final courses = await _courseService.fetchCourses();

      // Extract unique categories
      final categoriesSet = courses.map((c) => c.category).toSet();
      final sortedCategories = categoriesSet.toList()..sort();

      _allCourses = courses;
      _categories = ['All', ...sortedCategories];

      // Set initial category from parameter
      if (initialCategory != null &&
          initialCategory.isNotEmpty &&
          _categories.contains(initialCategory)) {
        _selectedCategory = initialCategory;
      }

      _filterAndSortCourses();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Update search query
  void updateSearchQuery(String query) {
    _searchQuery = query;
    _filterAndSortCourses();
    notifyListeners();
  }

  /// Clear search query
  void clearSearch() {
    _searchQuery = '';
    _filterAndSortCourses();
    notifyListeners();
  }

  /// Update sort option
  void updateSortOption(String sortOption) {
    _sortOption = sortOption;
    _filterAndSortCourses();
    notifyListeners();
  }

  /// Update selected category
  void updateCategory(String category) {
    _selectedCategory = category;
    _filterAndSortCourses();
    notifyListeners();
  }

  /// Filter and sort courses based on current settings
  void _filterAndSortCourses() {
    List<CourseModel> filtered = _allCourses;

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((course) {
        return course.category == _selectedCategory;
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((course) {
        final query = _searchQuery.toLowerCase();
        final title = course.title.toLowerCase();
        final description = course.description.toLowerCase();
        final category = course.category.toLowerCase();
        return title.contains(query) ||
            description.contains(query) ||
            category.contains(query);
      }).toList();
    }

    // Sort courses
    switch (_sortOption) {
      case 'newest':
        filtered.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
        break;
      case 'rating':
        filtered.sort((a, b) {
          final ratingA = a.rating ?? 0.0;
          final ratingB = b.rating ?? 0.0;
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
      case 'priceLowToHigh':
        filtered.sort((a, b) {
          final priceA = a.price ?? 0.0;
          final priceB = b.price ?? 0.0;
          return priceA.compareTo(priceB);
        });
        break;
      case 'priceHighToLow':
        filtered.sort((a, b) {
          final priceA = a.price ?? 0.0;
          final priceB = b.price ?? 0.0;
          return priceB.compareTo(priceA);
        });
        break;
      default:
      // Keep original order
        break;
    }

    _displayedCourses = filtered;
  }

  /// Reset all filters
  void resetFilters() {
    _searchQuery = '';
    _sortOption = 'none';
    _selectedCategory = 'All';
    _filterAndSortCourses();
    notifyListeners();
  }
}