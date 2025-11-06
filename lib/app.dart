import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'providers/chat_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/expense_screen.dart';
import 'screens/funlearn_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/subscription_debug_screen.dart';

class HumdamSoulSyncApp extends StatelessWidget {
  const HumdamSoulSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    return MaterialApp(
      title: 'Humdam / SoulSync',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: chat.isNightMode ? ThemeMode.dark : ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(), // Use wrapper for auth state management
      routes: {
        // Don't include '/' route since we're using home property
        LandingScreen.routeName: (_) => const LandingScreen(),
        AuthScreen.routeName: (_) => const AuthScreen(),
        HomeScreen.routeName: (_) => const HomeScreen(),
        ScheduleScreen.routeName: (_) => const ScheduleScreen(),
        ExpenseScreen.routeName: (_) => const ExpenseScreen(),
        FunLearnScreen.routeName: (_) => const FunLearnScreen(),
        ProfileScreen.routeName: (_) => const ProfileScreen(),
        SubscriptionScreen.routeName: (_) => const SubscriptionScreen(),
        SignupScreen.routeName: (_) => const SignupScreen(),
        SubscriptionDebugScreen.routeName: (_) => const SubscriptionDebugScreen(),
      },
    );
  }
}

// Wrapper to handle auth state changes
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    // Show splash first, then appropriate screen based on auth state
    return FutureBuilder(
      future: Future.delayed(const Duration(seconds: 2)), // Splash delay
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        
        // After splash, check auth state
        if (!auth.isLoggedIn) {
          return const LandingScreen();
        }
        
        return const HomeScreen();
      },
    );
  }
}


