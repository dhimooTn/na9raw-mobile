import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialLink {
  final IconData icon;
  final String url;
  final String label;

  const SocialLink({required this.icon, required this.url, required this.label});
}

class AppFooter extends StatefulWidget {
  const AppFooter({super.key});

  @override
  State<AppFooter> createState() => _AppFooterState();
}

class _AppFooterState extends State<AppFooter> {
  static const List<SocialLink> _socialLinks = [
    SocialLink(
      icon: Icons.facebook,
      url: 'https://facebook.com/na9raw',
      label: 'Follow us on Facebook',
    ),
    SocialLink(
      icon: Icons.camera_alt,
      url: 'https://instagram.com/na9raw',
      label: 'Follow us on Instagram',
    ),
    SocialLink(
      icon: Icons.business,
      url: 'https://linkedin.com/company/na9raw',
      label: 'Follow us on LinkedIn',
    ),
  ];

  Future<void> _launchUrl(String urlString) async {
    try {
      await launchUrl(
        Uri.parse(urlString),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _socialLinks.map((link) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: IconButton(
              icon: Icon(link.icon),
              iconSize: 20,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
              tooltip: link.label,
              onPressed: () => _launchUrl(link.url),
            ),
          );
        }).toList(),
      ),
    );
  }
}