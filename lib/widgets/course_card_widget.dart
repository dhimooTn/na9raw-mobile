import 'package:flutter/material.dart';
import '../models/course_model.dart';

class CourseCardWidget extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onMenuTap;
  final VoidCallback? onCardTap;

  const CourseCardWidget({
    super.key,
    required this.course,
    required this.onMenuTap,
    this.onCardTap,
  });

  String _getStatusLabel(CourseModel course) {
    if ((course.studentsCount ?? 0) > 0) {
      return 'Published';
    } else if (course.rating != null && course.rating! < 1.0) {
      return 'Rejected';
    } else {
      return 'Draft';
    }
  }

  Color _getStatusColor(String status, BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final status = _getStatusLabel(course);
    final statusColor = _getStatusColor(status, context);

    return InkWell(
      onTap: onCardTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThumbnail(colorScheme),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCourseInfo(textTheme, colorScheme, status, statusColor),
              ),
              _buildMenuButton(colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(ColorScheme colorScheme) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: colorScheme.surfaceVariant,
        image: course.thumbnail != null && course.thumbnail!.isNotEmpty
            ? DecorationImage(
          image: NetworkImage(course.thumbnail!),
          fit: BoxFit.cover,
        )
            : null,
      ),
      child: course.thumbnail == null || course.thumbnail!.isEmpty
          ? Icon(
        Icons.image,
        color: colorScheme.onSurfaceVariant,
        size: 30,
      )
          : null,
    );
  }

  Widget _buildCourseInfo(
      TextTheme textTheme,
      ColorScheme colorScheme,
      String status,
      Color statusColor,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          course.title,
          style: textTheme.headlineSmall?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.people, size: 14, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              '${course.studentsCount ?? 0} Students',
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuButton(ColorScheme colorScheme) {
    return IconButton(
      icon: Icon(
        Icons.more_vert,
        color: colorScheme.onSurfaceVariant,
        size: 20,
      ),
      onPressed: onMenuTap,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }
}