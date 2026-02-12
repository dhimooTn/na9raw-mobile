import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SubscriptionPlansView extends StatelessWidget {
  const SubscriptionPlansView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [theme.scaffoldBackgroundColor, theme.cardColor]
                : [Colors.grey[50]!, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
            child: Column(
              children: [
                // Header Section
                Text(
                  'Choose Your Learning Plan',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  constraints: const BoxConstraints(maxWidth: 672),
                  child: Text(
                    'Start with our free plan or upgrade to unlock premium courses and personalized learning experiences.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 48),

                // Plans Grid
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1152),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 1;
                        if (constraints.maxWidth >= 1024) {
                          crossAxisCount = 3;
                        } else if (constraints.maxWidth >= 640) {
                          crossAxisCount = 2;
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 32,
                            mainAxisSpacing: 32,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: _plans.length,
                          itemBuilder: (context, index) {
                            return _PlanCard(plan: _plans[index]);
                          },
                        );
                      },
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

  static final List<_Plan> _plans = [
    _Plan(
      name: 'Free',
      price: '0 TND',
      description: 'Access free courses and join the Na9raw learning community.',
      features: [
        'Access to free courses',
        'Basic profile and progress tracking',
        'Community discussions',
      ],
      icon: Icons.check_circle,
      iconColor: Colors.green,
      featured: false,
    ),
    _Plan(
      name: 'Student Plus',
      price: '25 TND / month',
      description: 'Unlock all premium courses and personalized study tools.',
      features: [
        'All Free plan features',
        'Access to premium courses',
        'Certificates of completion',
        'Offline downloads (mobile app)',
      ],
      icon: Icons.star,
      iconColor: Colors.blue,
      featured: true,
    ),
    _Plan(
      name: 'Student Premium',
      price: '40 TND / month',
      description:
      'Enjoy full Na9raw benefits – advanced analytics and early access to new courses.',
      features: [
        'All Student Plus features',
        'Advanced learning analytics',
        'Early access to new courses',
        'Priority support',
      ],
      icon: Icons.workspace_premium,
      iconColor: Colors.amber,
      featured: false,
    ),
  ];
}

class _Plan {
  final String name;
  final String price;
  final String description;
  final List<String> features;
  final IconData icon;
  final Color iconColor;
  final bool featured;

  _Plan({
    required this.name,
    required this.price,
    required this.description,
    required this.features,
    required this.icon,
    required this.iconColor,
    required this.featured,
  });
}

class _PlanCard extends StatelessWidget {
  final _Plan plan;

  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: plan.featured ? 8 : 2,
      shadowColor: plan.featured
          ? theme.colorScheme.primary.withValues(alpha: 0.3)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: plan.featured
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            Icon(
              plan.icon,
              size: 48,
              color: plan.iconColor,
            ),
            const SizedBox(height: 16),

            // Plan Name
            Text(
              plan.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            // Price
            Text(
              plan.price,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              plan.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Features List
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: plan.features.map((feature) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Button
            SizedBox(
              width: double.infinity,
              child: plan.featured
                  ? ElevatedButton(
                onPressed: () => context.push('/signin'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  plan.price == '0 TND'
                      ? 'Start Learning'
                      : 'Upgrade Now',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
                  : OutlinedButton(
                onPressed: () => context.push('/signin'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  plan.price == '0 TND'
                      ? 'Start Learning'
                      : 'Upgrade Now',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}