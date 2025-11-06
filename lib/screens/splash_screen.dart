import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/auth_provider.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'landing_screen.dart';
import '../widgets/app_background.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _initialize();
  }

  Future<void> _initialize() async {
    // Refresh subscription status and check auth
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      await context.read<SubscriptionProvider>().refreshFromBackend();
    }
    
    // Wait for splash animation (3 seconds)
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    _navigate();
  }

  void _navigate() {
    final auth = context.read<AuthProvider>();
    final sub = context.read<SubscriptionProvider>();
    
    if (!auth.isLoggedIn) {
      Navigator.of(context).pushReplacementNamed(LandingScreen.routeName);
      return;
    }
    
    final dest = sub.isSubscribed || sub.inTrial
        ? HomeScreen.routeName
        : HomeScreen.routeName; // Still show home, but with subscription prompt
    Navigator.of(context).pushReplacementNamed(dest);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _pulse,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.indigo, Colors.indigoAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 56),
                ),
              ),
              const SizedBox(height: 16),
              Text('Humdam / SoulSync', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}


