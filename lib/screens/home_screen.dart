import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/subscription_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/mic_button.dart';
import '../widgets/app_background.dart';
import '../widgets/age_verification_modal.dart';
import 'schedule_screen.dart';
import 'expense_screen.dart';
import 'profile_screen.dart';
import 'subscription_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final sub = context.watch<SubscriptionProvider>();
    final pages = [
      _HomeTab(chat: chat, controller: _controller, subscription: sub),
      const ScheduleScreen(),
      const ExpenseScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Humdam / SoulSync'),
        actions: [
          // New Chat button - only show on home tab
          if (_tab == 0)
            IconButton(
              icon: const Icon(Icons.add_comment_outlined),
              onPressed: () {
                // Show confirmation dialog
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Start New Chat?'),
                    content: const Text(
                      'This will clear the current conversation history and start fresh. Your messages will still be saved.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () async {
                          await chat.startNewConversation();
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✨ New conversation started!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: const Text('Start New'),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'Start new conversation',
            ),
          // Voice control button - dynamic based on state
          if (_tab == 0)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: chat.isSpeaking
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    )
                  : null,
              child: IconButton(
                icon: Icon(
                  chat.isSpeaking
                      ? Icons.volume_mute // Show mute when speaking (click to stop)
                      : (chat.isVoiceResponseEnabled 
                          ? Icons.volume_up 
                          : Icons.volume_off),
                  color: chat.isSpeaking
                      ? Theme.of(context).colorScheme.error // Red when speaking (indicates can stop)
                      : null,
                ),
                onPressed: () {
                  if (chat.isSpeaking) {
                    // Stop speaking immediately
                    chat.stopVoice();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Voice stopped'),
                        duration: Duration(milliseconds: 800),
                      ),
                    );
                  } else {
                    // Toggle voice on/off
                    chat.toggleVoiceResponse();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          chat.isVoiceResponseEnabled
                              ? 'Voice enabled'
                              : 'Voice disabled',
                        ),
                        duration: const Duration(milliseconds: 800),
                      ),
                    );
                  }
                },
                tooltip: chat.isSpeaking
                    ? 'Tap to stop speaking'
                    : (chat.isVoiceResponseEnabled ? 'Voice ON (tap to disable)' : 'Voice OFF (tap to enable)'),
              ),
            ),
          PopupMenuButton<ChatMode>(
            onSelected: (mode) async {
              if (mode == ChatMode.night) {
                final sub = context.read<SubscriptionProvider>();
                // Check subscription tier for adult mode
                if (!sub.canAccessAdultMode) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Adult mode requires Premium (Tier 2) or Ultimate (Tier 3) subscription'),
                      action: SnackBarAction(
                        label: 'Upgrade',
                        onPressed: () {
                          Navigator.of(context).pushNamed(SubscriptionScreen.routeName);
                        },
                      ),
                    ),
                  );
                  Future.delayed(const Duration(milliseconds: 500), () {
                    Navigator.of(context).pushNamed(SubscriptionScreen.routeName);
                  });
                  return;
                }
                // Show age verification modal
                if (!mounted) return;
                final verified = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AgeVerificationModal(
                    onVerified: (v) => Navigator.of(ctx).pop(v),
                  ),
                );
                if (verified == true) {
                  chat.setMode(mode);
                }
              } else {
                chat.setMode(mode);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: ChatMode.night, child: Text('Night (18+)')),
              const PopupMenuItem(value: ChatMode.funLearn, child: Text('FunLearn')),
              const PopupMenuItem(value: ChatMode.health, child: Text('Health')),
              const PopupMenuItem(value: ChatMode.finance, child: Text('Finance')),
            ],
          )
        ],
      ),
      body: AppBackground(child: pages[_tab]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home,
                  label: 'Home',
                  isSelected: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
                _NavItem(
                  icon: Icons.event,
                  label: 'Schedule',
                  isSelected: _tab == 1,
                  onTap: () => setState(() => _tab = 1),
                ),
                MicButton(
                  isProcessing: chat.isProcessing,
                  onStop: () {
                    context.read<ChatProvider>().stopProcessing();
                  },
                  onResult: (t) {
                    // Check subscription before sending
                    final sub = context.read<SubscriptionProvider>();
                    if (!sub.canUseAI) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('No active subscription. Subscribe to use AI features.'),
                          action: SnackBarAction(
                            label: 'Subscribe',
                            onPressed: () {
                              Navigator.of(context).pushNamed(SubscriptionScreen.routeName);
                            },
                          ),
                        ),
                      );
                      return;
                    }
                    
                    // Stop any ongoing processing before recording new message
                    if (chat.isProcessing) {
                      context.read<ChatProvider>().stopProcessing();
                    }
                    context.read<ChatProvider>().addUserMessage(t, tierLevel: sub.tierLevel);
                  },
                ),
                _NavItem(
                  icon: Icons.account_balance_wallet,
                  label: 'Expense',
                  isSelected: _tab == 2,
                  onTap: () => setState(() => _tab = 2),
                ),
                _NavItem(
                  icon: Icons.person,
                  label: 'Profile',
                  isSelected: _tab == 3,
                  onTap: () => setState(() => _tab = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final ChatProvider chat;
  final TextEditingController controller;
  final SubscriptionProvider subscription;
  const _HomeTab({required this.chat, required this.controller, required this.subscription});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Subscription status banner
        if (!subscription.canUseAI)
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.errorContainer,
            child: Row(
              children: [
                Icon(Icons.warning, color: Theme.of(context).colorScheme.onErrorContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'No active subscription. Subscribe to use AI features.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(SubscriptionScreen.routeName);
                  },
                  child: const Text('Subscribe'),
                ),
              ],
            ),
          ),
        // Conversation length warning banner
        if (chat.conversationHistory.length >= 15)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
            child: Row(
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Conversation is getting long (${chat.conversationHistory.length} messages). Consider starting a new chat for better performance.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Start New Chat?'),
                        content: const Text(
                          'This will clear the current conversation history and start fresh.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () async {
                              await chat.startNewConversation();
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✨ New conversation started!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            child: const Text('Start New'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('New Chat', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        // Subscription info banner
        if (subscription.canUseAI)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              children: [
                Icon(
                  subscription.inTrial ? Icons.timer_outlined : Icons.verified,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    subscription.inTrial 
                        ? 'Free Trial Active - Tier 1 Features'
                        : '${subscription.currentTier?.name ?? ""} Plan Active',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // New conversation button
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('New'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onPressed: () {
                    chat.startNewConversation();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Started new conversation'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            reverse: true,
            itemCount: chat.messages.length,
            itemBuilder: (ctx, i) => ChatBubble(message: chat.messages[i]),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    enabled: true, // Always enabled - can interrupt
                    decoration: InputDecoration(
                      hintText: chat.isProcessing 
                          ? 'AI is responding... (type to interrupt)' 
                          : (chat.isStopped ? 'Response stopped. Type new message...' : 'Type a message'),
                      border: const OutlineInputBorder(),
                      prefixIcon: chat.isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : (chat.isStopped 
                              ? Icon(Icons.stop_circle, color: Theme.of(context).colorScheme.error)
                              : const Icon(Icons.chat_bubble_outline)),
                    ),
                    onChanged: (value) {
                      // Auto-stop when user starts typing during processing
                      if (chat.isProcessing && value.isNotEmpty) {
                        // Don't stop immediately, wait a bit to avoid interrupting if user is just correcting
                        // But we'll handle it in onSubmitted instead
                      }
                    },
                    onSubmitted: (t) {
                      if (t.trim().isEmpty) return;
                      
                      // Check subscription before sending
                      if (!subscription.canUseAI) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('No active subscription. Subscribe to use AI features.'),
                            action: SnackBarAction(
                              label: 'Subscribe',
                              onPressed: () {
                                Navigator.of(context).pushNamed(SubscriptionScreen.routeName);
                              },
                            ),
                          ),
                        );
                        return;
                      }
                      
                      // Stop current processing if any, then send new message
                      if (chat.isProcessing) {
                        chat.stopProcessing();
                      }
                      chat.addUserMessage(t.trim(), tierLevel: subscription.tierLevel);
                      controller.clear();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                if (chat.isProcessing)
                  FilledButton.icon(
                    icon: const Icon(Icons.stop_circle),
                    label: const Text('Stop'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.errorContainer,
                      foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    onPressed: () {
                      chat.stopProcessing();
                      // Optionally clear input or keep it for new message
                    },
                  )
                else if (chat.isStopped)
                  FilledButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Ready'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    ),
                    onPressed: () {
                      final t = controller.text.trim();
                      if (t.isEmpty) return;
                      
                      // Check subscription before sending
                      if (!subscription.canUseAI) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('No active subscription. Subscribe to use AI features.'),
                            action: SnackBarAction(
                              label: 'Subscribe',
                              onPressed: () {
                                Navigator.of(context).pushNamed(SubscriptionScreen.routeName);
                              },
                            ),
                          ),
                        );
                        return;
                      }
                      
                      chat.addUserMessage(t, tierLevel: subscription.tierLevel);
                      controller.clear();
                    },
                  )
                else
                  FilledButton.icon(
                    icon: const Icon(Icons.send),
                    label: const Text('Send'),
                    onPressed: () {
                      final t = controller.text.trim();
                      if (t.isEmpty) return;
                      
                      // Check subscription before sending
                      if (!subscription.canUseAI) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('No active subscription. Subscribe to use AI features.'),
                            action: SnackBarAction(
                              label: 'Subscribe',
                              onPressed: () {
                                Navigator.of(context).pushNamed(SubscriptionScreen.routeName);
                              },
                            ),
                          ),
                        );
                        return;
                      }
                      
                      chat.addUserMessage(t, tierLevel: subscription.tierLevel);
                      controller.clear();
                    },
                  ),
              ],
            ),
          ),
        )
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? scheme.primary : scheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}


