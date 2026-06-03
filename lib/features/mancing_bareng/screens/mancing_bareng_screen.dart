import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/mancing_bareng_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/widgets/map_picker_screen.dart';

class MancingBarengScreen extends StatefulWidget {
  const MancingBarengScreen({super.key});

  @override
  State<MancingBarengScreen> createState() => _MancingBarengScreenState();
}

class _MancingBarengScreenState extends State<MancingBarengScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text(
          'Mancing Bareng 🎣',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () => _showBuatAjakDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('mancing_bareng')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmpty();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final model = MancingBarengModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
              return _buildCard(context, model);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBuatAjakDialog(context),
        backgroundColor: const Color(0xFF1B5E20),
        icon: const Icon(Icons.people_alt, color: Colors.white),
        label: const Text(
          'Ajak Mancing',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎣', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          const Text(
            'Belum ada ajakan mancing',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Jadilah yang pertama\nmengajak mancing bareng!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showBuatAjakDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Buat Ajakan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, MancingBarengModel model) {
    final user = FirebaseAuth.instance.currentUser;
    final sudahGabung = model.pesertaIds.contains(user?.uid);
    final penuh = model.pesertaIds.length >= model.maxPeserta;
    final isOwner = model.userId == user?.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF1B5E20),
                  backgroundImage: model.userPhotoUrl.isNotEmpty
                      ? NetworkImage(model.userPhotoUrl)
                      : null,
                  child: model.userPhotoUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 22)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        timeago.format(model.createdAt.toDate(), locale: 'id'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () => _hapusAjakan(model.id),
                  ),
              ],
            ),
          ),

          // Info utama
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E20).withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF1B5E20).withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📍 ${model.spotName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(Icons.calendar_today, model.tanggal),
                    const SizedBox(width: 8),
                    _buildInfoChip(Icons.access_time, model.jam),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInfoChip(Icons.location_on, model.lokasi),
                if (model.deskripsi.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    model.deskripsi,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ],
            ),
          ),

          // Peserta & Tombol
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Indikator peserta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '👥 ${model.pesertaIds.length}/${model.maxPeserta} Peserta',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: model.pesertaIds.length / model.maxPeserta,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          penuh ? Colors.red : const Color(0xFF1B5E20),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Tombol gabung
                if (!isOwner)
                  ElevatedButton(
                    onPressed: penuh && !sudahGabung
                        ? null
                        : () => _toggleGabung(model),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: sudahGabung
                          ? Colors.red
                          : penuh
                          ? Colors.grey
                          : const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      sudahGabung
                          ? 'Keluar'
                          : penuh
                          ? 'Penuh'
                          : 'Gabung!',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                if (isOwner)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Ajakanmu',
                      style: TextStyle(
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF1B5E20)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
  }

  Future<void> _toggleGabung(MancingBarengModel model) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance
        .collection('mancing_bareng')
        .doc(model.id);

    if (model.pesertaIds.contains(user.uid)) {
      await ref.update({
        'pesertaIds': FieldValue.arrayRemove([user.uid]),
      });
    } else {
      await ref.update({
        'pesertaIds': FieldValue.arrayUnion([user.uid]),
      });
    }
  }

  Future<void> _hapusAjakan(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Ajakan'),
        content: const Text('Yakin ingin menghapus ajakan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('mancing_bareng')
          .doc(id)
          .delete();
    }
  }

  void _showBuatAjakDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _BuatAjakanSheet(),
    );
  }
}

class _BuatAjakanSheet extends StatefulWidget {
  const _BuatAjakanSheet();

  @override
  State<_BuatAjakanSheet> createState() => _BuatAjakanSheetState();
}

class _BuatAjakanSheetState extends State<_BuatAjakanSheet> {
  final _spotController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _lokasiController = TextEditingController();
  int _maxPeserta = 5;
  String _tanggal = '';
  String _jam = '';
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _spotController.dispose();
    _deskripsiController.dispose();
    _lokasiController.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1B5E20)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _tanggal = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _pilihJam() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 5, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1B5E20)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _jam = picked.format(context);
      });
    }
  }

  Future<void> _getLocation() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerScreen()),
    );
    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
    }
  }

  Future<void> _submit() async {
    if (_spotController.text.trim().isEmpty ||
        _tanggal.isEmpty ||
        _jam.isEmpty ||
        _lokasiController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua field wajib!')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser!;

    await FirebaseFirestore.instance.collection('mancing_bareng').add({
      'userId': user.uid,
      'userName': user.displayName ?? 'Pemancing',
      'userPhotoUrl': user.photoURL ?? '',
      'spotName': _spotController.text.trim(),
      'deskripsi': _deskripsiController.text.trim(),
      'tanggal': _tanggal,
      'jam': _jam,
      'lokasi': _lokasiController.text.trim(),
      'maxPeserta': _maxPeserta,
      'pesertaIds': [user.uid],
      'createdAt': Timestamp.now(),
      'latitude': _latitude,
      'longitude': _longitude,
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajakan mancing bareng dibuat! 🎣'),
          backgroundColor: Color(0xFF1B5E20),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Buat Ajakan Mancing Bareng 🎣',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 20),

            // Nama spot
            _buildTextField(
              _spotController,
              'Nama Spot / Lokasi Mancing',
              'Contoh: Waduk Kedung Ombo',
              Icons.location_on,
            ),
            const SizedBox(height: 12),

            // Tanggal & Jam
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pilihTanggal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Color(0xFF1B5E20),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _tanggal.isEmpty ? 'Tanggal' : _tanggal,
                            style: TextStyle(
                              color: _tanggal.isEmpty
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _pilihJam,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 18,
                            color: Color(0xFF1B5E20),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _jam.isEmpty ? 'Jam' : _jam,
                            style: TextStyle(
                              color: _jam.isEmpty ? Colors.grey : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Lokasi detail
            _buildTextField(
              _lokasiController,
              'Titik Kumpul',
              'Contoh: Parkiran Indomaret Jl. Merdeka',
              Icons.pin_drop,
            ),
            const SizedBox(height: 12),

            // Deskripsi
            TextField(
              controller: _deskripsiController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Deskripsi tambahan (opsional)...',
                filled: true,
                fillColor: const Color(0xFFF5F5F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tambahkan ini — Tombol GPS
            GestureDetector(
              onTap: _getLocation,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _latitude != null
                        ? const Color(0xFF1B5E20)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.map,
                      color: _latitude != null
                          ? const Color(0xFF1B5E20)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _latitude != null
                            ? 'Titik kumpul dipilih ✅\n'
                                  '${_latitude!.toStringAsFixed(4)}, '
                                  '${_longitude!.toStringAsFixed(4)}'
                            : 'Pilih titik kumpul di peta (opsional)',
                        style: TextStyle(
                          color: _latitude != null
                              ? const Color(0xFF1B5E20)
                              : Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Max peserta
            Row(
              children: [
                const Text(
                  'Maks. Peserta:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    if (_maxPeserta > 2) {
                      setState(() => _maxPeserta--);
                    }
                  },
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                Text(
                  '$_maxPeserta orang',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (_maxPeserta < 20) {
                      setState(() => _maxPeserta++);
                    }
                  },
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tombol submit
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Buat Ajakan Mancing Bareng!',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF1B5E20)),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1B5E20)),
        ),
      ),
    );
  }
}
