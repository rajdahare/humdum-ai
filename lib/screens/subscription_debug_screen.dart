import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';

class SubscriptionDebugScreen extends StatelessWidget {
  static const routeName = '/subscription-debug';
  
  const SubscriptionDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sub = context.watch<SubscriptionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Debug'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            context,
            'Subscription Status',
            [
              _buildRow('Has Subscription', sub.isSubscribed),
              _buildRow('In Trial', sub.inTrial),
              _buildRow('Can Use AI', sub.canUseAI),
              _buildRow('Is Processing', sub.isProcessing),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildCard(
            context,
            'Current Tier',
            [
              _buildRow('Tier ID', sub.currentTier?.id ?? 'None'),
              _buildRow('Tier Name', sub.currentTier?.name ?? 'None'),
              _buildRow('Price', sub.currentTier != null 
                ? 'Rs ${sub.currentTier!.priceInINR}/month' 
                : 'N/A'),
              _buildRow('Tier Level (Backend)', sub.tierLevel),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildCard(
            context,
            'Feature Access',
            [
              _buildRow('Adult Mode', sub.canAccessAdultMode),
              _buildRow('Background Listen', sub.canAccessBackgroundListen),
              _buildRow('Scheduling', sub.currentTier?.hasScheduling ?? false),
              _buildRow('General Talk', sub.currentTier?.hasGeneralTalk ?? false),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildCard(
            context,
            'Features List',
            sub.currentTier?.features.map((f) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f)),
                  ],
                ),
              ),
            ).toList() ?? [const Text('No features available')],
          ),
          
          const SizedBox(height: 16),
          
          FilledButton.icon(
            onPressed: () async {
              await sub.refreshFromBackend();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Refreshed subscription from backend')),
                );
              }
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh from Backend'),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, dynamic value) {
    String displayValue;
    Color? valueColor;
    
    if (value is bool) {
      displayValue = value ? 'YES' : 'NO';
      valueColor = value ? Colors.green : Colors.red;
    } else {
      displayValue = value.toString();
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            displayValue,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

