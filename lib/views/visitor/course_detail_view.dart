import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '/models/course_subcollections_model.dart';
import '/viewmodels/course_viewmodel.dart';

class CourseDetailView extends StatefulWidget {
  final String courseId;

  const CourseDetailView({super.key, required this.courseId});

  @override
  State<CourseDetailView> createState() => _CourseDetailViewState();
}

class _CourseDetailViewState extends State<CourseDetailView> {
  late CourseDetailViewModel _viewModel;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _videoContainerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _viewModel = CourseDetailViewModel();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await _viewModel.loadCourseData(widget.courseId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading course: $e')),
        );
      }
    }
  }

  Future<void> _handleLessonClick(Lesson lesson) async {
    final error = await _viewModel.handleLessonClick(lesson);

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    if (_videoContainerKey.currentContext != null) {
      await Scrollable.ensureVisible(
        _videoContainerKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _addToCart() {
    final error = _viewModel.addToCart();

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_viewModel.course!.title} added to cart'),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => context.push('/student/cart'),
        ),
      ),
    );
  }

  void _buyNow() {
    _viewModel.buyNow();
    context.go('/student/cart');
  }

  void _showReviewDialog() {
    int selectedRating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Write a Review'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rate this course',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < selectedRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 36,
                          ),
                          onPressed: () {
                            setState(() {
                              selectedRating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Share your thoughts (optional)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: commentController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        hintText: 'What did you think about this course?',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(context).pop();

                    final error = await _viewModel.submitReview(
                      selectedRating,
                      commentController.text.trim(),
                    );

                    if (mounted) {
                      if (error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(error)),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Review submitted successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Submit Review'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<CourseDetailViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading || viewModel.course == null || viewModel.teacher == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Course Details')),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(viewModel.course!.title),
            ),
            body: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    key: _videoContainerKey,
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 400),
                    child: _buildVideoSection(viewModel),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitleSection(viewModel),
                        const SizedBox(height: 24),
                        _buildStatsSection(viewModel),
                        const SizedBox(height: 24),
                        _buildTeacherSection(viewModel),
                        const SizedBox(height: 24),
                        _buildModulesSection(viewModel),
                        const SizedBox(height: 24),
                        _buildReviewsSection(viewModel),
                        const SizedBox(height: 24),
                        _buildActionButtons(viewModel),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVideoSection(CourseDetailViewModel viewModel) {
    if (viewModel.videoController != null &&
        viewModel.videoController!.value.isInitialized) {
      return Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: viewModel.videoController!.value.aspectRatio,
            child: VideoPlayer(viewModel.videoController!),
          ),
          Positioned.fill(
            child: GestureDetector(
              onTap: () => viewModel.togglePlayback(),
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: viewModel.isPlaying ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Icon(
                        viewModel.isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      viewModel.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: () => viewModel.togglePlayback(),
                  ),
                  Expanded(
                    child: VideoProgressIndicator(
                      viewModel.videoController!,
                      allowScrubbing: true,
                      colors: VideoProgressColors(
                        playedColor: Theme.of(context).primaryColor,
                        bufferedColor: Colors.white30,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder(
                    valueListenable: viewModel.videoController!,
                    builder: (context, VideoPlayerValue value, child) {
                      return Text(
                        '${viewModel.formatDuration(value.position)} / ${viewModel.formatDuration(value.duration)}',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.stop, color: Colors.white),
                    onPressed: () => viewModel.stopVideo(),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Image.network(
      viewModel.course!.thumbnail ?? 'https://via.placeholder.com/800x400',
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: 400,
          color: Colors.grey[300],
          child: const Center(
            child: Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
          ),
        );
      },
    );
  }

  Widget _buildTitleSection(CourseDetailViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          viewModel.course!.title,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          viewModel.course!.description,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        if (viewModel.isEnrolled) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Enrolled',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatsSection(CourseDetailViewModel viewModel) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2,
      children: [
        _buildStatCard(
          icon: Icons.star,
          iconColor: Colors.amber,
          value: viewModel.course!.rating?.toStringAsFixed(1) ?? 'No rating',
          label: 'Rating',
        ),
        _buildStatCard(
          icon: Icons.people,
          iconColor: Colors.blue,
          value: '${viewModel.course!.studentsCount ?? 0}',
          label: 'Students',
        ),
        _buildStatCard(
          icon: Icons.layers,
          iconColor: Colors.green,
          value: viewModel.getCourseLevelDisplay(viewModel.course!.level),
          label: 'Level',
        ),
        _buildStatCard(
          icon: Icons.attach_money,
          iconColor: Colors.purple,
          value: '\$${viewModel.course!.price.toStringAsFixed(2)}',
          label: 'Price',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherSection(CourseDetailViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundImage: viewModel.teacher!.photoURL != null
                ? NetworkImage(viewModel.teacher!.photoURL!)
                : null,
            child: viewModel.teacher!.photoURL == null
                ? const Icon(Icons.person, size: 32)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Instructor',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  viewModel.teacher!.displayName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (viewModel.teacher!.bio != null &&
                    viewModel.teacher!.bio!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    viewModel.teacher!.bio!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModulesSection(CourseDetailViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Course Content (${viewModel.modules.length} modules)',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        viewModel.modules.isEmpty
            ? Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'No modules available yet.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        )
            : ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: viewModel.modules.length,
          itemBuilder: (context, index) {
            final module = viewModel.modules[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                title: Text(
                  'Module ${module.order}: ${module.title}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${module.lessons.length} lesson${module.lessons.length != 1 ? 's' : ''}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                children: [
                  if (module.lessons.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No lessons available in this module.',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    )
                  else
                    ...module.lessons.map((lesson) {
                      final isLocked = lesson.locked == LessonLockStatus.locked;
                      final isCurrentLesson = lesson.id == viewModel.currentLessonId;

                      return ListTile(
                        leading: Icon(
                          isLocked
                              ? Icons.lock
                              : (isCurrentLesson && viewModel.isPlaying
                              ? Icons.pause_circle
                              : Icons.play_circle),
                          color: isLocked
                              ? Colors.grey
                              : (isCurrentLesson ? Colors.green : Colors.blue),
                        ),
                        title: Text(
                          lesson.title,
                          style: TextStyle(
                            fontWeight: isCurrentLesson
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: lesson.duration != null
                            ? Text(
                          '${(lesson.duration! / 60).floor()} min',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        )
                            : null,
                        trailing: isLocked
                            ? const Icon(Icons.lock_outline, size: 16)
                            : null,
                        enabled: !isLocked,
                        onTap: () => _handleLessonClick(lesson),
                      );
                    }),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReviewsSection(CourseDetailViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reviews',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (viewModel.totalReviews > 0) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Text(
                    viewModel.averageRating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < viewModel.averageRating.floor()
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${viewModel.totalReviews} review${viewModel.totalReviews != 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final percentage = viewModel.ratingDistribution['$star'] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Text('$star'),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 4),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 35,
                            child: Text(
                              '${percentage.toStringAsFixed(0)}%',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
        viewModel.reviews.isEmpty
            ? Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.rate_review_outlined,
                    size: 48, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text('No reviews yet.', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(
                  'Be the first to review this course!',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        )
            : ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: viewModel.reviews.length,
          itemBuilder: (context, index) {
            final review = viewModel.reviews[index];
            final userId = review.userRef.id;
            final user = viewModel.reviewUsers[userId];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Anonymous',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: List.generate(5, (starIndex) {
                            return Icon(
                              starIndex < review.rating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            );
                          }),
                        ),
                        if (review.comment.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            review.comment,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(CourseDetailViewModel viewModel) {
    // If enrolled, show "Write a Review" button
    if (viewModel.isEnrolled) {
      return Column(
        children: [
          if (!viewModel.hasUserReviewed())
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showReviewDialog,
                icon: const Icon(Icons.rate_review),
                label: const Text('Write a Review'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'You have reviewed this course',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    // If not enrolled, show "Add to Cart" and "Buy Now" buttons
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addToCart,
            icon: const Icon(Icons.shopping_cart_outlined),
            label: Text('Add to Cart - \$${viewModel.course!.price.toStringAsFixed(2)}'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Theme.of(context).primaryColor),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _buyNow,
            icon: const Icon(Icons.shopping_bag),
            label: Text('Buy Now - \$${viewModel.course!.price.toStringAsFixed(2)}'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}