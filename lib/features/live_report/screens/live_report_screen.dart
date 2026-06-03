import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'dart:io';
import '../../../core/widgets/map_picker_screen.dart';
import '../../../core/widgets/comment_thread.dart';

class LiveReportScreen extends StatefulWidget {
  const LiveReportScreen({super.key});

  @override
  State<LiveReportScreen> createState() => _LiveReportScreenState();
}

class _LiveReportScreenState extends State<LiveReportScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          '🔴 Live Report',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.red),
            onPressed: () => _showBuatReportSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info 24 jam
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white54, size: 14),
                SizedBox(width: 6),
                Text(
                  'Report otomatis hilang setelah 24 jam',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),

          // Story bubbles
          SizedBox(
            height: 100,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('live_reports')
                  .where('expiresAt', isGreaterThan: Timestamp.now())
                  .orderBy('expiresAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada live report hari ini',
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final data =
                        snapshot.data!.docs[index].data()
                            as Map<String, dynamic>;
                    final docId = snapshot.data!.docs[index].id;
                    return _buildStoryBubble(context, data, docId, user.uid);
                  },
                );
              },
            ),
          ),

          const Divider(color: Colors.white12),

          // Feed live reports
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('live_reports')
                  .where('expiresAt', isGreaterThan: Timestamp.now())
                  .orderBy('expiresAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🎣', style: TextStyle(fontSize: 60)),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum ada yang lagi mancing',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Bagikan kondisi spot real-time\ndan bantu sesama pemancing!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showBuatReportSheet(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Buat Live Report'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
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

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildReportCard(context, data, doc.id, user.uid);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBuatReportSheet(context),
        backgroundColor: Colors.red,
        icon: const Icon(Icons.fiber_manual_record, color: Colors.white),
        label: const Text(
          'Live Report',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildStoryBubble(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
    String currentUserId,
  ) {
    final isOwn = data['userId'] == currentUserId;
    return GestureDetector(
      onTap: () => _showReportDetail(context, data, docId),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isOwn
                      ? [Colors.blue, Colors.purple]
                      : [Colors.red, Colors.orange],
                ),
              ),
              child: CircleAvatar(
                backgroundColor: const Color(0xFF1A1A2E),
                backgroundImage:
                    data['userPhotoUrl'] != null && data['userPhotoUrl'] != ''
                    ? NetworkImage(data['userPhotoUrl'])
                    : null,
                child:
                    data['userPhotoUrl'] == null || data['userPhotoUrl'] == ''
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 68,
              child: Text(
                data['userName'] ?? '',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
    String currentUserId,
  ) {
    final expiresAt = data['expiresAt'] as Timestamp;
    final remainingHours = expiresAt
        .toDate()
        .difference(DateTime.now())
        .inHours;
    final remainingMinutes =
        expiresAt.toDate().difference(DateTime.now()).inMinutes % 60;
    final isOwn = data['userId'] == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      data['userPhotoUrl'] != null && data['userPhotoUrl'] != ''
                      ? NetworkImage(data['userPhotoUrl'])
                      : null,
                  child:
                      data['userPhotoUrl'] == null || data['userPhotoUrl'] == ''
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['userName'] ?? 'Pemancing',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '📍 ${data['spotName'] ?? ''}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Timer
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, color: Colors.red, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${remainingHours}j ${remainingMinutes}m',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOwn)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                      size: 20,
                    ),
                    onPressed: () => _hapusReport(docId),
                  ),
              ],
            ),
          ),

          // Foto
          if (data['imageUrl'] != null && data['imageUrl'] != '')
            GestureDetector(
              onTap: () => _showReportDetail(context, data, docId),
              child: CachedNetworkImage(
                imageUrl: data['imageUrl'],
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),

          // Konten
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status kondisi
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _buildStatusChip('🌊 ${data['kondisiAir'] ?? ''}'),
                    _buildStatusChip('☁️ ${data['cuaca'] ?? ''}'),
                    if (data['sudahDapat'] == true)
                      _buildStatusChip(
                        '🐟 Sudah Dapat Ikan!',
                        isHighlight: true,
                      ),
                  ],
                ),
                if (data['pesan'] != null && data['pesan'] != '') ...[
                  const SizedBox(height: 8),
                  Text(
                    data['pesan'],
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (data['latitude'] != null && data['longitude'] != null)
                      TextButton.icon(
                        onPressed: () => _openReportLocation(context, data),
                        icon: const Icon(Icons.map, color: Colors.white70),
                        label: const Text(
                          'Lihat Lokasi',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _showCommentsSheet(context, docId, data),
                      icon: const Icon(
                        Icons.comment_outlined,
                        color: Colors.white70,
                      ),
                      label: const Text(
                        'Komentar',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlight
            ? const Color(0xFF1B5E20).withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHighlight
              ? const Color(0xFF4CAF50).withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isHighlight ? const Color(0xFF4CAF50) : Colors.white,
          fontSize: 12,
          fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  void _showReportDetail(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (data['imageUrl'] != null && data['imageUrl'] != '')
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: data['imageUrl'],
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 12),
            Text(
              '📍 ${data['spotName'] ?? 'Spot Mancing'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data['pesan'] ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _buildStatusChip('🌊 ${data['kondisiAir'] ?? ''}'),
                _buildStatusChip('☁️ ${data['cuaca'] ?? ''}'),
                if (data['sudahDapat'] == true)
                  _buildStatusChip('🐟 Dapat Ikan!', isHighlight: true),
              ],
            ),
            if (data['latitude'] != null && data['longitude'] != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openReportLocation(context, data),
                  icon: const Icon(Icons.map),
                  label: const Text('Lihat Titik Lokasi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showCommentsSheet(context, docId, data);
                },
                icon: const Icon(Icons.comment_outlined),
                label: const Text('Komentar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openReportLocation(BuildContext context, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLat: (data['latitude'] as num).toDouble(),
          initialLng: (data['longitude'] as num).toDouble(),
        ),
      ),
    );
  }

  void _showCommentsSheet(
    BuildContext context,
    String reportId,
    Map<String, dynamic> reportData,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          _LiveReportCommentsSheet(reportId: reportId, reportData: reportData),
    );
  }

  Future<void> _hapusReport(String docId) async {
    await FirebaseFirestore.instance
        .collection('live_reports')
        .doc(docId)
        .delete();
  }

  void _showBuatReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _BuatReportSheet(),
    );
  }
}

class _BuatReportSheet extends StatefulWidget {
  const _BuatReportSheet();

  @override
  State<_BuatReportSheet> createState() => _BuatReportSheetState();
}

class _BuatReportSheetState extends State<_BuatReportSheet> {
  final _spotController = TextEditingController();
  final _pesanController = TextEditingController();
  String _kondisiAir = 'Jernih';
  String _cuaca = 'Cerah';
  bool _sudahDapat = false;
  File? _imageFile;
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;

  final List<String> _kondisiList = ['Jernih', 'Agak Keruh', 'Keruh', 'Banjir'];
  final List<String> _cuacaList = [
    'Cerah',
    'Berawan',
    'Mendung',
    'Gerimis',
    'Hujan',
  ];

  @override
  void dispose() {
    _spotController.dispose();
    _pesanController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await _chooseImageSource();
    if (source == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 1080,
      imageQuality: 75,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<ImageSource?> _chooseImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.white),
              title: const Text(
                'Ambil dari kamera',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text(
                'Pilih dari galeri',
                style: TextStyle(color: Colors.white),
              ),
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
    if (_spotController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nama spot wajib diisi!')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      String imageUrl = '', videoUrl = '';
      if (_imageFile != null) {
        final r = await _uploadMedia(_imageFile!);
        imageUrl = r['imageUrl'] ?? '';
        videoUrl = r['videoUrl'] ?? '';
      }

      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 24));

      await FirebaseFirestore.instance.collection('live_reports').add({
        'userId': user.uid,
        'userName': user.displayName ?? 'Pemancing',
        'userPhotoUrl': user.photoURL ?? '',
        'spotName': _spotController.text.trim(),
        'pesan': _pesanController.text.trim(),
        'kondisiAir': _kondisiAir,
        'cuaca': _cuaca,
        'sudahDapat': _sudahDapat,
        'latitude': _latitude,
        'longitude': _longitude,
        'imageUrl': imageUrl,
        'createdAt': Timestamp.now(),
        'expiresAt': Timestamp.fromDate(expiresAt),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Live report dibagikan! 🎣'),
            backgroundColor: Colors.red,
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
        color: Color(0xFF16213E),
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
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '🔴 Buat Live Report',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Report akan hilang otomatis setelah 24 jam',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // Foto
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
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
                            color: Colors.white38,
                            size: 36,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tambah Foto (opsional)',
                            style: TextStyle(color: Colors.white38),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Nama spot
            TextField(
              controller: _spotController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nama Spot / Lokasi',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.location_on, color: Colors.red),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _latitude == null
                              ? 'Titik lokasi belum dipilih'
                              : '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                          style: const TextStyle(color: Colors.white),
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
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
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
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Pesan
            TextField(
              controller: _pesanController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ceritakan kondisi spot sekarang...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Kondisi & Cuaca
            Row(
              children: [
                Expanded(
                  child: _buildDarkDropdown(
                    'Kondisi Air',
                    _kondisiAir,
                    _kondisiList,
                    (v) => setState(() => _kondisiAir = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDarkDropdown(
                    'Cuaca',
                    _cuaca,
                    _cuacaList,
                    (v) => setState(() => _cuaca = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Sudah dapat ikan
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text(
                  '🐟 Sudah Dapat Ikan!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                value: _sudahDapat,
                onChanged: (v) => setState(() => _sudahDapat = v),
                activeThumbColor: const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '🔴 Bagikan Live Report',
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

  Widget _buildDarkDropdown(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        dropdownColor: const Color(0xFF16213E),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          border: InputBorder.none,
        ),
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(color: Colors.white)),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _LiveReportCommentsSheet extends StatefulWidget {
  final String reportId;
  final Map<String, dynamic> reportData;

  const _LiveReportCommentsSheet({
    required this.reportId,
    required this.reportData,
  });

  @override
  State<_LiveReportCommentsSheet> createState() =>
      _LiveReportCommentsSheetState();
}

class _LiveReportCommentsSheetState extends State<_LiveReportCommentsSheet> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Komentar ${widget.reportData['spotName'] ?? ''}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: CommentThread(
                  commentsRef: FirebaseFirestore.instance
                      .collection('live_reports')
                      .doc(widget.reportId)
                      .collection('comments'),
                  ownerUserId: widget.reportData['userId'] ?? '',
                  accentColor: Colors.red,
                  darkMode: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
