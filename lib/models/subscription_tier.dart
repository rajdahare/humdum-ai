class SubscriptionTier {
  final String id;
  final String name;
  final int priceInINR;
  final bool hasScheduling;
  final bool hasGeneralTalk;
  final bool hasAdultTalk; // Night mode with Grok AI
  final bool hasBackgroundListen;
  final List<String> features;

  const SubscriptionTier({
    required this.id,
    required this.name,
    required this.priceInINR,
    required this.hasScheduling,
    required this.hasGeneralTalk,
    required this.hasAdultTalk,
    required this.hasBackgroundListen,
    required this.features,
  });
}

class SubscriptionTiers {
  // Tier 1: ₹1000/month - OpenAI only
  static const SubscriptionTier tier1 = SubscriptionTier(
    id: 'tier1',
    name: 'Basic',
    priceInINR: 1000,
    hasScheduling: true,
    hasGeneralTalk: true,
    hasAdultTalk: false,
    hasBackgroundListen: false,
    features: [
      'Scheduling & Reminders',
      'General AI Talk (OpenAI)',
      'Expense Tracking',
      'Voice Interaction',
      'FunLearn, Health, Finance modes',
    ],
  );

  // Tier 2: ₹1500/month - Tier 1 + Grok AI for Adult mode
  static const SubscriptionTier tier2 = SubscriptionTier(
    id: 'tier2',
    name: 'Premium',
    priceInINR: 1500,
    hasScheduling: true,
    hasGeneralTalk: true,
    hasAdultTalk: true, // Grok AI for adult/night mode
    hasBackgroundListen: false,
    features: [
      'Everything in Basic',
      'Adult Talk Mode (18+) with Grok AI',
      'Age Verification Required',
      'Enhanced Conversational AI',
      'Priority Response Speed',
    ],
  );

  // Tier 3: ₹2000/month - All features
  static const SubscriptionTier tier3 = SubscriptionTier(
    id: 'tier3',
    name: 'Ultimate',
    priceInINR: 2000,
    hasScheduling: true,
    hasGeneralTalk: true,
    hasAdultTalk: true,
    hasBackgroundListen: true,
    features: [
      'Everything in Premium',
      'Background Listen & Smart Suggestions',
      'Detect Misleading Commitments',
      'Real-time Conversation Analysis',
      'Advanced Grok AI Features',
      'Priority Support',
    ],
  );

  static const List<SubscriptionTier> all = [tier1, tier2, tier3];
  
  // Free trial limits (7 days of Tier 1)
  static const int trialDurationDays = 7;
}


