import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/widgets/course_card.dart';
import '/widgets/course_card_skeleton.dart';
import '/viewmodels/course_viewmodel.dart';

class ExploreCoursesView extends StatefulWidget {
  final String? initialCategory;

  const ExploreCoursesView({super.key, this.initialCategory});

  @override
  State<ExploreCoursesView> createState() => _ExploreCoursesViewState();
}

class _ExploreCoursesViewState extends State<ExploreCoursesView> {
  late ExploreCourseViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = ExploreCourseViewModel();
    _loadCourses();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    try {
      await _viewModel.loadCourses(initialCategory: widget.initialCategory);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading courses: $e')),
        );
      }
    }
  }

  void _onSearchChanged() {
    _viewModel.updateSearchQuery(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        body: Consumer<ExploreCourseViewModel>(
          builder: (context, viewModel, child) {
            return CustomScrollView(
              slivers: [
                // Header Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Explore All Courses',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Discover new skills and advance your career with our course collection.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                // Search and Sort Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Column(
                      children: [
                        // Search Bar
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by course, teacher, or topic...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: viewModel.searchQuery.isNotEmpty
                                ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                viewModel.clearSearch();
                              },
                            )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Category Filter Chips
                        if (viewModel.categories.length > 1)
                          SizedBox(
                            height: 40,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: viewModel.categories.length,
                              itemBuilder: (context, index) {
                                final category = viewModel.categories[index];
                                final isSelected = category == viewModel.selectedCategory;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: FilterChip(
                                    label: Text(category),
                                    selected: isSelected,
                                    onSelected: (_) => viewModel.updateCategory(category),
                                    backgroundColor: Colors.grey[200],
                                    selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                                    checkmarkColor: Theme.of(context).primaryColor,
                                    labelStyle: TextStyle(
                                      color: isSelected
                                          ? Theme.of(context).primaryColor
                                          : Colors.grey[700],
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 12),

                        // Sort Dropdown and Results Count
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${viewModel.displayedCourses.length} courses found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            DropdownButton<String>(
                              value: viewModel.sortOption,
                              items: const [
                                DropdownMenuItem(value: 'none', child: Text('Default')),
                                DropdownMenuItem(value: 'newest', child: Text('Newest')),
                                DropdownMenuItem(value: 'rating', child: Text('Highest Rated')),
                                DropdownMenuItem(value: 'studentsCount', child: Text('Most Popular')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  viewModel.updateSortOption(value);
                                }
                              },
                              underline: Container(),
                              icon: const Icon(Icons.sort),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Courses Grid
                viewModel.isLoading
                    ? SliverToBoxAdapter(
                  child: SizedBox(
                    height: 400,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: 6,
                      itemBuilder: (context, index) => const CourseCardSkeleton(),
                    ),
                  ),
                )
                    : viewModel.displayedCourses.isEmpty
                    ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 100,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No courses found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                )
                    : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final course = viewModel.displayedCourses[index];
                        return CourseCard(course: course);
                      },
                      childCount: viewModel.displayedCourses.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}