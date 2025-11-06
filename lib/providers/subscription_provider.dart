import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/subscription_tier.dart';
import '../services/api_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionTier? _currentTier;
  DateTime? _trialEndsAt; // 7-day trial
  String? _processingTierId; // Track which specific tier is being processed

  SubscriptionProvider();

  SubscriptionTier? get currentTier => _currentTier;
  bool get isSubscribed => _currentTier != null;
  bool get inTrial => _trialEndsAt != null && DateTime.now().isBefore(_trialEndsAt!);
  
  // Check if a specific tier is being processed
  bool isProcessingTier(String tierId) => _processingTierId == tierId;
  
  // Check if any tier is being processed
  bool get isProcessing => _processingTierId != null;
  
  // Feature access based on tier
  bool get canAccessAdultMode => (isSubscribed || inTrial) && 
      (_currentTier?.hasAdultTalk ?? false);
  
  bool get canAccessBackgroundListen => isSubscribed && 
      (_currentTier?.hasBackgroundListen ?? false);
  
  // Check if user can use AI (has subscription or trial)
  bool get canUseAI => isSubscribed || inTrial;
  
  // Get tier level (for backend to determine which AI to use)
  String get tierLevel {
    if (!isSubscribed && !inTrial) return 'none';
    if (inTrial) return 'tier1'; // Trial gets Tier 1 features
    return _currentTier?.id ?? 'tier1';
  }
  
  Future<void> startTrial() async {
    _trialEndsAt = DateTime.now().add(Duration(days: SubscriptionTiers.trialDurationDays));
    notifyListeners();
  }

  Razorpay? _razorpay;
  
  Future<bool> subscribe(SubscriptionTier tier, BuildContext context) async {
    _processingTierId = tier.id;
    notifyListeners();
    
    try {
      debugPrint('[Subscription] Creating order for ${tier.id} on platform: ${kIsWeb ? "WEB" : "MOBILE"}');
      
      // FOR WEB: Use Razorpay Standard Checkout (opens in new tab)
      if (kIsWeb) {
        final res = await ApiService.post('/razorpay/create-order', {
          'tier': tier.id,
        });
        
        final orderId = res['orderId'] as String?;
        final keyId = res['keyId'] as String?;
        final amount = res['amount'] as int?;
        
        if (orderId == null || keyId == null) {
          throw Exception('Invalid order response');
        }
        
        // Create Razorpay checkout URL
        final checkoutUrl = 'https://api.razorpay.com/v1/checkout/embedded?key_id=$keyId&order_id=$orderId&amount=$amount&currency=INR&name=Humdam%20SoulSync&description=${tier.name}%20Subscription';
        
        // Open in new tab
        final uri = Uri.parse(checkoutUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment page opened. Complete payment and return to app.'),
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
        
        _processingTierId = null;
        notifyListeners();
        return true;
      }
      
      // FOR MOBILE: Use Razorpay Flutter SDK
      final res = await ApiService.post('/razorpay/create-order', {
        'tier': tier.id,
      });
      
      debugPrint('[Subscription] Backend response: $res');
      
      final orderId = res['orderId'] as String?;
      final amount = res['amount'] as int?;
      final keyId = res['keyId'] as String?;
      
      if (orderId == null || amount == null || keyId == null) {
        debugPrint('[Subscription] Missing required fields');
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Razorpay not configured. Error: ${res['error'] ?? 'Missing keys'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        
        _processingTierId = null;
        notifyListeners();
        return false;
      }

      // Initialize Razorpay for mobile
      _razorpay ??= Razorpay();
      
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) async {
        debugPrint('[Razorpay] Payment success: ${response.paymentId}');
        await _handlePaymentSuccess(response, tier.id, context);
      });

      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
        debugPrint('[Razorpay] Payment error: ${response.code} - ${response.message}');
        _handlePaymentError(response, context);
      });

      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
        debugPrint('[Razorpay] External wallet: ${response.walletName}');
        _processingTierId = null;
        notifyListeners();
      });

      // Open Razorpay checkout
      final options = {
        'key': keyId,
        'amount': amount,
        'currency': 'INR',
        'name': 'Humdam / SoulSync',
        'description': '${tier.name} Subscription - Monthly',
        'order_id': orderId,
        'prefill': {
          'contact': '',
          'email': '',
        },
        'theme': {
          'color': '#3F51B5',
        },
      };

      debugPrint('[Razorpay] Opening mobile checkout');
      _razorpay!.open(options);
      
      _processingTierId = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[Subscription] Error: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      
      _processingTierId = null;
      notifyListeners();
      return false;
    }
  }
  
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response, String tierId, BuildContext context) async {
    try {
      debugPrint('[Payment] Verifying payment: ${response.paymentId}');
      
      // Verify payment on backend
      final res = await ApiService.post('/razorpay/verify-payment', {
        'razorpay_order_id': response.orderId,
        'razorpay_payment_id': response.paymentId,
        'razorpay_signature': response.signature,
      });

      if (res['verified'] == true) {
        debugPrint('[Payment] Payment verified successfully');
        
        // Update local state
        await refreshFromBackend();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful! Subscription activated.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        debugPrint('[Payment] Payment verification failed');
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment verification failed. Please contact support.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('[Payment] Verification error: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying payment: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _processingTierId = null;
      notifyListeners();
    }
  }

  void _handlePaymentError(PaymentFailureResponse response, BuildContext context) {
    _processingTierId = null;
    notifyListeners();
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message ?? "Unknown error"}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> refreshFromBackend() async {
    try {
      final res = await ApiService.get('/subscription/me');
      final tierId = res['tier']?.toString();
      if (tierId != null) {
        _currentTier = SubscriptionTiers.all.firstWhere(
          (t) => t.id == tierId,
          orElse: () => SubscriptionTiers.tier1,
        );
      } else {
        _currentTier = null;
      }
      notifyListeners();
    } catch (_) {
      // Silently fail - might be offline or not logged in
    }
  }
}


