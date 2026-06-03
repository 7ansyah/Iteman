import 'package:flutter/material.dart';

class TentangScreen extends StatelessWidget {
  const TentangScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text(
          'Tentang Iteman',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Image.asset(
                  'assets/images/logo_header.png',
                  width: 180,
                  height: 54,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Versi 1.0.0',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Info Tempat Mancing',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tentang
          _buildSection(
            '🎣 Tentang Iteman',
            const Text(
              'Iteman (Info Tempat Mancing) adalah aplikasi komunitas '
              'pemancing Indonesia yang memungkinkan pengguna untuk '
              'menemukan, membagikan, dan mengelola spot mancing '
              'terbaik di seluruh nusantara.\n\n'
              'Iteman lahir dari kebutuhan nyata para pemancing yang '
              'kesulitan menemukan informasi spot mancing yang akurat, '
              'terkini, dan terpercaya. Dengan kekuatan komunitas, '
              'setiap spot yang dibagikan menjadi lebih kaya informasi '
              'dan lebih dapat diandalkan.',
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Fitur unggulan
          _buildSection(
            '⭐ Fitur Unggulan',
            Column(
              children: [
                _buildFeature(
                  '🗺️',
                  'Peta Spot Mancing',
                  'Temukan spot mancing terdekat dengan peta satelit interaktif dan heatmap kepanasan spot',
                ),
                _buildFeature(
                  '📍',
                  'Tambah & Bagikan Spot',
                  'Bagikan spot favoritmu dengan foto, koordinat GPS, dan informasi lengkap',
                ),
                _buildFeature(
                  '👥',
                  'Komunitas Aktif',
                  'Follow pemancing lain, komentar, like, dan ajak mancing bareng',
                ),
                _buildFeature(
                  '🔴',
                  'Live Report',
                  'Pantau kondisi spot real-time dari pemancing yang sedang di lapangan',
                ),
                _buildFeature(
                  '🌤️',
                  'Cuaca & Pasang Surut',
                  'Info cuaca real-time dan prediksi pasang surut untuk spot laut',
                ),
                _buildFeature(
                  '🌕',
                  'Fase Bulan',
                  'Panduan fase bulan untuk menentukan waktu mancing terbaik',
                ),
                _buildFeature(
                  '📒',
                  'Log Book Digital',
                  'Catat setiap sesi mancing dengan detail umpan, teknik, dan hasil tangkapan',
                ),
                _buildFeature(
                  '🏆',
                  'Event & Lomba',
                  'Ikuti dan buat lomba mancing lokal bersama komunitas',
                ),
                _buildFeature(
                  '🛒',
                  'Lapak Iteman',
                  'Jual beli alat pancing dan promosi kolam langsung di komunitas',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Kebijakan privasi
          _buildSection(
            '🔒 Kebijakan Privasi',
            const Text(
              'Iteman berkomitmen menjaga privasi seluruh pengguna:\n\n'
              '• Data pribadi (nama, email, foto) hanya digunakan untuk '
              'keperluan identitas di dalam aplikasi\n\n'
              '• Data lokasi GPS hanya digunakan saat pengguna secara '
              'aktif menambahkan spot atau melihat peta\n\n'
              '• Kami tidak menjual data pengguna kepada pihak ketiga\n\n'
              '• Konten yang dibagikan pengguna sepenuhnya menjadi '
              'tanggung jawab pengguna yang bersangkutan\n\n'
              '• Pengguna berhak menghapus akun dan seluruh data '
              'mereka kapan saja',
              style: TextStyle(
                fontSize: 13,
                height: 1.7,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Ketentuan layanan
          _buildSection(
            '📋 Ketentuan Layanan',
            const Text(
              'Dengan menggunakan Iteman, pengguna menyetujui:\n\n'
              '• Tidak membagikan informasi spot yang menyesatkan '
              'atau palsu\n\n'
              '• Tidak menggunakan aplikasi untuk kegiatan yang '
              'melanggar hukum termasuk penangkapan ikan ilegal\n\n'
              '• Menghormati sesama anggota komunitas dan tidak '
              'melakukan tindakan intimidasi atau pelecehan\n\n'
              '• Konten yang mengandung SARA, pornografi, atau '
              'kekerasan akan dihapus dan akun diblokir\n\n'
              '• Iteman berhak menangguhkan akun yang melanggar '
              'ketentuan ini tanpa pemberitahuan sebelumnya',
              style: TextStyle(
                fontSize: 13,
                height: 1.7,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Kontak
          _buildSection(
            '📬 Hubungi Kami',
            Column(
              children: [
                _buildKontak(Icons.email, 'Email', 'iteman.app@gmail.com'),
                const SizedBox(height: 8),
                _buildKontak(
                  Icons.language,
                  'Website',
                  'www.iteman.app (segera hadir)',
                ),
                const SizedBox(height: 8),
                _buildKontak(Icons.photo_camera, 'Instagram', '@iteman.app'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Credits
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Text(
                  'Dibuat dengan ❤️ untuk\nkomunitas pemancing Indonesia',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '© 2025 Iteman App. All rights reserved.',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildFeature(String emoji, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKontak(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1B5E20), size: 20),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}
