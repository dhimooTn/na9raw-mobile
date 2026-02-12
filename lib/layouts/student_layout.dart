import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_navbar.dart';
import '../widgets/buttom_bar.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/user_model.dart';
class StudentLayout extends StatelessWidget {
  final Widget child;

  const StudentLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final userData = authViewModel.currentUser;
    final navlinks = _getStudentNavLinks(userData);

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

  List<NavLink> _getStudentNavLinks(UserModel? userData) {
    final links = [
      NavLink(path: '/student', label: 'Home', icon: Icons.home),
      NavLink(path: '/student/mycourses', label: 'My Courses', icon: Icons.library_books),
      NavLink(path: '/student/teach', label: 'Teach', icon: Icons.school),
    ];

    if (userData?.role == 'teacher') {
      links.add(NavLink(
        path: '/teacher',
        label: 'Teacher',
        icon: Icons.person,
        nofollow: true,
      ));
    }

    if (userData?.role == 'admin') {
      links.add(NavLink(
        path: '/teacher',
        label: 'Teacher',
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
