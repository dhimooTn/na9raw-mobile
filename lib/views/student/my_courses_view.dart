import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/services/enrollment_service.dart';
import '/services/course_service.dart';
import '/models/enrollment_model.dart';
import '/models/course_model.dart';
import '/utils/style/app_radius.dart';

// ════════════════════════════════════════════════════════════════════════════
// DATA MODEL
// ════════════════════════════════════════════════════════════════════════════

class EnrolledCourseData {
  final CourseModel course;
  final EnrollmentModel enrollment;

  EnrolledCourseData({
    required this.course,
    required this.enrollment,
  });
}

// ════════════════════════════════════════════════════════════════════════════
// MAIN VIEW
// ════════════════════════════════════════════════════════════════════════════

class MyCoursesView extends StatefulWidget {
  const MyCoursesView({super.key});

  @override
  State<MyCoursesView> createState() => _MyCoursesViewState();
}

class _MyCoursesViewState extends State<MyCoursesView>
    with SingleTickerProviderStateMixin {
  final EnrollmentService _enrollmentService = EnrollmentService();
  final CourseService _courseService = CourseService();

  late TabController _tabController;
  List<EnrolledCourseData>? _enrolledCourses;
  bool _isLoading = true;
  String? _error;

  String _searchQuery = '';
  String _selectedCategory = 'all';
  String _selectedLevel = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadEnrolledCourses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // DATA LOADING
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _loadEnrolledCourses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final enrollments = await _enrollmentService.getUserEnrollments(userId);
      final List<EnrolledCourseData> enrolledCourses = [];

      for (final enrollment in enrollments) {
        try {
          final courseId = enrollment.courseRef.id;
          final course = await _courseService.getCourseById(courseId);

          if (course != null) {
            enrolledCourses.add(EnrolledCourseData(
              course: course,
              enrollment: enrollment,
            ));
          }
        } catch (e) {
          debugPrint('Error loading course ${enrollment.courseRef.id}: $e');
        }
      }

      setState(() {
        _enrolledCourses = enrolledCourses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load courses: $e';
        _isLoading = false;
      });
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // COMPUTED PROPERTIES
  // ──────────────────────────────────────────────────────────────────────────

  List<String> get categories {
    if (_enrolledCourses == null) return ['all'];
    final cats = _enrolledCourses!.map((e) => e.course.category).toSet();
    return ['all', ...cats];
  }

  List<String> get levels {
    if (_enrolledCourses == null) return ['all'];
    final lvls = _enrolledCourses!
        .map((e) => e.course.level.name.toString())
        .toSet();
    return ['all', ...lvls];
  }

  List<EnrolledCourseData> get filteredCourses {
    if (_enrolledCourses == null) return [];

    return _enrolledCourses!.where((item) {
      final matchesSearch = item.course.title
          .toLowerCase()
          .contains(_searchQuery.toLowerCase()) ||
          item.course.description
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      final matchesCategory =
          _selectedCategory == 'all' || item.course.category == _selectedCategory;

      final matchesLevel = _selectedLevel == 'all' ||
          item.course.level.name.toString() == _selectedLevel;

      return matchesSearch && matchesCategory && matchesLevel;
    }).toList();
  }

  List<EnrolledCourseData> get activeCourses {
    return filteredCourses
        .where((item) => item.enrollment.status == EnrollmentStatus.active)
        .toList();
  }

  List<EnrolledCourseData> get completedCourses {
    return filteredCourses
        .where((item) => item.enrollment.status == EnrollmentStatus.completed)
        .toList();
  }

  double get averageProgress {
    if (_enrolledCourses == null || _enrolledCourses!.isEmpty) return 0;
    final total = _enrolledCourses!.fold<double>(
      0,
          (sum, item) => sum + item.enrollment.progress,
    );
    return total / _enrolledCourses!.length;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // NAVIGATION HELPERS
  // ──────────────────────────────────────────────────────────────────────────

  void _navigateToCourseDetail(String courseId) {
    context.go('/courses/$courseId');
  }

  void _navigateToBrowseCourses() {
    context.go('/courses');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // BUILD METHOD
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Courses',
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEnrolledCourses,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(theme, colorScheme),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading your courses...',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Courses',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadEnrolledCourses,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_enrolledCourses == null || _enrolledCourses!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 80,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Courses Yet',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Start learning by enrolling in a course!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToBrowseCourses,
              icon: const Icon(Icons.explore),
              label: const Text('Browse Courses'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsCards(theme, colorScheme),
          const SizedBox(height: 24),
          _buildFilters(theme, colorScheme),
          const SizedBox(height: 24),
          _buildTabs(theme, colorScheme),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // STATS CARDS
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildStatsCards(ThemeData theme, ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800
            ? 3
            : constraints.maxWidth > 400
            ? 2
            : 1;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            _buildStatCard(
              theme: theme,
              colorScheme: colorScheme,
              icon: Icons.book_outlined,
              label: 'Active Courses',
              value: activeCourses.length.toString(),
              color: colorScheme.primary,
            ),
            _buildStatCard(
              theme: theme,
              colorScheme: colorScheme,
              icon: Icons.school,
              label: 'Completed',
              value: completedCourses.length.toString(),
              color: Colors.green,
            ),
            _buildStatCard(
              theme: theme,
              colorScheme: colorScheme,
              icon: Icons.trending_up,
              label: 'Total Progress',
              value: '${averageProgress.round()}%',
              color: Colors.purple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required ThemeData theme,
    required ColorScheme colorScheme,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // FILTERS
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildFilters(ThemeData theme, ColorScheme colorScheme) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: 300,
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Search courses...',
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String>(
            initialValue: _selectedCategory,
            style: theme.textTheme.bodyMedium,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(
                  category == 'all'
                      ? 'All Categories'
                      : '${category[0].toUpperCase()}${category.substring(1)}',
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCategory = value);
              }
            },
          ),
        ),
        SizedBox(
          width: 180,
          child: DropdownButtonFormField<String>(
            initialValue: _selectedLevel,
            style: theme.textTheme.bodyMedium,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: levels.map((level) {
              return DropdownMenuItem(
                value: level,
                child: Text(level == 'all' ? 'All Levels' : level),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedLevel = value);
              }
            },
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // TABS
  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildTabs(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          width: 400,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            labelColor: colorScheme.onPrimary,
            unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.6),
            labelStyle: theme.textTheme.labelLarge,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: 'Active (${activeCourses.length})'),
              Tab(text: 'Completed (${completedCourses.length})'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 600,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCoursesList(activeCourses, true, theme, colorScheme),
              _buildCoursesList(completedCourses, false, theme, colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoursesList(
      List<EnrolledCourseData> courses,
      bool isActive,
      ThemeData theme,
      ColorScheme colorScheme,
      ) {
    if (courses.isEmpty) {
      return _buildEmptyState(isActive, theme, colorScheme);
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        childAspectRatio: 0.75,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        return _EnrolledCourseCard(
          data: courses[index],
          theme: theme,
          colorScheme: colorScheme,
          onTap: () => _navigateToCourseDetail(courses[index].course.id),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isActive, ThemeData theme, ColorScheme colorScheme) {
    final hasFilters = _searchQuery.isNotEmpty ||
        _selectedCategory != 'all' ||
        _selectedLevel != 'all';

    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.book_outlined : Icons.school,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No Active Courses' : 'No Completed Courses',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'No courses match your filters.'
                  : isActive
                  ? 'Start learning by enrolling in a course!'
                  : 'Complete your active courses to see them here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            if (!hasFilters && isActive) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _navigateToBrowseCourses,
                child: const Text('Browse Courses'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// COURSE CARD WIDGET
// ════════════════════════════════════════════════════════════════════════════

class _EnrolledCourseCard extends StatelessWidget {
  final EnrolledCourseData data;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _EnrolledCourseCard({
    required this.data,
    required this.theme,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: colorScheme.surfaceContainerHighest,
                child: data.course.thumbnail != null && data.course.thumbnail!.isNotEmpty
                    ? Image.network(
                  data.course.thumbnail!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(
                        Icons.image,
                        size: 48,
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                    );
                  },
                )
                    : Center(
                  child: Icon(
                    Icons.image,
                    size: 48,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      data.course.title,
                      style: theme.textTheme.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Category & Level badges
                    Row(
                      children: [
                        _buildBadge(
                          context,
                          data.course.category,
                          colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        _buildBadge(
                          context,
                          data.course.level.name.toString(),
                          Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Rating and Students
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              (data.course.rating ?? 0.0).toStringAsFixed(1),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 16,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${data.course.studentsCount ?? 0}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Progress bar
                    LinearProgressIndicator(
                      value: data.enrollment.progress / 100,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        data.enrollment.status == EnrollmentStatus.completed
                            ? Colors.green
                            : colorScheme.primary,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    const SizedBox(height: 8),

                    // Progress text and status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${data.enrollment.progress.round()}% Complete',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (data.enrollment.status == EnrollmentStatus.completed)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(
                                color: Colors.green.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Completed',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HELPER EXTENSION
// ════════════════════════════════════════════════════════════════════════════

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}