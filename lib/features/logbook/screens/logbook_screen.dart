import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'dart:io';
import '../models/logbook_model.dart';

class LogbookScreen extends StatelessWidget {
  const LogbookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text(
          '📒 Log Book Mancing',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TambahLogbookScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('logbook')
            .where('userId', isEqualTo: user.uid)
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

          final logs = snapshot.data!.docs
              .map(
                (d) => LogbookModel.fromMap(
                  d.data() as Map<String, dynamic>,
                  d.id,
                ),
              )
              .toList();

          // Statistik ringkas
          final totalSesi = logs.length;
          final totalIkan = logs.fold(
            0,
            (total, l) => total + l.totalTangkapan,
          );

          return Column(
            children: [
              // Statistik header
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildStat('$totalSesi', 'Total\nSesi'),
                    _buildStatDivider(),
                    _buildStat('$totalIkan', 'Total\nIkan'),
                    _buildStatDivider(),
                    _buildStat(
                      totalSesi > 0
                          ? (totalIkan / totalSesi).toStringAsFixed(1)
                          : '0',
                      'Rata-rata\nper Sesi',
                    ),
                  ],
                ),
              ),

              // List log
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) =>
                      _buildLogCard(context, logs[index]),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TambahLogbookScreen()),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Catat Sesi',
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
          const Text('📒', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          const Text(
            'Log Book Kosong',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Catat setiap sesi mancingmu!\nDari umpan, teknik, hingga hasil tangkapan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TambahLogbookScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Catat Sesi Pertama'),
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

  Widget _buildLogCard(BuildContext context, LogbookModel log) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailLogbookScreen(log: log)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            // Foto
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: log.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: log.imageUrl,
                      width: 100,
                      height: 110,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 100,
                      height: 110,
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.phishing,
                        color: Color(0xFF1B5E20),
                        size: 36,
                      ),
                    ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.spotName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log.tanggal,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildChip('☁️ ${log.cuaca}'),
                        _buildChip('🎣 ${log.teknik}'),
                      ],
                    ),
                    const SizedBox(height: 8),
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
                        '🐟 ${log.totalTangkapan} ekor tertangkap',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1B5E20),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.chevron_right, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Colors.black87),
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 40,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }
}

// ============================================================
// TAMBAH LOGBOOK SCREEN
// ============================================================

class TambahLogbookScreen extends StatefulWidget {
  const TambahLogbookScreen({super.key});

  @override
  State<TambahLogbookScreen> createState() => _TambahLogbookScreenState();
}

class _TambahLogbookScreenState extends State<TambahLogbookScreen> {
  final _spotController = TextEditingController();
  final _teknikController = TextEditingController();
  final _umpanController = TextEditingController();
  final _catatanController = TextEditingController();

  String _tanggal = '';
  String _cuaca = 'Cerah';
  String _kondisiAir = 'Jernih';
  File? _imageFile;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _tangkapan = [];
  final _ikanController = TextEditingController();
  final _beratController = TextEditingController();
  final _jumlahController = TextEditingController();

  final List<String> _cuacaList = [
    'Cerah',
    'Berawan',
    'Mendung',
    'Gerimis',
    'Hujan',
  ];
  final List<String> _kondisiAirList = [
    'Jernih',
    'Agak Keruh',
    'Keruh',
    'Banjir',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _tanggal = '${now.day}/${now.month}/${now.year}';
  }

  @override
  void dispose() {
    _spotController.dispose();
    _teknikController.dispose();
    _umpanController.dispose();
    _catatanController.dispose();
    _ikanController.dispose();
    _beratController.dispose();
    _jumlahController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await _chooseImageSource();
    if (source == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1080,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<ImageSource?> _chooseImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Ambil dari kamera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
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
    return data['secure_url'] as String;
  }

  void _tambahTangkapan() {
    if (_ikanController.text.trim().isEmpty) return;
    setState(() {
      _tangkapan.add({
        'namaIkan': _ikanController.text.trim(),
        'berat': _beratController.text.trim().isEmpty
            ? ''
            : _beratController.text.trim(),
        'jumlah': int.tryParse(_jumlahController.text.trim()) ?? 1,
      });
      _ikanController.clear();
      _beratController.clear();
      _jumlahController.clear();
    });
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1B5E20)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _tanggal = '${picked.day}/${picked.month}/${picked.year}');
    }
  }

  Future<void> _submit() async {
    if (_spotController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nama spot wajib diisi!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      String imageUrl = '';
      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!);
      }

      await FirebaseFirestore.instance.collection('logbook').add({
        'userId': user.uid,
        'spotName': _spotController.text.trim(),
        'tanggal': _tanggal,
        'cuaca': _cuaca,
        'kondisiAir': _kondisiAir,
        'teknik': _teknikController.text.trim(),
        'umpan': _umpanController.text.trim(),
        'tangkapan': _tangkapan,
        'catatan': _catatanController.text.trim(),
        'imageUrl': imageUrl,
        'createdAt': Timestamp.now(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi mancing berhasil dicatat! 🎣'),
            backgroundColor: Color(0xFF1B5E20),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
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
          'Catat Sesi Mancing',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: const Text(
              'Simpan',
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
          // Foto hasil tangkapan
          _buildSectionTitle('📸 Foto Hasil Tangkapan'),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1B5E20),
                  style: BorderStyle.solid,
                ),
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
                          Icons.add_photo_alternate_outlined,
                          size: 40,
                          color: Color(0xFF1B5E20),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap untuk pilih foto',
                          style: TextStyle(color: Color(0xFF1B5E20)),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Info dasar
          _buildSectionTitle('📝 Info Sesi'),
          _buildTextField(_spotController, 'Nama Spot / Lokasi', true),
          const SizedBox(height: 12),

          // Tanggal
          GestureDetector(
            onTap: _pilihTanggal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF1B5E20),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(_tanggal, style: const TextStyle(fontSize: 15)),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Cuaca & Kondisi Air
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  'Cuaca',
                  _cuaca,
                  _cuacaList,
                  (v) => setState(() => _cuaca = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  'Kondisi Air',
                  _kondisiAir,
                  _kondisiAirList,
                  (v) => setState(() => _kondisiAir = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(_teknikController, 'Teknik Mancing', false),
          const SizedBox(height: 12),
          _buildTextField(_umpanController, 'Umpan yang Digunakan', false),
          const SizedBox(height: 16),

          // Hasil tangkapan
          _buildSectionTitle('🐟 Hasil Tangkapan'),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // List tangkapan
                if (_tangkapan.isNotEmpty) ...[
                  ...(_tangkapan.asMap().entries.map((entry) {
                    final i = entry.key;
                    final t = entry.value;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Text('🐟', style: TextStyle(fontSize: 24)),
                      title: Text(
                        t['namaIkan'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${t['jumlah']} ekor${t['berat'].isNotEmpty ? ' • ${t['berat']} kg' : ''}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => setState(() => _tangkapan.removeAt(i)),
                      ),
                    );
                  })),
                  const Divider(),
                ],

                // Input tambah tangkapan
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _ikanController,
                        decoration: InputDecoration(
                          hintText: 'Nama ikan',
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _beratController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Berat (kg)',
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _jumlahController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Jml',
                          filled: true,
                          fillColor: const Color(0xFFF5F5F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: _tambahTangkapan,
                      icon: const Icon(
                        Icons.add_circle,
                        color: Color(0xFF1B5E20),
                        size: 32,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Isi nama ikan lalu tap + untuk menambah',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Catatan
          _buildSectionTitle('📝 Catatan Tambahan'),
          TextField(
            controller: _catatanController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Ceritakan pengalamanmu mancing hari ini...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 32),

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
                      'Simpan Catatan Mancing 📒',
                      style: TextStyle(
                        fontSize: 15,
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1B5E20),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    bool required,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
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

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
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
}

// ============================================================
// DETAIL LOGBOOK SCREEN
// ============================================================

class DetailLogbookScreen extends StatelessWidget {
  final LogbookModel log;

  const DetailLogbookScreen({super.key, required this.log});

  Future<void> _hapus(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: const Text('Yakin ingin menghapus catatan sesi ini?'),
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
          .collection('logbook')
          .doc(log.id)
          .delete();
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: Text(
          log.spotName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: () => _hapus(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Foto
          if (log.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: log.imageUrl,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 16),

          // Info sesi
          _buildSection(
            '📝 Info Sesi',
            Column(
              children: [
                _buildRow('Tanggal', log.tanggal),
                _buildRow('Cuaca', log.cuaca),
                _buildRow('Kondisi Air', log.kondisiAir),
                if (log.teknik.isNotEmpty) _buildRow('Teknik', log.teknik),
                if (log.umpan.isNotEmpty) _buildRow('Umpan', log.umpan),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Hasil tangkapan
          _buildSection(
            '🐟 Hasil Tangkapan (${log.totalTangkapan} ekor)',
            log.tangkapan.isEmpty
                ? const Text(
                    'Tidak ada tangkapan tercatat',
                    style: TextStyle(color: Colors.grey),
                  )
                : Column(
                    children: log.tangkapan.map((t) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF1B5E20,
                          ).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(
                              0xFF1B5E20,
                            ).withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text('🐟', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t['namaIkan'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    '${t['jumlah']} ekor${(t['berat']?.toString() ?? '').isNotEmpty ? ' • ${t['berat']} kg' : ''}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 12),

          // Catatan
          if (log.catatan.isNotEmpty)
            _buildSection(
              '📝 Catatan',
              Text(
                log.catatan,
                style: const TextStyle(fontSize: 14, height: 1.5),
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
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

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
