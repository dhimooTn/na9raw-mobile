import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '/utils/validators.dart';
import '/utils/style/app_radius.dart';
import '/services/instructor_service.dart';
import '/models/instructor_application_model.dart';

class TeachView extends StatefulWidget {
  const TeachView({super.key});

  @override
  State<TeachView> createState() => _TeachViewState();
}

class _TeachViewState extends State<TeachView> {
  final _formKey = GlobalKey<FormState>();
  final _experienceController = TextEditingController();
  final _qualificationsController = TextEditingController();
  final _instructorService = InstructorService();

  PlatformFile? _cvFile;
  bool _isSubmitting = false;
  bool _isLoading = true;
  bool _isActivating = false;
  InstructorApplicationModel? _existingApplication;

  @override
  void initState() {
    super.initState();
    _checkExistingApplication();
  }

  @override
  void dispose() {
    _experienceController.dispose();
    _qualificationsController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingApplication() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to continue')),
          );
        }
        return;
      }

      final application = await _instructorService.getInstructorApplication(userId);

      setState(() {
        _existingApplication = application;
        _isLoading = false;
      });

      if (application != null && mounted) {
        // Pre-fill form with existing data if pending
        if (application.status == ApplicationStatus.pending) {
          _experienceController.text = application.experience ?? '';
          _qualificationsController.text = application.qualifications ?? '';
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading application: $e')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null) {
        setState(() {
          _cvFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to continue')),
          );
        }
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        await _instructorService.submitInstructorApplication(
          userId: userId,
          experience: _experienceController.text,
          qualifications: _qualificationsController.text,
          cvFile: _cvFile,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Application submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Refresh to show application status
          await _checkExistingApplication();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  Future<void> _activateTeacherRole() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    setState(() {
      _isActivating = true;
    });

    try {
      // Update user role to teacher in Firestore
      await _instructorService.activateTeacherRole(userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teacher role activated! Redirecting to dashboard...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Wait a moment for the snackbar to show
        await Future.delayed(const Duration(milliseconds: 500));

        // Reload the current user to get updated custom claims
        await FirebaseAuth.instance.currentUser?.reload();

        // Get the updated user
        final updatedUser = FirebaseAuth.instance.currentUser;

        // Force get fresh token to refresh claims
        if (updatedUser != null) {
          await updatedUser.getIdToken(true);
        }

        // Navigate to teacher dashboard using GoRouter
        if (mounted) {
          context.go('/teacher');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error activating teacher role: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isActivating = false;
        });
      }
    }
  }

  Widget _buildApplicationStatus() {
    if (_existingApplication == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = _existingApplication!.status;

    Color statusColor;
    IconData statusIcon;
    String statusText;
    String statusMessage;

    switch (status) {
      case ApplicationStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Pending Review';
        statusMessage = 'Your application is currently under review. We\'ll notify you once it\'s processed.';
        break;
      case ApplicationStatus.approved:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Approved';
        statusMessage = 'Congratulations! Your application has been approved. Click the button below to activate your teacher account and access the teacher dashboard.';
        break;
      case ApplicationStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        statusMessage = _existingApplication!.rejectionReason ??
            'Your application was not approved. Please review the requirements and try again.';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 32),
                const SizedBox(width: 12),
                Text(
                  statusText,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              statusMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            if (_existingApplication!.createdAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Submitted: ${_formatDate(_existingApplication!.createdAt!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
            if (_existingApplication!.reviewDate != null) ...[
              Text(
                'Reviewed: ${_formatDate(_existingApplication!.reviewDate!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
            // Add button for approved applications
            if (status == ApplicationStatus.approved) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isActivating ? null : _activateTeacherRole,
                  icon: _isActivating
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                      : const Icon(Icons.school),
                  label: Text(
                    _isActivating ? 'Activating...' : 'Go to Teacher Dashboard',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    backgroundColor: statusColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    DateTime date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If application exists and is approved or pending, show status only
    if (_existingApplication != null &&
        (_existingApplication!.status == ApplicationStatus.approved ||
            _existingApplication!.status == ApplicationStatus.pending)) {
      return Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Instructor Application Status',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildApplicationStatus(),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Show application form
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Section
                Text(
                  'Apply to Become a Teacher',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Welcome! Join our community of educators.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Show previous rejection status if exists
                if (_existingApplication?.status == ApplicationStatus.rejected)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: _buildApplicationStatus(),
                  ),

                // Form Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Professional Experience Field
                          Text(
                            'Professional Experience *',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _experienceController,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              hintText: 'Describe your professional experience...',
                            ),
                            validator: Validators.validateExperience,
                          ),
                          const SizedBox(height: 24),

                          // Educational Qualifications Field
                          Text(
                            'Educational Qualifications *',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _qualificationsController,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              hintText: 'List your educational qualifications...',
                            ),
                            validator: Validators.validateQualifications,
                          ),
                          const SizedBox(height: 24),

                          // CV Upload Section
                          Text(
                            'Upload CV (Optional)',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: _pickFile,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: colorScheme.outline.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.upload_file_outlined,
                                    size: 48,
                                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Upload a file',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        ' or drag and drop',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _cvFile != null
                                        ? _cvFile!.name
                                        : 'PDF, DOC, DOCX up to 10MB',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Bottom Section with Submit Button
                          Container(
                            padding: const EdgeInsets.only(top: 24),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(
                                  color: colorScheme.outline.withValues(alpha: 0.2),
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '* Required fields',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: _isSubmitting ? null : _handleSubmit,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                  ),
                                  child: _isSubmitting
                                      ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.onPrimary,
                                    ),
                                  )
                                      : const Text('Send Application'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}