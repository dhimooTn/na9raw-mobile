import 'package:flutter/material.dart';

class CourseFilterBottomSheet extends StatefulWidget {
  final String selectedStatus;
  final String selectedCategory;
  final Function(String status, String category) onFilterChanged;

  const CourseFilterBottomSheet({
    super.key,
    required this.selectedStatus,
    required this.selectedCategory,
    required this.onFilterChanged,
  });

  @override
  State<CourseFilterBottomSheet> createState() =>
      _CourseFilterBottomSheetState();
}

class _CourseFilterBottomSheetState extends State<CourseFilterBottomSheet> {
  late String _selectedStatus;
  late String _selectedCategory;

  final List<String> _statuses = ['All', 'Published', 'Draft', 'Rejected'];
  final List<String> _categories = [
    'All',
    'Development',
    'Design',
    'Business',
    'Marketing',
    'Music',
    'Photography',
    'Health',
    'Language',
    'Science',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.selectedStatus;
    _selectedCategory = widget.selectedCategory;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, textTheme),
            const SizedBox(height: 20),
            _buildStatusFilter(colorScheme, textTheme),
            const SizedBox(height: 20),
            _buildCategoryFilter(colorScheme, textTheme),
            const SizedBox(height: 30),
            _buildApplyButton(context, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Filter Courses',
          style: textTheme.headlineSmall?.copyWith(fontSize: 18),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildStatusFilter(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _statuses.map((status) {
            final isSelected = _selectedStatus == status;
            return ChoiceChip(
              label: Text(status, style: const TextStyle(fontSize: 13)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedStatus = status);
              },
              selectedColor: colorScheme.primary.withOpacity(0.15),
              checkmarkColor: colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category;
            return ChoiceChip(
              label: Text(category, style: const TextStyle(fontSize: 13)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedCategory = category);
              },
              selectedColor: colorScheme.primary.withOpacity(0.15),
              checkmarkColor: colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildApplyButton(BuildContext context, ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          widget.onFilterChanged(_selectedStatus, _selectedCategory);
          Navigator.pop(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Apply Filters',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}