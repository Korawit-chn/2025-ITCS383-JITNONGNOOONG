import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();
  final _registerFirstNameController = TextEditingController();
  final _registerLastNameController = TextEditingController();
  final _registerPhoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    _registerFirstNameController.dispose();
    _registerLastNameController.dispose();
    _registerPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JITNONGNOONG'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              '🐾 JITNONGNOONG',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text('ระบบรับเลี้ยงสุนัข'),
            const SizedBox(height: 24),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'เข้าสู่ระบบ'),
                Tab(text: 'สมัครสมาชิก'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLoginTab(),
                  _buildRegisterTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginTab() {
    return Form(
      key: _loginFormKey,
      child: ListView(
        padding: const EdgeInsets.only(top: 24),
        children: [
          TextFormField(
            controller: _loginEmailController,
            decoration: const InputDecoration(
              labelText: 'อีเมล',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'กรุณากรอกอีเมล';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _loginPasswordController,
            decoration: const InputDecoration(
              labelText: 'รหัสผ่าน',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'กรุณากรอกรหัสผ่าน';
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _login,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('เข้าสู่ระบบ'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
            child: const Text('กลับสู่หน้าหลัก'),
          ),
          const SizedBox(height: 16),
          const Text(
            'บัญชีทดสอบ: admin@gmail.com, malee.staff@gmail.com, thanakrit@gmail.com, sponsor1@gmail.com / Password123!',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterTab() {
    return Form(
      key: _registerFormKey,
      child: ListView(
        padding: const EdgeInsets.only(top: 24),
        children: [
          TextFormField(
            controller: _registerFirstNameController,
            decoration: const InputDecoration(
              labelText: 'ชื่อ',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'กรุณากรอกชื่อ';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _registerLastNameController,
            decoration: const InputDecoration(
              labelText: 'นามสกุล',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'กรุณากรอกนามสกุล';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _registerEmailController,
            decoration: const InputDecoration(
              labelText: 'อีเมล',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'กรุณากรอกอีเมล';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _registerPhoneController,
            decoration: const InputDecoration(
              labelText: 'เบอร์โทร',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) return 'กรุณากรอกเบอร์โทร';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _registerPasswordController,
            decoration: const InputDecoration(
              labelText: 'รหัสผ่าน',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'กรุณากรอกรหัสผ่าน';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _registerConfirmPasswordController,
            decoration: const InputDecoration(
              labelText: 'ยืนยันรหัสผ่าน',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
            validator: (value) {
              if (value != _registerPasswordController.text) {
                return 'รหัสผ่านไม่ตรงกัน';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _register,
            child: _isLoading
                ? const CircularProgressIndicator()
                : const Text('สมัครสมาชิก'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false),
            child: const Text('กลับสู่หน้าหลัก'),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.login(
        _loginEmailController.text,
        _loginPasswordController.text,
      );
      
      // Navigate to appropriate dashboard based on role
      String route = '/';
      final role = authProvider.user?['role']?.toString().toLowerCase();
      switch (role) {
        case 'admin':
          route = '/admin-dashboard';
          break;
        case 'staff':
          route = '/staff-dashboard';
          break;
        case 'sponsor':
          route = '/sponsor-dashboard';
          break;
        case 'user':
        default:
          route = '/user-dashboard';
          break;
      }
      Navigator.of(context).pushReplacementNamed(route);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เข้าสู่ระบบล้มเหลว: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    if (!_registerFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.register({
        'firstName': _registerFirstNameController.text,
        'lastName': _registerLastNameController.text,
        'email': _registerEmailController.text,
        'phone': _registerPhoneController.text,
        'password': _registerPasswordController.text,
      });
      Navigator.of(context).pushReplacementNamed('/');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('สมัครสมาชิกล้มเหลว: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}