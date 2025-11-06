import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_background.dart';
import '../providers/subscription_provider.dart';
import '../providers/auth_provider.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

class LandingScreen extends StatelessWidget {
  static const routeName = '/landing';
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sub = context.watch<SubscriptionProvider>();
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: const Icon(Icons.favorite, color: Colors.indigo, size: 48),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Humdam / SoulSync',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your AI companion for life, learning, and wellbeing.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: () => Navigator.pushNamed(context, AuthScreen.routeName),
                        icon: const Icon(Icons.login),
                        label: const Text('Get Started'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          if (!sub.inTrial && !sub.isSubscribed) {
                            await context.read<SubscriptionProvider>().startTrial();
                          }
                          if (!context.mounted) return;
                          Navigator.pushReplacementNamed(context, HomeScreen.routeName);
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Try Demo'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: const [
                      _FeatureChip(icon: Icons.nightlight_round, label: 'Night Mode'),
                      _FeatureChip(icon: Icons.psychology, label: 'Health'),
                      _FeatureChip(icon: Icons.school, label: 'FunLearn'),
                      _FeatureChip(icon: Icons.savings, label: 'Finance'),
                      _FeatureChip(icon: Icons.notifications_active, label: 'Reminders'),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(icon, size: 18, color: scheme.primary),
      label: Text(label),
      side: BorderSide(color: scheme.outlineVariant),
      backgroundColor: scheme.surfaceContainerHighest.withOpacity(0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}


