import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('JITNONGNOONG'),
        actions: [
          if (authProvider.isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => authProvider.logout(),
            )
          else
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('เข้าสู่ระบบ'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.blue.shade50,
              child: Column(
                children: [
                  const Text(
                    'ให้น้องสุนัขมีบ้านที่รัก',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ระบบรับเลี้ยงสุนัขขององค์กรไม่แสวงหาผลกำไร ครบครัน โปร่งใส ดูแลต่อเนื่อง',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/dogs'),
                        child: const Text('🐶 ดูสุนัขรอหาบ้าน'),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('วิธีการรับเลี้ยง'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Sponsor Banner
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ผู้สนับสนุน'),
                  Container(
                    height: 100,
                    color: Colors.grey.shade100,
                    child: const Center(child: Text('กำลังโหลด...')),
                  ),
                ],
              ),
            ),

            // Dogs Section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'น้องรอหาบ้าน',
                    style: TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'สุนัขพร้อมรับเลี้ยง',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ทุกตัวผ่านการตรวจสุขภาพ ฉีดวัคซีน และฝึกนิสัยพื้นฐานแล้ว',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  // Dogs Grid - placeholder
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      return Card(
                        child: Column(
                          children: [
                            Container(
                              height: 120,
                              color: Colors.grey.shade200,
                              child: const Center(child: Text('รูปสุนัข')),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text('ชื่อสุนัข'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/dogs'),
                    child: const Text('ดูสุนัขทั้งหมด →'),
                  ),
                ],
              ),
            ),

            // How it works
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.grey.shade50,
              child: Column(
                children: [
                  const Text(
                    'ขั้นตอน',
                    style: TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'วิธีการรับเลี้ยงสุนัข',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ง่าย 4 ขั้นตอน เพื่อให้น้องได้บ้านที่ดีที่สุด',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStep('🔍', 'ขั้นที่ 1', 'ค้นหาสุนัข', 'เลือกดูสุนัขที่คุณชอบ'),
                      ),
                      Expanded(
                        child: _buildStep('📝', 'ขั้นที่ 2', 'ยื่นคำขอ', 'กรอกแบบฟอร์มรับเลี้ยง'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStep('✅', 'ขั้นที่ 3', 'ตรวจสอบคุณสมบัติ', 'ตรวจประวัติ'),
                      ),
                      Expanded(
                        child: _buildStep('🏠', 'ขั้นที่ 4', 'รับน้องกลับบ้าน', 'นัดรับน้อง'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String icon, String step, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(step, style: const TextStyle(color: Colors.blue)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}