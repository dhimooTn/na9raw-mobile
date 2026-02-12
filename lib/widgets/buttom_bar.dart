import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavLink {
  final String path;
  final String label;
  final IconData icon;
  final bool nofollow;

  NavLink({
    required this.path,
    required this.label,
    required this.icon,
    this.nofollow = false,
  });
}

class CustomBottomNavBar extends StatelessWidget {
  final List<NavLink> navLinks;

  const CustomBottomNavBar({
    super.key,
    required this.navLinks,
  });

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final theme = Theme.of(context);

    return SafeArea(
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          color: theme.bottomNavigationBarTheme.backgroundColor ??
              theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: navLinks.map((link) {
            final isActive = _isLinkActive(currentPath, link.path);

            return Expanded(
              child: _NavBarItem(
                icon: link.icon,
                label: link.label,
                isActive: isActive,
                onTap: () {
                  context.go(link.path);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  bool _isLinkActive(String currentPath, String linkPath) {
    if (linkPath == '/') {
      return currentPath == '/';
    }
    // For dashboard links, check if current path starts with the link path
    if (linkPath == '/student' ||
        linkPath == '/teacher' ||
        linkPath == '/admin') {
      return currentPath.startsWith(linkPath);
    }
    return currentPath.startsWith(linkPath);
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final color = isActive
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.6);

    return InkWell(
      onTap: onTap,
      splashColor: colorScheme.primary.withValues(alpha: 0.1),
      highlightColor: colorScheme.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}