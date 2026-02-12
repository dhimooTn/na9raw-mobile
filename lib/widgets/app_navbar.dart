import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/user_model.dart';
import '../services/cart_service.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showUserSection;

  const CustomAppBar({
    super.key,
    this.showUserSection = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  String _getInitials(String displayName) {
    if (displayName.isEmpty) return 'U';
    final names = displayName.split(' ');
    if (names.length >= 2) {
      return (names[0][0] + names[1][0]).toUpperCase();
    }
    return displayName[0].toUpperCase();
  }


  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final userData = authViewModel.currentUser;
    final isLoading = authViewModel.isLoading;
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      elevation: 0,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.go('/'),
            child: Image.asset(
              'assets/icons/na9raw-landscape.png',
              width: 128,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Text(
                  'Na9raw',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                );
              },
            ),
          ),
          if (showUserSection)
            _buildAuthenticatedSection(
              context,
              userData,
              authViewModel,
              colorScheme,
              isLoading,
            )
          else
            _buildUnauthenticatedSection(context, colorScheme),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          color: colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
    );
  }

  Widget _buildAuthenticatedSection(
      BuildContext context,
      UserModel? userData,
      AuthViewModel authViewModel,
      ColorScheme colorScheme,
      bool isLoading,
      ) {
    if (isLoading) {
      return _buildLoadingSkeleton(colorScheme);
    }

    if (userData == null) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (userData.role == 'student')
          _buildCartIcon(context, colorScheme),
        InkWell(
          onTap: () {
            context.go('/${userData.role}/profile');
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primary,
              backgroundImage: userData.photoURL != null &&
                  userData.photoURL!.isNotEmpty
                  ? NetworkImage(userData.photoURL!)
                  : null,
              child: userData.photoURL == null || userData.photoURL!.isEmpty
                  ? Text(
                _getInitials(userData.displayName),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimary,
                ),
              )
                  : null,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.logout, color: colorScheme.error),
          tooltip: 'Log out',
          iconSize: 28,
          onPressed: () async {
            final router = GoRouter.of(context);
            await authViewModel.signOut();
            router.go('/');
          },
        ),
      ],
    );
  }

  Widget _buildCartIcon(BuildContext context, ColorScheme colorScheme) {
    // Listen to cart changes using ListenableBuilder
    return ListenableBuilder(
      listenable: CartService(),
      builder: (context, child) {
        final cartService = CartService();
        final itemCount = cartService.itemCount;

        return IconButton(
          icon: Badge(
            label: Text(
              itemCount.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            isLabelVisible: itemCount > 0,
            backgroundColor: colorScheme.error,
            textColor: Colors.white,
            child: Icon(
              Icons.shopping_cart_outlined,
              color: colorScheme.onSurface,
            ),
          ),
          iconSize: 28,
          tooltip: 'Shopping Cart',
          onPressed: () {
            context.go('/student/cart');
          },
        );
      },
    );
  }

  Widget _buildUnauthenticatedSection(
      BuildContext context,
      ColorScheme colorScheme,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: IconButton(
        icon: Icon(
          Icons.person_outline,
          color: colorScheme.primary,
          size: 28,
        ),
        tooltip: 'Log In',
        onPressed: () => context.go('/signin'),
      ),
    );
  }

  Widget _buildLoadingSkeleton(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}