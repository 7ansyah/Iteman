import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'dart:io';
import '../models/lapak_model.dart';
import '../../../core/widgets/map_picker_screen.dart';

class LapakScreen extends StatefulWidget {
  const LapakScreen({super.key});

  @override
  State<LapakScreen> createState() => _LapakScreenState();
}

class _LapakScreenState extends State<LapakScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterKategori = 'Semua';
  String _filterWilayah = '';

  final List<String> _kategoriList = [
    'Semua',
    'Joran & Reel',
    'Umpan & Kail',
    'Perlengkapan',
    'Promosi Kolam',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text(
          '🛒 Lapak Iteman',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _showTambahIklanSheet(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Semua Iklan'),
            Tab(text: 'Iklanku'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSemuaIklan(), _buildIklanku()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTambahIklanSheet(context),
        backgroundColor: Colors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Pasang Iklan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSemuaIklan() {
    return Column(
      children: [
        // Filter kategori
        Container(
          color: Colors.white,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: TextField(
                  onChanged: (value) =>
                      setState(() => _filterWilayah = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Cari wilayah penjual...',
                    prefixIcon: const Icon(Icons.location_on),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  itemCount: _kategoriList.length,
                  itemBuilder: (context, index) {
                    final k = _kategoriList[index];
                    final isSelected = _filterKategori == k;
                    return GestureDetector(
                      onTap: () => setState(() => _filterKategori = k),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.orange : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          k,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _buildQuery(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmpty();
              }

              final items = snapshot.data!.docs
                  .map(
                    (d) => LapakModel.fromMap(
                      d.data() as Map<String, dynamic>,
                      d.id,
                    ),
                  )
                  .where((l) => !l.isSold)
                  .where(
                    (l) =>
                        _filterWilayah.isEmpty ||
                        l.wilayah.toLowerCase().contains(_filterWilayah),
                  )
                  .toList();

              // Premium dulu
              items.sort((a, b) => b.isPremium ? 1 : (a.isPremium ? -1 : 0));

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    _buildLapakCard(context, items[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Stream<QuerySnapshot> _buildQuery() {
    Query query = FirebaseFirestore.instance
        .collection('lapak')
        .where('expiresAt', isGreaterThan: Timestamp.now());

    if (_filterKategori != 'Semua') {
      query = FirebaseFirestore.instance
          .collection('lapak')
          .where('kategori', isEqualTo: _filterKategori)
          .where('expiresAt', isGreaterThan: Timestamp.now());
    }

    return query.snapshots();
  }

  Widget _buildIklanku() {
    final user = FirebaseAuth.instance.currentUser!;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lapak')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orange),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🛒', style: TextStyle(fontSize: 60)),
                const SizedBox(height: 16),
                const Text(
                  'Belum ada iklan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pasang iklan jual beli\nalat pancing atau promosi kolammu!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showTambahIklanSheet(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Pasang Iklan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
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

        final items = snapshot.data!.docs
            .map(
              (d) => LapakModel.fromMap(d.data() as Map<String, dynamic>, d.id),
            )
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (context, index) =>
              _buildMyLapakCard(context, items[index]),
        );
      },
    );
  }

  Widget _buildLapakCard(BuildContext context, LapakModel item) {
    return GestureDetector(
      onTap: () => _showDetailIklan(context, item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: item.isPremium
              ? Border.all(color: Colors.orange, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: item.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          width: double.infinity,
                          height: 120,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: double.infinity,
                          height: 120,
                          color: Colors.orange.withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.shopping_bag,
                            color: Colors.orange,
                            size: 40,
                          ),
                        ),
                ),
                if (item.isPremium)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '⭐ UNGGULAN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.kondisi,
                      style: const TextStyle(color: Colors.white, fontSize: 9),
                    ),
                  ),
                ),
              ],
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.judul,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.harga,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.userName,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.wilayah.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '📍 ${item.wilayah}',
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyLapakCard(BuildContext context, LapakModel item) {
    final isExpired = item.expiresAt.toDate().isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: item.isSold
            ? Border.all(color: Colors.grey)
            : isExpired
            ? Border.all(color: Colors.red)
            : item.isPremium
            ? Border.all(color: Colors.orange, width: 2)
            : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: item.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 80,
                    height: 80,
                    color: Colors.orange.withValues(alpha: 0.1),
                    child: const Icon(Icons.shopping_bag, color: Colors.orange),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.judul,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.isPremium)
                      const Text('⭐', style: TextStyle(fontSize: 14)),
                  ],
                ),
                Text(
                  item.harga,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (item.isSold)
                  const Text(
                    '✅ Sudah Terjual',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  )
                else if (isExpired)
                  const Text(
                    '⏰ Iklan Kadaluarsa',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  )
                else
                  Text(
                    'Aktif hingga: ${item.expiresAt.toDate().day}/${item.expiresAt.toDate().month}/${item.expiresAt.toDate().year}',
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
              ],
            ),
          ),

          // Actions
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'sold') {
                await FirebaseFirestore.instance
                    .collection('lapak')
                    .doc(item.id)
                    .update({'isSold': true});
              } else if (value == 'delete') {
                await FirebaseFirestore.instance
                    .collection('lapak')
                    .doc(item.id)
                    .delete();
              }
            },
            itemBuilder: (context) => [
              if (!item.isSold)
                const PopupMenuItem(
                  value: 'sold',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 18),
                      SizedBox(width: 8),
                      Text('Tandai Terjual'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 18),
                    SizedBox(width: 8),
                    Text('Hapus Iklan', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🛒', style: TextStyle(fontSize: 60)),
          SizedBox(height: 16),
          Text(
            'Belum ada iklan',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Jadilah yang pertama berjualan\ndi Lapak Iteman!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showDetailIklan(BuildContext context, LapakModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
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

            if (item.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: Text(
                    item.judul,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (item.isPremium)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '⭐ Unggulan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              item.harga,
              style: const TextStyle(
                fontSize: 22,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip(item.kategori),
                _buildChip(item.kondisi),
                if (item.wilayah.isNotEmpty) _buildChip('📍 ${item.wilayah}'),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              item.deskripsi,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Penjual
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: item.userPhotoUrl.isNotEmpty
                        ? NetworkImage(item.userPhotoUrl)
                        : null,
                    child: item.userPhotoUrl.isEmpty
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Penjual',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (item.latitude != null && item.longitude != null) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MapPickerScreen(
                        initialLat: item.latitude,
                        initialLng: item.longitude,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.map),
                  label: const Text('Lihat Lokasi Penjual'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Tombol hubungi
            if (item.userPhone.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: item.userPhone));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nomor WA disalin ke clipboard ✅'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone),
                  label: Text('Hubungi via WA: ${item.userPhone}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.orange),
      ),
    );
  }

  void _showTambahIklanSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _TambahIklanSheet(),
    );
  }
}

// ============================================================
// TAMBAH IKLAN SHEET
// ============================================================

class _TambahIklanSheet extends StatefulWidget {
  const _TambahIklanSheet();

  @override
  State<_TambahIklanSheet> createState() => _TambahIklanSheetState();
}

class _TambahIklanSheetState extends State<_TambahIklanSheet> {
  final _kodeController = TextEditingController();
  bool _kodeValid = false;
  bool _isCheckingKode = false;
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _hargaController = TextEditingController();
  final _phoneController = TextEditingController();
  final _wilayahController = TextEditingController();

  String _kategori = 'Joran & Reel';
  String _kondisi = 'Baru';
  bool _isPremium = false;
  File? _imageFile;
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;

  final List<String> _kategoriList = [
    'Joran & Reel',
    'Umpan & Kail',
    'Perlengkapan',
    'Promosi Kolam',
    'Lainnya',
  ];

  final List<String> _kondisiList = [
    'Baru',
    'Seperti Baru',
    'Bekas',
    'Perlu Perbaikan',
  ];

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _hargaController.dispose();
    _phoneController.dispose();
    _wilayahController.dispose();
    super.dispose();
  }

  Future<void> _verifikasiKode() async {
    final kode = _kodeController.text.trim().toUpperCase();
    if (kode.isEmpty) return;

    setState(() => _isCheckingKode = true);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('premium_codes')
          .where('code', isEqualTo: kode)
          .where('isUsed', isEqualTo: false)
          .get();

      if (snap.docs.isNotEmpty) {
        setState(() {
          _kodeValid = true;
          _isPremium = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kode premium valid! ✅'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() => _kodeValid = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kode tidak valid atau sudah digunakan!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isCheckingKode = false);
    }
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
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
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
    return data['secure_url'].toString();
  }

  Future<void> _getLocationGPS() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi belum diberikan')),
        );
      }
      return;
    }
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
    });
  }

  Future<void> _pickLocationOnMap() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MapPickerScreen(initialLat: _latitude, initialLng: _longitude),
      ),
    );
    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
    }
  }

  Future<void> _submit() async {
    if (_judulController.text.trim().isEmpty ||
        _hargaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan harga wajib diisi!')),
      );
      return;
    }

    // Validasi kode premium
    if (_isPremium && !_kodeValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan kode premium yang valid!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      String phone = _phoneController.text.trim();
      if (phone.isEmpty) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        phone = (userDoc.data() ?? {})['phone'] ?? '';
      }

      String imageUrl = '';
      if (_imageFile != null) {
        imageUrl = await _uploadImage(_imageFile!);
      }

      final now = DateTime.now();
      final expiresAt = now.add(Duration(days: _isPremium ? 30 : 7));

      await FirebaseFirestore.instance.collection('lapak').add({
        'userId': user.uid,
        'userName': user.displayName ?? 'Pemancing',
        'userPhotoUrl': user.photoURL ?? '',
        'userPhone': phone,
        'judul': _judulController.text.trim(),
        'deskripsi': _deskripsiController.text.trim(),
        'harga': _hargaController.text.trim(),
        'kategori': _kategori,
        'kondisi': _kondisi,
        'wilayah': _wilayahController.text.trim(),
        'latitude': _latitude,
        'longitude': _longitude,
        'imageUrl': imageUrl,
        'isPremium': _isPremium,
        'isSold': false,
        'createdAt': Timestamp.now(),
        'expiresAt': Timestamp.fromDate(expiresAt),
      });

      // Tandai kode premium sudah dipakai
      if (_isPremium && _kodeValid) {
        final kode = _kodeController.text.trim().toUpperCase();
        final snap = await FirebaseFirestore.instance
            .collection('premium_codes')
            .where('code', isEqualTo: kode)
            .get();
        for (final doc in snap.docs) {
          await doc.reference.update({
            'isUsed': true,
            'usedBy': user.uid,
            'usedAt': Timestamp.now(),
          });
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isPremium
                  ? 'Iklan unggulan dipasang 30 hari! ⭐'
                  : 'Iklan dipasang 7 hari! 🛒',
            ),
            backgroundColor: Colors.orange,
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
              '🛒 Pasang Iklan Lapak',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 20),

            // Foto
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
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
                            color: Colors.orange,
                            size: 36,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tambah Foto Produk',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),

            _buildTextField(
              _judulController,
              'Judul Iklan',
              'Contoh: Joran Shimano Bekas',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              _hargaController,
              'Harga',
              'Contoh: Rp 150.000 atau Nego',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              _deskripsiController,
              'Deskripsi',
              'Jelaskan kondisi, ukuran, dll...',
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              _phoneController,
              'Nomor WhatsApp',
              'Nomor untuk dihubungi pembeli',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              _wilayahController,
              'Wilayah Penjual',
              'Contoh: Cirebon, Jawa Barat',
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _latitude == null
                              ? 'Lokasi detail penjual belum dipilih'
                              : '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _getLocationGPS,
                          icon: const Icon(Icons.my_location),
                          label: const Text('GPS'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickLocationOnMap,
                          icon: const Icon(Icons.map),
                          label: const Text('Peta'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    'Kategori',
                    _kategori,
                    _kategoriList,
                    (v) => setState(() => _kategori = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdown(
                    'Kondisi',
                    _kondisi,
                    _kondisiList,
                    (v) => setState(() => _kondisi = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Premium toggle
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isPremium
                    ? Colors.orange.withValues(alpha: 0.05)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isPremium ? Colors.orange : Colors.grey[300]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Iklan Unggulan (Premium)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Tayang 7 hari • Posisi teratas • Badge Unggulan',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Info harga
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '💰 Harga Iklan Premium: Rp 15.000/iklan',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(color: Colors.orange),
                        const SizedBox(height: 8),
                        const Text(
                          '📋 Cara mendapatkan kode premium:',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildStep(
                          '1',
                          'Transfer Rp 15.000 via QRIS atau rekening di bawah',
                        ),
                        _buildStep('2', 'Screenshot bukti transfer'),
                        _buildStep(
                          '3',
                          'Kirim bukti ke WA Admin: 082322210005',
                        ),
                        _buildStep('4', 'Kode premium dikirim dalam 1x24 jam'),
                        _buildStep('5', 'Masukkan kode di kolom di bawah'),
                        const SizedBox(height: 10),
                        const Text(
                          '🏦 Rekening Admin:',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Dana: 082322210005\n'
                          'BRI: 578801015633532 a/n Juansah\n'
                          'SEABANK: 901259382692 a/n Juansah\n'
                          'QRIS: Scan QR di halaman Donasi',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Input kode
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _kodeController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'Masukkan kode premium...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: _kodeValid
                                    ? Colors.green
                                    : Colors.grey[300]!,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: _kodeValid
                                    ? Colors.green
                                    : Colors.grey[300]!,
                              ),
                            ),
                            suffixIcon: _kodeValid
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _isCheckingKode
                          ? const CircularProgressIndicator(
                              color: Colors.orange,
                            )
                          : ElevatedButton(
                              onPressed: _verifikasiKode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              child: const Text('Cek'),
                            ),
                    ],
                  ),
                ],
              ),
            ),

            if (_isPremium) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '💡 Iklan Premium akan muncul di posisi teratas '
                  'dan terselip di setiap 5 postingan Feed. '
                  'Hubungi admin untuk pembayaran premium.',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isPremium
                            ? 'Pasang Iklan Unggulan ⭐'
                            : 'Pasang Iklan Gratis 🛒',
                        style: const TextStyle(
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

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
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
          borderSide: const BorderSide(color: Colors.orange),
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
}
