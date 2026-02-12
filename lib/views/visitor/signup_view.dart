import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '/viewmodels/auth_viewmodel.dart';
import '/utils/validators.dart';
import '/widgets/auth_widgets.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _termsAccepted = false;

  // Role is always "student" by default
  final String _selectedRole = 'student';

  String _passwordStrengthText = 'None';
  Color _passwordStrengthColor = Colors.grey;
  double _passwordStrengthWidth = 0.0;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength(String password) {
    double strength = 0.0;
    String text = 'None';
    Color color = Colors.grey;

    if (password.isNotEmpty) {
      if (password.length >= 8) strength += 0.3;
      if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.3;
      if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.2;
      if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.1;
      if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.1;

      if (strength < 0.4) {
        text = 'Weak';
        color = Theme.of(context).colorScheme.error;
      } else if (strength < 0.7) {
        text = 'Fair';
        color = Colors.orange;
      } else {
        text = 'Strong';
        color = Colors.green;
      }
    }

    setState(() {
      _passwordStrengthText = text;
      _passwordStrengthColor = color;
      _passwordStrengthWidth = strength;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the terms and conditions')),
      );
      return;
    }

    final authViewModel = context.read<AuthViewModel>();

    // Call the updated signUp method with all required parameters
    final success = await authViewModel.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      displayName: _fullNameController.text.trim(),
      role: _selectedRole,
    );

    if (!mounted) return;

    if (success) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate based on role
      authViewModel.navigateAfterLogin(context);
    } else {
      // Error is already shown via Consumer<AuthViewModel>
      // Optionally show a snackbar as well
      if (authViewModel.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authViewModel.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signUpWithGoogle() async {
    final authViewModel = context.read<AuthViewModel>();
    final success = await authViewModel.signInWithGoogle();

    if (!mounted) return;

    if (success) {
      authViewModel.navigateAfterLogin(context);
    } else if (authViewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authViewModel.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          // Top Navigation Bar - NEW
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Home Button (left)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.go('/'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back,
                              size: 20,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Home',
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Sign In Button (right)
                  Material(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => context.go('/signin'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.login,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sign In',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
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

          // Form Content
          Expanded(
            child: SafeArea(
              top: false,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Header
                      AuthHeader(
                        title: 'Create an Account',
                        subtitle: 'Start your learning journey with us.',
                        onLogoTap: () => context.go('/'),
                      ),

                      const SizedBox(height: 32),

                      // Form Card
                      AuthFormCard(
                        child: Consumer<AuthViewModel>(
                          builder: (context, authViewModel, child) {
                            return Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Error Message
                                  AuthErrorMessage(
                                    errorMessage: authViewModel.errorMessage,
                                  ),
                                  if (authViewModel.errorMessage != null)
                                    const SizedBox(height: 16),

                                  // Full Name
                                  AuthTextField(
                                    controller: _fullNameController,
                                    label: 'Full Name',
                                    hintText: 'John Doe',
                                    textInputAction: TextInputAction.next,
                                    validator: Validators.validateName,
                                  ),

                                  const SizedBox(height: 16),

                                  // Email
                                  AuthTextField(
                                    controller: _emailController,
                                    label: 'Email address',
                                    hintText: 'you@example.com',
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validator: Validators.validateEmail,
                                  ),

                                  const SizedBox(height: 16),

                                  // Password
                                  AuthPasswordField(
                                    controller: _passwordController,
                                    label: 'Password',
                                    hintText: '••••••••',
                                    obscurePassword: !_showPassword,
                                    onToggleVisibility: () {
                                      setState(() {
                                        _showPassword = !_showPassword;
                                      });
                                    },
                                    onChanged: _updatePasswordStrength,
                                    validator: Validators.validatePassword,
                                    textInputAction: TextInputAction.next,
                                  ),

                                  const SizedBox(height: 8),

                                  // Password Strength
                                  PasswordStrengthIndicator(
                                    strengthText: _passwordStrengthText,
                                    strengthColor: _passwordStrengthColor,
                                    strengthWidth: _passwordStrengthWidth,
                                  ),

                                  const SizedBox(height: 16),

                                  // Confirm Password
                                  AuthPasswordField(
                                    controller: _confirmPasswordController,
                                    label: 'Confirm Password',
                                    hintText: '••••••••',
                                    obscurePassword: !_showConfirmPassword,
                                    onToggleVisibility: () {
                                      setState(() {
                                        _showConfirmPassword = !_showConfirmPassword;
                                      });
                                    },
                                    validator: (value) =>
                                        Validators.validateConfirmPassword(
                                          value,
                                          _passwordController.text,
                                        ),
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _submitForm(),
                                  ),

                                  const SizedBox(height: 16),

                                  // Terms and Conditions
                                  TermsCheckbox(
                                    value: _termsAccepted,
                                    onChanged: (value) {
                                      setState(() {
                                        _termsAccepted = value ?? false;
                                      });
                                    },
                                  ),

                                  const SizedBox(height: 24),

                                  // Sign Up Button
                                  AuthPrimaryButton(
                                    text: 'Sign Up',
                                    isLoading: authViewModel.isLoading,
                                    onPressed: _submitForm,
                                  ),

                                  const SizedBox(height: 20),

                                  // Divider
                                  const AuthDivider(text: 'Or sign up with'),

                                  const SizedBox(height: 20),

                                  // Google Sign Up
                                  AuthGoogleButton(
                                    isLoading: authViewModel.isLoading,
                                    onPressed: _signUpWithGoogle,
                                  ),

                                  const SizedBox(height: 20),

                                  // Sign In Link
                                  AuthNavigationLink(
                                    text: 'Already have an account? ',
                                    linkText: 'Sign in',
                                    onPressed: () => context.go('/signin'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}