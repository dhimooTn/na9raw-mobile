import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_navbar.dart';
import '../widgets/buttom_bar.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/user_model.dart';

class TeacherLayout extends StatelessWidget {
  final Widget child;

  const TeacherLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final userData = authViewModel.currentUser;
    final navlinks = _getTeacherNavLinks(userData);

    return Scaffold(
      appBar: CustomAppBar(showUserSection: true),
      body: Column(
        children: [
          Expanded(
            child: authViewModel.isLoading
                ? const Center(
              child: CircularProgressIndicator(),
            )
                : child,
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(navLinks: navlinks),
    );
  }

  List<NavLink> _getTeacherNavLinks(UserModel? userData) {
    final links = [
      NavLink(path: '/teacher', label: 'Home', icon: Icons.home),
      NavLink(path: '/teacher/my-courses', label: 'My Courses', icon: Icons.library_books),
      NavLink(path: '/teacher/create-course', label: 'Create', icon: Icons.add_circle),
    ];

    if (userData?.role == 'admin') {
      links.add(NavLink(
        path: '/student',
        label: 'Student',
        icon: Icons.person,
        nofollow: true,
      ));
      links.add(NavLink(
        path: '/admin',
        label: 'Admin',
        icon: Icons.admin_panel_settings,
        nofollow: true,
      ));
    }

    return links;
  }
}