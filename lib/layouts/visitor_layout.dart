import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_navbar.dart';
import '../widgets/buttom_bar.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/user_model.dart';

class VisitorLayout extends StatelessWidget {
  final Widget child;

  const VisitorLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final userData = authViewModel.currentUser;
    final navlinks = _getVisitorNavLinks(userData);

    return Scaffold(
      // Show user section if user is logged in
      appBar: CustomAppBar(showUserSection: userData != null),
      body: Column(
        children: [
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(navLinks: navlinks),
    );
  }

  List<NavLink> _getVisitorNavLinks(UserModel? userData) {
    final links = [
      NavLink(path: '/', label: 'Home', icon: Icons.home),
      NavLink(path: '/courses', label: 'Courses', icon: Icons.school),
      NavLink(path: '/plans', label: 'Pricing', icon: Icons.card_giftcard),
    ];

    if (userData == null) {
      links.add(NavLink(
        path: '/signin',
        label: 'Sign In',
        icon: Icons.account_circle,
      ));
    } else {
      if (userData.role == 'student') {
        links.add(NavLink(
          path: '/student',
          label: 'Dashboard',
          icon: Icons.dashboard,
          nofollow: true,
        ));
      }
      if (userData.role == 'teacher') {
        links.add(NavLink(
          path: '/teacher',
          label: 'Dashboard',
          icon: Icons.dashboard,
          nofollow: true,
        ));
      }
      if (userData.role == 'admin') {
        links.add(NavLink(
          path: '/admin',
          label: 'Dashboard',
          icon: Icons.admin_panel_settings,
          nofollow: true,
        ));
      }
    }

    return links;
  }
}