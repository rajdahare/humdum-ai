import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/chat_provider.dart';
import '../services/local_storage.dart';
import 'subscription_screen.dart';
import 'subscription_debug_screen.dart';

class ProfileScreen extends StatelessWidget {
  static const routeName = '/profile';
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final sub = context.watch<SubscriptionProvider>();
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Gradient AppBar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Profile',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Hero(
                        tag: 'profile_avatar',
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, size: 48, color: Colors.indigo),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  await context.read<SubscriptionProvider>().refreshFromBackend();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Subscription refreshed')),
                    );
                  }
                },
                tooltip: 'Refresh subscription',
              ),
            ],
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primaryContainer,
                            Theme.of(context).colorScheme.secondaryContainer,
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            auth.user?.email ?? 'Guest',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: sub.isSubscribed 
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey[700],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  sub.isSubscribed ? Icons.verified : Icons.timer,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  sub.isSubscribed
                                      ? sub.currentTier?.name ?? 'Subscribed'
                                      : (sub.inTrial ? '7-Day Free Trial' : 'Free Plan'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Section: Account
                  Text(
                    'ACCOUNT',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStyledCard(
                    context,
                    icon: Icons.workspace_premium,
                    iconColor: Colors.amber,
                    title: 'Manage Subscription',
                    subtitle: 'Upgrade or manage your plan',
                    onTap: () => Navigator.pushNamed(context, SubscriptionScreen.routeName),
                  ),
                  const SizedBox(height: 12),
                  _buildStyledCard(
                    context,
                    icon: Icons.bug_report,
                    iconColor: Colors.orange,
                    title: 'Subscription Debug',
                    subtitle: 'View detailed subscription info',
                    onTap: () => Navigator.pushNamed(context, SubscriptionDebugScreen.routeName),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Section: Settings
                  Text(
                    'SETTINGS',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStyledCard(
                    context,
                    icon: Icons.delete_sweep,
                    iconColor: Colors.red,
                    title: 'Delete Chat Logs',
                    subtitle: 'Clear all chat history',
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Chat Logs'),
                          content: const Text('Are you sure you want to delete all chat logs? This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirmed == true) {
                        // Clear local cache
                        LocalStorage.clearMessages();
                        // Clear chat provider
                        context.read<ChatProvider>().clearMessages();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Chat logs deleted')),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildStyledCard(
                    context,
                    icon: Icons.refresh_rounded,
                    iconColor: Colors.blue,
                    title: 'Reset Chat History',
                    subtitle: 'Clear all conversations and start fresh',
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Reset Chat History?'),
                          content: const Text(
                            'This will permanently delete all conversation history and messages. This action cannot be undone.\n\nUse this if you\'re experiencing errors with chat history.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                              child: const Text('Reset All'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        await LocalStorage.clearAll();
                        await context.read<ChatProvider>().startNewConversation();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Chat history reset successfully!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Section: Logout
                  Text(
                    'ACCOUNT ACTIONS',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStyledCard(
                    context,
                    icon: Icons.logout,
                    iconColor: Colors.grey[700]!,
                    title: 'Logout',
                    subtitle: 'Sign out of your account',
                    onTap: () => context.read<AuthProvider>().signOut(),
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle != null
            ? Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[600]))
            : null,
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }
}


