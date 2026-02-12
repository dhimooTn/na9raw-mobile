import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '/viewmodels/auth_viewmodel.dart';
import '/utils/validators.dart';
import '/widgets/auth_widgets.dart'; // Import shared widgets

class SignInView extends StatefulWidget {
  const SignInView({super.key});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitForm(AuthViewModel vm) async {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      final ok = await vm.signIn(email, password);
      if (ok && mounted) {
        if (!context.mounted) return;
        vm.navigateAfterLogin(context);
      }
    }
  }

  Future<void> _signInWithGoogle(AuthViewModel vm) async {
    final ok = await vm.signInWithGoogle();
    if (ok && mounted) {
      if (!context.mounted) return;
      vm.navigateAfterLogin(context);
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
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
                children: [
                  // Home Button
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
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Home',
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
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header with Logo and Title
                    AuthHeader(
                      title: 'Welcome Back',
                      onLogoTap: () => context.go('/'),
                    ),

                    const SizedBox(height: 32),

                    // Form Card
                    AuthFormCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Error Message
                            AuthErrorMessage(errorMessage: vm.errorMessage),
                            if (vm.errorMessage != null) const SizedBox(height: 20),

                            // Email Field
                            AuthTextField(
                              controller: _emailController,
                              label: 'Email address',
                              hintText: 'you@example.com',
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: Validators.validateEmail,
                            ),

                            const SizedBox(height: 20),

                            // Password Field
                            AuthPasswordField(
                              controller: _passwordController,
                              label: 'Password',
                              hintText: '••••••••',
                              obscurePassword: _obscurePassword,
                              onToggleVisibility: _togglePasswordVisibility,
                              validator: Validators.validatePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submitForm(vm),
                            ),

                            const SizedBox(height: 20),

                            // Login Button
                            AuthPrimaryButton(
                              text: 'Login',
                              isLoading: vm.isLoading,
                              onPressed: () => _submitForm(vm),
                            ),

                            const SizedBox(height: 20),

                            // Divider
                            const AuthDivider(),

                            const SizedBox(height: 20),

                            // Google Sign-In Button
                            AuthGoogleButton(
                              isLoading: vm.isLoading,
                              onPressed: () => _signInWithGoogle(vm),
                            ),

                            const SizedBox(height: 20),

                            // Sign Up Link
                            AuthNavigationLink(
                              text: "Don't have an account? ",
                              linkText: 'Create one',
                              onPressed: () => context.go("/signup"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}