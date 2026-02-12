import 'package:flutter/material.dart';
import '../models/course_model.dart';
import '../viewmodels/teacher_viewmodel.dart';

class CourseMenuBottomSheet extends StatelessWidget {
  final CourseModel course;
  final TeacherViewModel viewModel;

  const CourseMenuBottomSheet({
    super.key,
    required this.course,
    required this.viewModel,
  });

  void _showDeleteDialog(BuildContext context) {
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
              await viewModel.deleteCourse(context, course);
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

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            ListTile(
              leading: Icon(Icons.edit, color: colorScheme.primary),
              title: Text('Edit Course', style: theme.textTheme.bodyMedium),
              onTap: () {
                Navigator.pop(context);
                viewModel.navigateToCreateCourse(context, course);
              },
            ),
            ListTile(
              leading: Icon(Icons.visibility, color: colorScheme.primary),
              title: Text('View Details', style: theme.textTheme.bodyMedium),
              onTap: () {
                Navigator.pop(context);
                viewModel.navigateToCourseDetails(context, course);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(
                'Delete Course',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}