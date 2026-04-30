import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({super.key});

  Future<void> _handleLogout(BuildContext context, AuthProvider authProvider) async {
    await authProvider.logout();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('แดชบอร์ดผู้ใช้'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context, authProvider),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'สวัสดี ${user?['firstName'] ?? ''} ${user?['lastName'] ?? ''}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text('เมนูหลัก', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMenuCard(
                    context,
                    'ดูสุนัข',
                    Icons.pets,
                    () => Navigator.pushNamed(context, '/dogs'),
                  ),
                  _buildMenuCard(
                    context,
                    'คำขอรับเลี้ยง',
                    Icons.assignment,
                    () => Navigator.pushNamed(context, '/user-requests'),
                  ),
                  _buildMenuCard(
                    context,
                    'สุนัขที่ชอบ',
                    Icons.favorite,
                    () => Navigator.pushNamed(context, '/user-favourites'),
                  ),
                  _buildMenuCard(
                    context,
                    'นัดตรวจสุขภาพ',
                    Icons.medical_services,
                    () => Navigator.pushNamed(context, '/user-checkups'),
                  ),
                  _buildMenuCard(
                    context,
                    'นัดรับสุนัข',
                    Icons.home,
                    () => Navigator.pushNamed(context, '/user-pickup'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.blue),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}