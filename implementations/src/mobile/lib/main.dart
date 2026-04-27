import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dogs_screen.dart';
import 'screens/user_dashboard_screen.dart';
import 'screens/staff_dashboard_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/sponsor_dashboard_screen.dart';
import 'providers/auth_provider.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    await Provider.of<AuthProvider>(context, listen: false).tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JITNONGNOONG',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Sarabun',
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            return _getDashboardForRole(auth.user?['role']);
          }
          return const HomeScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dogs': (context) => const DogsScreen(),
        '/user-dashboard': (context) => const UserDashboardScreen(),
        '/staff-dashboard': (context) => const StaffDashboardScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/sponsor-dashboard': (context) => const SponsorDashboardScreen(),
      },
    );
  }

  Widget _getDashboardForRole(String? role) {
    switch (role?.toUpperCase()) {
      case 'ADMIN':
        return const AdminDashboardScreen();
      case 'STAFF':
        return const StaffDashboardScreen();
      case 'SPONSOR':
        return const SponsorDashboardScreen();
      case 'USER':
      default:
        return const UserDashboardScreen();
    }
  }
}