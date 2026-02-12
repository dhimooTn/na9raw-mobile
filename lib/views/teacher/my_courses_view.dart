import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/course_model.dart';
import '../../viewmodels/teacher_viewmodel.dart';
import '../../widgets/course_card_widget.dart';
import '../../widgets/course_filter_bottom_sheet.dart';

class MyCoursesView extends StatefulWidget {
  const MyCoursesView({super.key});

  @override
  State<MyCoursesView> createState() => _MyCoursesViewState();
}

class _MyCoursesViewState extends State<MyCoursesView> {
  final TeacherViewModel _viewModel = TeacherViewModel();
  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'All';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _onFilterChanged(String status, String category) {
    setState(() {
      _selectedStatus = status;
      _selectedCategory = category;
    });
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CourseFilterBottomSheet(
        selectedStatus: _selectedStatus,
        selectedCategory: _selectedCategory,
        onFilterChanged: _onFilterChanged,
      ),
    );
  }

  void _showCourseMenu(BuildContext context, CourseModel course) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCourseMenuBottomSheet(context, course),
    );
  }

  Widget _buildCourseMenuBottomSheet(BuildContext context, CourseModel course) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Edit Course
            ListTile(
              leading: Icon(Icons.edit, color: colorScheme.primary),
              title: Text('Edit Course', style: theme.textTheme.bodyMedium),
              onTap: () {
                Navigator.pop(context);
                _viewModel.navigateToCreateCourse(context, course);
              },
            ),

            // Delete Course
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(
                'Delete Course',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context, course);
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, CourseModel course) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Delete Course',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        content: Text(
          'Are you sure you want to delete "${course.title}"? This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _viewModel.deleteCourse(context, course);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context, colorScheme, textTheme),
      body: Column(
        children: [
          _buildSearchBar(context, colorScheme, textTheme),
          _buildFiltersRow(context, colorScheme, textTheme),
          _buildCoursesList(context, colorScheme, textTheme),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context,
      ColorScheme colorScheme,
      TextTheme textTheme,
      ) {
    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      title: Text(
        'My Courses',
        style: textTheme.headlineSmall?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.add, color: colorScheme.onPrimary, size: 20),
          ),
          onPressed: () => _viewModel.navigateToCreateCourse(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar(
      BuildContext context,
      ColorScheme colorScheme,
      TextTheme textTheme,
      ) {
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() {}),
          style: textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Search my courses...',
            hintStyle: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: Icon(
                Icons.clear,
                size: 18,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersRow(
      BuildContext context,
      ColorScheme colorScheme,
      TextTheme textTheme,
      ) {
    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: Row(
        children: [
          InkWell(
            onTap: () => _showFilterOptions(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune, size: 16, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (_selectedStatus != 'All')
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(
                  'Status: $_selectedStatus',
                  style: textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
                onDeleted: () => setState(() => _selectedStatus = 'All'),
                backgroundColor: colorScheme.surfaceVariant,
                deleteIconColor: colorScheme.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                labelPadding: const EdgeInsets.only(left: 8),
              ),
            ),
          if (_selectedCategory != 'All')
            Chip(
              label: Text(
                'Category: $_selectedCategory',
                style: textTheme.bodyMedium?.copyWith(fontSize: 12),
              ),
              onDeleted: () => setState(() => _selectedCategory = 'All'),
              backgroundColor: colorScheme.surfaceVariant,
              deleteIconColor: colorScheme.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              labelPadding: const EdgeInsets.only(left: 8),
            ),
        ],
      ),
    );
  }

  Widget _buildCoursesList(
      BuildContext context,
      ColorScheme colorScheme,
      TextTheme textTheme,
      ) {
    return Expanded(
      child: StreamBuilder<List<CourseModel>>(
        stream: _viewModel.getTeacherCoursesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(context, colorScheme, textTheme, snapshot.error);
          }

          final courses = snapshot.data ?? [];
          final filteredCourses = _viewModel.filterCourses(
            courses,
            _searchController.text,
            _selectedStatus,
            _selectedCategory,
          );

          if (filteredCourses.isEmpty) {
            return _buildEmptyState(context, colorScheme, textTheme, courses.isEmpty);
          }

          return RefreshIndicator(
            color: colorScheme.primary,
            backgroundColor: colorScheme.surface,
            onRefresh: () => _viewModel.refreshCourses(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredCourses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final course = filteredCourses[index];
                return CourseCardWidget(
                  course: course,
                  onMenuTap: () => _showCourseMenu(context, course),
                  onCardTap: () => _viewModel.navigateToCreateCourse(context, course),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(
      BuildContext context,
      ColorScheme colorScheme,
      TextTheme textTheme,
      Object? error,
      ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error loading courses',
              style: textTheme.headlineSmall?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context,
      ColorScheme colorScheme,
      TextTheme textTheme,
      bool isEmptyCourses,
      ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.school_outlined,
            size: 80,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            isEmptyCourses ? 'No courses yet' : 'No courses found',
            style: textTheme.headlineSmall?.copyWith(
              fontSize: 18,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isEmptyCourses
                ? 'Create your first course to get started'
                : 'Try adjusting your filters',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          if (isEmptyCourses) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _viewModel.navigateToCreateCourse(context),
              icon: const Icon(Icons.add),
              label: const Text('Create First Course'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}