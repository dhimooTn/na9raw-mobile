import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_navbar.dart';
import '../widgets/buttom_bar.dart';
import '../viewmodels/auth_viewmodel.dart';


class AdminLayout extends StatelessWidget {
  final Widget child;

  const AdminLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

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
          )
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(navLinks: _getAdminNavLinks()),
    );
  }

  List<NavLink> _getAdminNavLinks() {
    return [
      NavLink(path: '/admin', label: 'Home', icon: Icons.home),
      NavLink(path: '/admin/courses', label: 'Courses', icon: Icons.library_books),
      NavLink(path: '/admin/users', label: 'Users', icon: Icons.people),
      NavLink(path: '/admin/payments', label: 'Payments', icon: Icons.payment),
      NavLink(path: '/admin/promotions', label: 'Promotions', icon: Icons.local_offer),
    ];
  }
}
