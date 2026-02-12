import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/course_model.dart';
import '../../viewmodels/teacher_viewmodel.dart';
import '../../widgets/dashboard_widgets.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  late TeacherViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TeacherViewModel();
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Widget _buildDashboardContent(
      BuildContext context,
      List<CourseModel> allCourses,
      ) {
    final theme = Theme.of(context);
    final stats = _viewModel.calculateStats(allCourses);
    final displayCourses = _viewModel.getRecentCourses(allCourses);

    return RefreshIndicator(
      onRefresh: () => _viewModel.refreshCourses(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            DashboardWidgets.buildDashboardHeader(context, stats),

            const SizedBox(height: 24),

            // Your Courses Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Courses',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (allCourses.isNotEmpty)
                    TextButton(
                      onPressed: () => context.push('/teacher/my-courses'),
                      child: Text(
                        'View All (${stats['totalCourses']})',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Courses List
            if (displayCourses.isEmpty)
              DashboardWidgets.buildEmptyState(context)
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: displayCourses.length,
                separatorBuilder: (context, index) =>
                const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final course = displayCourses[index];
                  final courseColor = _viewModel.getRandomCourseColor(index);
                  return DashboardWidgets.buildCourseCard(
                    context,
                    course,
                    index,
                    courseColor,
                  );
                },
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<List<CourseModel>>(
        stream: _viewModel.getTeacherCoursesStream(),
        builder: (context, snapshot) {
          if (_viewModel.isLoading) {
            return DashboardWidgets.buildLoadingState(context);
          }

          if (snapshot.hasError) {
            return DashboardWidgets.buildErrorState(
              context,
              snapshot.error!,
                  () {
                _viewModel.refreshCourses();
                setState(() {});
              },
            );
          }

          if (!snapshot.hasData) {
            return DashboardWidgets.buildEmptyState(context);
          }

          final allCourses = snapshot.data!;

          if (allCourses.isEmpty) {
            return DashboardWidgets.buildEmptyState(context);
          }

          return _buildDashboardContent(context, allCourses);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _viewModel.navigateToCreateCourse(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
        label: Text(
          'Create Course',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}