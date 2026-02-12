import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/course_model.dart';
import '../../models/course_material_model.dart';
import '../../services/course_service.dart';
import '../../widgets/course_form_fields.dart';
import '../../widgets/course_material_widgets.dart';

class CreateCourseView extends StatefulWidget {
  final CourseModel? course; // Course à modifier (null si création)
  final bool isEditing; // Indique si on est en mode édition

  const CreateCourseView({
    super.key,
    this.course,
    this.isEditing = false,
  });

  @override
  State<CreateCourseView> createState() => _CreateCourseViewState();
}

class _CreateCourseViewState extends State<CreateCourseView> {
  final CourseService _courseService = CourseService();
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _thumbnailController = TextEditingController();

  // Form values
  CourseLevel _selectedLevel = CourseLevel.beginner;
  String? _teacherId;
  bool _isSubmitting = false;
  bool _isSaving = false;

  // Course materials
  final List<CourseMaterial> _courseMaterials = [];

  // Categories
  final List<String> _categories = [
    'Development',
    'Design',
    'Business',
    'Marketing',
    'Music',
    'Photography',
    'Health',
    'Language',
    'Science',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _categoryController.text = _categories[0];
    _getCurrentTeacherId();

    // Charger les données du cours si on est en mode édition
    if (widget.isEditing && widget.course != null) {
      _loadCourseData();
    }
  }

  void _loadCourseData() {
    final course = widget.course!;

    _titleController.text = course.title;
    _descriptionController.text = course.description;
    _categoryController.text = course.category;
    _priceController.text = course.price.toString();
    _thumbnailController.text = course.thumbnail ?? '';
    _selectedLevel = course.level;
  }

  void _getCurrentTeacherId() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() {
        _teacherId = currentUser.uid;
      });
    } else {
      setState(() {
        _teacherId = 'demo_teacher_id';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Using demo teacher ID. Please sign in for production.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _thumbnailController.dispose();
    super.dispose();
  }

  Future<void> _saveAsDraft() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a course title to save as draft')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.isEditing && widget.course != null) {
        // Mise à jour du cours existant
        await _courseService.updateCourse(widget.course!.id, {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'category': _categoryController.text.trim(),
          'level': _selectedLevel.name[0].toUpperCase() + _selectedLevel.name.substring(1),
          'price': double.tryParse(_priceController.text) ?? 0.0,
          'thumbnail': _thumbnailController.text.trim().isNotEmpty
              ? _thumbnailController.text.trim()
              : null,
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'Course updated successfully'
                : 'Course saved as draft'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _publishCourse() async {
    if (_formKey.currentState!.validate()) {
      if (_teacherId == null || _teacherId!.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Teacher ID is not available. Please sign in.')),
          );
        }
        return;
      }

      setState(() => _isSubmitting = true);

      try {
        if (widget.isEditing && widget.course != null) {
          // Mise à jour du cours existant
          await _courseService.updateCourse(widget.course!.id, {
            'title': _titleController.text.trim(),
            'description': _descriptionController.text.trim(),
            'category': _categoryController.text.trim(),
            'level': _selectedLevel.name[0].toUpperCase() + _selectedLevel.name.substring(1),
            'price': double.tryParse(_priceController.text) ?? 0.0,
            'thumbnail': _thumbnailController.text.trim().isNotEmpty
                ? _thumbnailController.text.trim()
                : null,
          });

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Course "${_titleController.text}" updated successfully!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            context.go('/teacher/my-courses');
          }
        } else {
          // Création d'un nouveau cours
          final teacherRef = FirebaseFirestore.instance
              .collection('teachers')
              .doc(_teacherId!);

          final course = CourseModel(
            id: '',
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _categoryController.text.trim(),
            level: _selectedLevel,
            teacherRef: teacherRef,
            price: double.tryParse(_priceController.text) ?? 0.0,
            thumbnail: _thumbnailController.text.trim().isNotEmpty
                ? _thumbnailController.text.trim()
                : null,
            rating: null,
            studentsCount: 0,
            createdAt: Timestamp.now(),
          );

          await _courseService.addCourse(course);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Course "${_titleController.text}" published successfully!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            context.go('/teacher/my-courses');
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to ${widget.isEditing ? "update" : "publish"} course: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }

  void _addMaterial(CourseMaterial material) {
    setState(() {
      _courseMaterials.add(material);
    });
  }

  void _removeMaterial(int index) {
    setState(() {
      _courseMaterials.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Material deleted'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _setThumbnail(String url) {
    setState(() {
      _thumbnailController.text = url;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Header
            _buildHeader(theme),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Course Title
                    CourseFormField(
                      label: 'Course Title',
                      controller: _titleController,
                      hintText: 'e.g., Introduction to Python',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a course title';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Description
                    CourseFormField(
                      label: 'Description',
                      controller: _descriptionController,
                      hintText: 'Tell students about your course...',
                      maxLines: 4,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a course description';
                        }
                        if (value.trim().length < 20) {
                          return 'Description must be at least 20 characters';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Category and Price
                    CourseCategoryPriceRow(
                      categoryController: _categoryController,
                      priceController: _priceController,
                      categories: _categories,
                      onCategoryChanged: (value) {
                        if (value != null) {
                          setState(() => _categoryController.text = value);
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    // Course Level
                    CourseLevelSelector(
                      selectedLevel: _selectedLevel,
                      onLevelChanged: (level) {
                        setState(() {
                          _selectedLevel = level;
                        });
                      },
                    ),

                    const SizedBox(height: 32),

                    // Course Materials Section
                    CourseMaterialsSection(
                      thumbnailController: _thumbnailController,
                      courseMaterials: _courseMaterials,
                      onAddMaterial: _addMaterial,
                      onRemoveMaterial: _removeMaterial,
                      onSetThumbnail: _setThumbnail,
                    ),
                  ],
                ),
              ),
            ),

            // Publish/Update Button
            _buildActionButton(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () => context.go('/teacher/my-courses'),
              ),
              Expanded(
                child: Text(
                  widget.isEditing ? 'Edit Course' : 'Create Course',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              TextButton(
                onPressed: _isSaving ? null : _saveAsDraft,
                child: _isSaving
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(
                  'Save',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _publishCourse,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: _isSubmitting
              ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.onPrimary,
            ),
          )
              : Text(
            widget.isEditing ? 'Update Course' : 'Publish Course',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

// Extension helper - Peut être supprimée si elle existe déjà ailleurs
extension StringCapitalizeExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}