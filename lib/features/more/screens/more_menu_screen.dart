import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../admin/screens/admin_verification_screen.dart';
import '../../lapak/screens/lapak_screen.dart';
import '../../communities/screens/communities_screen.dart';
import 'donasi_screen.dart';
import 'tentang_screen.dart';

class MoreMenuScreen extends StatelessWidget {
  const MoreMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text(
          'Menu Lainnya',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/logo_header.png',
                  width: 160,
                  height: 48,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Komunitas Pemancing Indonesia',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Menu items
          _buildMenuCard(
            context,
            icon: '👥',
            title: 'Komunitas Iteman',
            subtitle: 'Rumah komunitas pemancing, basecamp, spot & anggota',
            color: const Color(0xFF1B5E20),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CommunitiesScreen()),
            ),
          ),
          const SizedBox(height: 12),

          _buildAdminMenu(context),

          _buildMenuCard(
            context,
            icon: '🛒',
            title: 'Lapak Iteman',
            subtitle: 'Jual beli alat pancing, umpan, joran & promosi kolam',
            color: Colors.orange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LapakScreen()),
            ),
          ),
          const SizedBox(height: 12),

          _buildMenuCard(
            context,
            icon: '❤️',
            title: 'Donasi',
            subtitle: 'Dukung pengembangan Iteman secara sukarela',
            color: Colors.red,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DonasiScreen()),
            ),
          ),
          const SizedBox(height: 12),

          _buildMenuCard(
            context,
            icon: 'ℹ️',
            title: 'Tentang Aplikasi',
            subtitle: 'Versi, tim, kebijakan & ketentuan layanan',
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TentangScreen()),
            ),
          ),
          const SizedBox(height: 12),

          _buildMenuCard(
            context,
            icon: '📒',
            title: 'Log Book Mancing',
            subtitle: 'Catatan sesi & hasil tangkapanmu',
            color: const Color(0xFF1B5E20),
            onTap: () => Navigator.pushNamed(context, '/logbook'),
          ),
          const SizedBox(height: 12),

          _buildMenuCard(
            context,
            icon: '🔴',
            title: 'Live Report',
            subtitle: 'Kondisi spot real-time dari komunitas',
            color: Colors.red,
            onTap: () => Navigator.pushNamed(context, '/live_report'),
          ),
          const SizedBox(height: 12),

          _buildMenuCard(
            context,
            icon: '🏅',
            title: 'Event & Lomba',
            subtitle: 'Temukan & ikuti lomba mancing terdekat',
            color: Colors.purple,
            onTap: () => Navigator.pushNamed(context, '/event'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAdminMenu(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final isAdmin = data['isAdmin'] == true || data['role'] == 'admin';
        if (!isAdmin) return const SizedBox.shrink();

        return Column(
          children: [
            _buildMenuCard(
              context,
              icon: '✅',
              title: 'Admin Verifikasi',
              subtitle: 'Review pengajuan komunitas terverifikasi',
              color: const Color(0xFF1565C0),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminVerificationScreen(),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
