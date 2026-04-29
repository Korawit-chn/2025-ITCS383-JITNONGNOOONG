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
import 'package:google_fonts/google_fonts.dart';

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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JITNONGNOONG',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.sarabunTextTheme(),
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
    final normalizedRole = role?.toLowerCase() ?? '';
    switch (normalizedRole) {
      case 'admin':
        return const AdminDashboardScreen();
      case 'staff':
        return const StaffDashboardScreen();
      case 'sponsor':
        return const SponsorDashboardScreen();
      case 'user':
      default:
        return const UserDashboardScreen();
    }
  }
}