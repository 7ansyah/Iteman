import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../models/event_model.dart';

class EventScreen extends StatelessWidget {
  const EventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text(
          '🏆 Event & Lomba Mancing',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BuatEventScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmpty(context);
          }

          final events = snapshot.data!.docs
              .map(
                (d) =>
                    EventModel.fromMap(d.data() as Map<String, dynamic>, d.id),
              )
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: events.length,
            itemBuilder: (context, index) =>
                _buildEventCard(context, events[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BuatEventScreen()),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Buat Event',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          const Text(
            'Belum ada event',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Buat lomba mancing pertama\ndi komunitasmu!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BuatEventScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Buat Event'),
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

  Widget _buildEventCard(BuildContext context, EventModel event) {
    final user = FirebaseAuth.instance.currentUser;
    final sudahDaftar = event.pesertaIds.contains(user?.uid);
    final penuh = event.pesertaIds.length >= event.maxPeserta;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailEventScreen(event: event)),
      ),
      child: Container(
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
            // Foto event
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: event.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: event.imageUrl,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: double.infinity,
                      height: 120,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                        ),
                      ),
                      child: const Center(
                        child: Text('🏆', style: TextStyle(fontSize: 48)),
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      event.kategori,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    event.judul,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.tanggalMulai} • ${event.jamMulai}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.lokasi,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Hadiah & Biaya
                  Row(
                    children: [
                      if (event.hadiah.isNotEmpty)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '🏆 ${event.hadiah}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: event.biayaDaftar == 'Gratis'
                              ? const Color(0xFF1B5E20).withValues(alpha: 0.1)
                              : Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          event.biayaDaftar == 'Gratis'
                              ? '✅ Gratis'
                              : '💰 ${event.biayaDaftar}',
                          style: TextStyle(
                            fontSize: 12,
                            color: event.biayaDaftar == 'Gratis'
                                ? const Color(0xFF1B5E20)
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Peserta & Tombol
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '👥 ${event.pesertaIds.length}/${event.maxPeserta} Peserta',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: event.pesertaIds.length / event.maxPeserta,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                penuh ? Colors.red : const Color(0xFF1B5E20),
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: penuh && !sudahDaftar
                            ? null
                            : () => _toggleDaftar(event),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: sudahDaftar
                              ? Colors.red
                              : penuh
                              ? Colors.grey
                              : const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          sudahDaftar
                              ? 'Batal'
                              : penuh
                              ? 'Penuh'
                              : 'Daftar',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
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

  Future<void> _toggleDaftar(EventModel event) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance.collection('events').doc(event.id);

    if (event.pesertaIds.contains(user.uid)) {
      await ref.update({
        'pesertaIds': FieldValue.arrayRemove([user.uid]),
      });
    } else {
      await ref.update({
        'pesertaIds': FieldValue.arrayUnion([user.uid]),
      });
    }
  }
}

// ============================================================
// DETAIL EVENT
// ============================================================

class DetailEventScreen extends StatelessWidget {
  final EventModel event;

  const DetailEventScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final sudahDaftar = event.pesertaIds.contains(user?.uid);
    final penuh = event.pesertaIds.length >= event.maxPeserta;
    final isOwner = event.userId == user?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF1B5E20),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('events')
                        .doc(event.id)
                        .delete();
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: event.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: event.imageUrl,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                        ),
                      ),
                      child: const Center(
                        child: Text('🏆', style: TextStyle(fontSize: 80)),
                      ),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF1B5E20,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            event.kategori,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1B5E20),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          event.judul,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.calendar_today,
                          '${event.tanggalMulai} — ${event.tanggalSelesai}',
                        ),
                        _buildDetailRow(Icons.access_time, event.jamMulai),
                        _buildDetailRow(Icons.location_on, event.lokasi),
                        if (event.hadiah.isNotEmpty)
                          _buildDetailRow(
                            Icons.emoji_events,
                            event.hadiah,
                            color: Colors.amber,
                          ),
                        _buildDetailRow(
                          Icons.payments,
                          event.biayaDaftar,
                          color: event.biayaDaftar == 'Gratis'
                              ? const Color(0xFF1B5E20)
                              : Colors.orange,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Deskripsi
                  if (event.deskripsi.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📋 Deskripsi Event',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B5E20),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            event.deskripsi,
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Peserta
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '👥 Peserta (${event.pesertaIds.length}/${event.maxPeserta})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: event.pesertaIds.length / event.maxPeserta,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            penuh ? Colors.red : const Color(0xFF1B5E20),
                          ),
                          borderRadius: BorderRadius.circular(4),
                          minHeight: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol daftar
                  if (!isOwner)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: penuh && !sudahDaftar
                            ? null
                            : () async {
                                final ref = FirebaseFirestore.instance
                                    .collection('events')
                                    .doc(event.id);
                                if (sudahDaftar) {
                                  await ref.update({
                                    'pesertaIds': FieldValue.arrayRemove([
                                      user!.uid,
                                    ]),
                                  });
                                } else {
                                  await ref.update({
                                    'pesertaIds': FieldValue.arrayUnion([
                                      user!.uid,
                                    ]),
                                  });
                                }
                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: sudahDaftar
                              ? Colors.red
                              : const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          sudahDaftar
                              ? 'Batalkan Pendaftaran'
                              : penuh
                              ? 'Peserta Penuh'
                              : 'Daftar Sekarang!',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: color ?? Colors.black87,
                fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BUAT EVENT SCREEN
// ============================================================

class BuatEventScreen extends StatefulWidget {
  const BuatEventScreen({super.key});

  @override
  State<BuatEventScreen> createState() => _BuatEventScreenState();
}

class _BuatEventScreenState extends State<BuatEventScreen> {
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _lokasiController = TextEditingController();
  final _hadiahController = TextEditingController();
  final _biayaController = TextEditingController();

  String _tanggalMulai = '';
  String _tanggalSelesai = '';
  String _jamMulai = '';
  String _kategori = 'Lomba Mancing';
  int _maxPeserta = 50;
  File? _imageFile;
  bool _isLoading = false;
  bool _gratis = true;

  final List<String> _kategoriList = [
    'Lomba Mancing',
    'Festival Mancing',
    'Mancing Bersama',
    'Turnamen Galatama',
    'Lomba Anak',
  ];

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _lokasiController.dispose();
    _hadiahController.dispose();
    _biayaController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<String> _uploadImage(File file) async {
    const cloudName = 'duwfcfamz';
    const uploadPreset = 'iteman_spots';
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final response = await request.send();
    final data = json.decode(
      String.fromCharCodes(await response.stream.toBytes()),
    );
    return data['secure_url'].toString();
  }

  Future<void> _pilihTanggal(bool isMulai) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1B5E20)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final str = '${picked.day}/${picked.month}/${picked.year}';
      setState(() {
        if (isMulai) {
          _tanggalMulai = str;
        } else {
          _tanggalSelesai = str;
        }
      });
    }
  }

  Future<void> _pilihJam() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 7, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1B5E20)),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _jamMulai = picked.format(context));
    }
  }

  Future<void> _submit() async {
    if (_judulController.text.trim().isEmpty ||
        _lokasiController.text.trim().isEmpty ||
        _tanggalMulai.isEmpty ||
        _jamMulai.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi semua field wajib!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      String imageUrl = '';
      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!);
      }

      await FirebaseFirestore.instance.collection('events').add({
        'userId': user.uid,
        'userName': user.displayName ?? 'Pemancing',
        'userPhotoUrl': user.photoURL ?? '',
        'judul': _judulController.text.trim(),
        'deskripsi': _deskripsiController.text.trim(),
        'lokasi': _lokasiController.text.trim(),
        'tanggalMulai': _tanggalMulai,
        'tanggalSelesai': _tanggalSelesai.isEmpty
            ? _tanggalMulai
            : _tanggalSelesai,
        'jamMulai': _jamMulai,
        'hadiah': _hadiahController.text.trim(),
        'biayaDaftar': _gratis ? 'Gratis' : _biayaController.text.trim(),
        'maxPeserta': _maxPeserta,
        'pesertaIds': [user.uid],
        'kategori': _kategori,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event berhasil dibuat! 🏆'),
            backgroundColor: Color(0xFF1B5E20),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text(
          'Buat Event Mancing',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: const Text(
              'Buat',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Foto
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1B5E20)),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _imageFile!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 40,
                          color: Color(0xFF1B5E20),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tambah Poster Event',
                          style: TextStyle(color: Color(0xFF1B5E20)),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Info event
          _buildSection('📋 Info Event', [
            _buildTextField(
              _judulController,
              'Judul Event',
              'Contoh: Lomba Mancing Gabus Berhadiah',
              true,
            ),
            const SizedBox(height: 12),
            _buildDropdownField(
              'Kategori',
              _kategori,
              _kategoriList,
              (v) => setState(() => _kategori = v!),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              _deskripsiController,
              'Deskripsi',
              'Ceritakan detail event ini...',
              false,
              maxLines: 3,
            ),
          ]),
          const SizedBox(height: 16),

          // Waktu & Lokasi
          _buildSection('📅 Waktu & Lokasi', [
            Row(
              children: [
                Expanded(
                  child: _buildDateButton(
                    'Mulai',
                    _tanggalMulai,
                    () => _pilihTanggal(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateButton(
                    'Selesai',
                    _tanggalSelesai,
                    () => _pilihTanggal(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDateButton(
              'Jam Mulai',
              _jamMulai,
              _pilihJam,
              icon: Icons.access_time,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              _lokasiController,
              'Lokasi Event',
              'Nama tempat / alamat lengkap',
              true,
            ),
          ]),
          const SizedBox(height: 16),

          // Hadiah & Biaya
          _buildSection('🏆 Hadiah & Biaya', [
            _buildTextField(
              _hadiahController,
              'Hadiah',
              'Contoh: Uang tunai Rp 5.000.000',
              false,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pendaftaran Gratis'),
              value: _gratis,
              onChanged: (v) => setState(() => _gratis = v),
              activeThumbColor: const Color(0xFF1B5E20),
            ),
            if (!_gratis)
              _buildTextField(
                _biayaController,
                'Biaya Daftar',
                'Contoh: Rp 50.000 per orang',
                false,
              ),
          ]),
          const SizedBox(height: 16),

          // Max peserta
          _buildSection('👥 Peserta', [
            Row(
              children: [
                const Text(
                  'Maksimal Peserta:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    if (_maxPeserta > 10) {
                      setState(() => _maxPeserta -= 10);
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
                  onPressed: () => setState(() => _maxPeserta += 10),
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 24),

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
                      'Buat Event 🏆',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
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
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    bool required, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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

  Widget _buildDropdownField(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDateButton(
    String label,
    String value,
    VoidCallback onTap, {
    IconData icon = Icons.calendar_today,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1B5E20), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value.isEmpty ? label : value,
                style: TextStyle(
                  color: value.isEmpty ? Colors.grey : Colors.black,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
