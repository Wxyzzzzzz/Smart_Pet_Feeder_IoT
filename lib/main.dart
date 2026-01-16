import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_screen.dart';
import 'analytics_screen.dart';
import 'history_screen.dart';
import 'schedule_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'config/firebase_config.dart';
import 'config/app_colors.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: FirebaseConfig.apiKey,
      authDomain: FirebaseConfig.authDomain,
      projectId: FirebaseConfig.projectId,
      storageBucket: FirebaseConfig.storageBucket,
      messagingSenderId: FirebaseConfig.messagingSenderId,
      appId: FirebaseConfig.appId,
    ),
  );

  // Initialize Notification Service
  await NotificationService().initialize();

  runApp(SmartFeederApp());
}

class SmartFeederApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Pet Feeder',
      navigatorKey: NavigationService.navigatorKey, // For global navigation
      theme: ThemeData(
        primarySwatch: AppColors.primarySwatch,
        primaryColor: AppColors.primaryDark,
        scaffoldBackgroundColor: AppColors.backgroundLight,
        cardColor: AppColors.cardBackground,
        colorScheme: ColorScheme.light(
          primary: AppColors.primaryDark,
          secondary: AppColors.accentSage,
          surface: AppColors.cardBackground,
          background: AppColors.backgroundLight,
        ),
        useMaterial3: true,
      ),
      home: AuthWrapper(), // Use auth wrapper instead of direct login screen
    );
  }
}

// Authentication wrapper to handle auth state
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryDark),
            ),
          );
        }

        // If user is logged in, show main navigation
        if (snapshot.hasData) {
          return MainNavigation();
        }

        // Otherwise show login screen
        return LoginScreen();
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    ScheduleScreen(),
    AnalyticsScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Status'),
          NavigationDestination(icon: Icon(Icons.schedule), label: 'Schedule'),
          NavigationDestination(
              icon: Icon(Icons.show_chart), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Logs'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
