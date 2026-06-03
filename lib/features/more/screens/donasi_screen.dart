import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DonasiScreen extends StatelessWidget {
  const DonasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text(
          'Donasi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header donasi
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.red, Colors.pink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                Text('❤️', style: TextStyle(fontSize: 60)),
                SizedBox(height: 12),
                Text(
                  'Dukung Iteman',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Iteman adalah aplikasi gratis yang dibuat\n'
                  'dengan penuh semangat untuk komunitas\n'
                  'pemancing Indonesia.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.6,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Kenapa donasi
          _buildSection(
            '💭 Kenapa Donasi?',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPoint(
                  '🖥️',
                  'Biaya server & database untuk menyimpan data spot dari seluruh Indonesia',
                ),
                _buildPoint(
                  '🗺️',
                  'Biaya Google Maps API untuk peta interaktif yang akurat',
                ),
                _buildPoint(
                  '👨‍💻',
                  'Waktu & tenaga pengembangan fitur-fitur baru',
                ),
                _buildPoint('🔒', 'Keamanan data dan privasi seluruh pengguna'),
                _buildPoint(
                  '📱',
                  'Pembaruan rutin agar aplikasi tetap berjalan lancar',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Cara donasi
          _buildSection(
            '💳 Cara Donasi',
            Column(
              children: [
                _buildDonasiOption(
                  'Transfer Bank',
                  'BRI • 578801015633532\na/n Juansah',
                  Icons.account_balance,
                  Colors.blue,
                  () => _copyToClipboard(context, '578801015633532'),
                ),
                const SizedBox(height: 12),
                _buildDonasiOption(
                  'Transfer Bank',
                  'SEABANK • 901259382692\na/n Juansah',
                  Icons.account_balance,
                  Colors.blue,
                  () => _copyToClipboard(context, '901259382692'),
                ),
                const SizedBox(height: 12),
                _buildDonasiOption(
                  'Dana',
                  '082322210005\na/n Juansah',
                  Icons.phone_android,
                  Colors.green,
                  () => _copyToClipboard(context, '082322210005'),
                ),
                const SizedBox(height: 12),
                _buildDonasiOption(
                  'QRIS',
                  'Scan kode QRIS di bawah',
                  Icons.qr_code,
                  Colors.purple,
                  null,
                ),
                // Placeholder QRIS
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          'https://res.cloudinary.com/duwfcfamz/image/upload/v1779080126/oqmllvbsiocek9wrlhnl.jpg', // ganti ini
                          width: double.infinity,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const SizedBox(
                              height: 200,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.purple,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stack) =>
                              const SizedBox(
                                height: 200,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.qr_code_2,
                                        size: 80,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'QRIS belum tersedia',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            const Text(
                              'Scan QRIS di atas dengan\nGoPay, OVO, Dana, ShopeePay, atau m-Banking',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _copyToClipboard(
                                context,
                                'iteman.app@gmail.com',
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.save_alt,
                                      color: Colors.purple,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Screenshot untuk disimpan',
                                      style: TextStyle(
                                        color: Colors.purple,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Nominal saran
          _buildSection(
            '💰 Nominal Donasi',
            Column(
              children: [
                const Text(
                  'Donasi berapapun sangat berarti untuk kami. '
                  'Tidak ada nominal minimum — seikhlasnya.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      [
                            'Rp 5.000',
                            'Rp 10.000',
                            'Rp 25.000',
                            'Rp 50.000',
                            'Rp 100.000',
                            'Bebas',
                          ]
                          .map(
                            (nominal) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF1B5E20,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(
                                    0xFF1B5E20,
                                  ).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                nominal,
                                style: const TextStyle(
                                  color: Color(0xFF1B5E20),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Ucapan terima kasih
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF1B5E20).withValues(alpha: 0.2),
              ),
            ),
            child: const Column(
              children: [
                Text('🙏', style: TextStyle(fontSize: 36)),
                SizedBox(height: 8),
                Text(
                  'Terima Kasih!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Setiap donasi akan langsung digunakan\n'
                  'untuk pengembangan dan operasional Iteman.\n'
                  'Nama donatur akan kami kenang di\n'
                  'Hall of Fame Iteman. 🎣',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    height: 1.5,
                  ),
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

  Widget _buildPoint(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonasiOption(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (onTap != null) Icon(Icons.copy, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Disalin ke clipboard ✅'),
        backgroundColor: Color(0xFF1B5E20),
      ),
    );
  }
}
