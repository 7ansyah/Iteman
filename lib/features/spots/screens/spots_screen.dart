import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../../../core/widgets/map_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SpotsScreen extends StatefulWidget {
  const SpotsScreen({super.key});

  @override
  State<SpotsScreen> createState() => _SpotsScreenState();
}

class _SpotsScreenState extends State<SpotsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _ikanController = TextEditingController();
  final _teknikController = TextEditingController();
  final _fasilitasController = TextEditingController();
  final _biayaController = TextEditingController();

  String _kategoriPerairan = 'Danau/Waduk';
  String _jenisAir = 'Tawar';
  String _kondisiDasar = 'Berlumpur';
  String _kedalaman = 'Sedang (1-3m)';
  String _arus = 'Diam';
  String _waktuTerbaik = 'Subuh (05-07)';
  String _aksesibilitas = 'Mudah (jalan aspal)';
  String _kebersihan = 'Bersih';
  String _keamanan = 'Aman';
  bool _catchAndRelease = false;
  final _aturanController = TextEditingController();

  File? _imageFile;
  bool _isLoading = false;
  double? _latitude;
  double? _longitude;
  String? _selectedCommunityId;
  String? _selectedCommunityName;

  final List<String> _kategoriList = [
    'Rawa',
    'Danau/Waduk',
    'Kolam Pancing',
    'Sungai Kecil',
    'Sungai Besar',
    'Muara',
    'Tepi Pantai',
    'Laut Dalam',
    'Tambak',
  ];
  final List<String> _jenisAirList = ['Tawar', 'Payau', 'Asin'];
  final List<String> _kondisiDasarList = [
    'Berlumpur',
    'Berpasir',
    'Berbatu',
    'Berkarang',
    'Rumput Liar',
  ];
  final List<String> _kedalamanList = [
    'Dangkal (<1m)',
    'Sedang (1-3m)',
    'Dalam (>3m)',
  ];
  final List<String> _arusList = ['Diam', 'Pelan', 'Sedang', 'Deras'];
  final List<String> _waktuList = [
    'Subuh (05-07)',
    'Pagi (07-11)',
    'Sore (15-18)',
    'Malam (19-00)',
  ];
  final List<String> _aksesibilitasList = [
    'Mudah (jalan aspal)',
    'Cukup (jalan makadam)',
    'Sulit (jalan tanah)',
    'Sangat Sulit (jalan kaki)',
  ];

  final List<String> _kebersihanList = [
    'Sangat Bersih',
    'Bersih',
    'Cukup Bersih',
    'Kotor',
    'Sangat Kotor',
  ];

  final List<String> _keamananList = [
    'Sangat Aman',
    'Aman',
    'Cukup Aman',
    'Perlu Waspada',
    'Berbahaya',
  ];

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

  Future<void> _getLocationGPS() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aktifkan GPS terlebih dahulu')),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi GPS berhasil diambil ✅'),
          backgroundColor: Color(0xFF1B5E20),
        ),
      );
    }
  }

  Future<void> _getLocationManual() async {
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

  Future<String?> _uploadImage(File file) async {
    try {
      const cloudName = 'duwfcfamz'; // ganti ini
      const uploadPreset = 'iteman_spots';

      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final responseString = String.fromCharCodes(responseData);
      final jsonMap = json.decode(responseString);

      if (response.statusCode == 200) {
        return jsonMap['secure_url'] as String;
      } else {
        throw Exception('Upload gagal: ${jsonMap['error']['message']}');
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      rethrow;
    }
  }

  Future<void> _submitSpot() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih foto spot terlebih dahulu')),
      );
      return;
    }
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ambil lokasi GPS terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final imageUrl = await _uploadImage(_imageFile!);
      final docRef = FirebaseFirestore.instance.collection('spots').doc();

      await docRef.set({
        'id': docRef.id,
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'kategoriPerairan': _kategoriPerairan,
        'jenisAir': _jenisAir,
        'kondisiDasar': _kondisiDasar,
        'kedalaman': _kedalaman,
        'arus': _arus,
        'targetIkan': _ikanController.text
            .split(',')
            .map((e) => e.trim())
            .toList(),
        'waktuTerbaik': _waktuTerbaik,
        'teknikUmpan': _teknikController.text.trim(),
        'fasilitas': _fasilitasController.text.trim(),
        'biaya': _biayaController.text.trim(),
        'aksesibilitas': _aksesibilitas,
        'kebersihan': _kebersihan,
        'keamanan': _keamanan,
        'aturanSetempat': _aturanController.text.trim(),
        'catchAndRelease': _catchAndRelease,
        'latitude': _latitude,
        'longitude': _longitude,
        'imageUrl': imageUrl,
        'userId': user.uid,
        'userName': user.displayName ?? 'Pemancing',
        'userPhotoUrl': user.photoURL ?? '',
        'communityId': _selectedCommunityId,
        'communityName': _selectedCommunityName,
        'createdAt': Timestamp.now(),
        'likes': 0,
        'total like': 0,
        'views': 0,
      });

      // Update total spots di profil user
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {'totalSpots': FieldValue.increment(1)},
      );

      if (_selectedCommunityId != null) {
        try {
          await FirebaseFirestore.instance
              .collection('communities')
              .doc(_selectedCommunityId)
              .update({'spotCount': FieldValue.increment(1)});
        } on FirebaseException catch (e) {
          if (e.code != 'permission-denied') rethrow;
          debugPrint('spotCount update skipped by Firestore rules: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Spot berhasil ditambahkan! 🎣'),
            backgroundColor: Color(0xFF1B5E20),
          ),
        );
        _formKey.currentState!.reset();
        setState(() {
          _imageFile = null;
          _latitude = null;
          _longitude = null;
          _selectedCommunityId = null;
          _selectedCommunityName = null;
        });
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
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _ikanController.dispose();
    _teknikController.dispose();
    _fasilitasController.dispose();
    _biayaController.dispose();
    _aturanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text(
          'Tambah Spot Mancing',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionTitle('📸 Foto Spot'),
            _buildImagePicker(),
            const SizedBox(height: 16),

            _buildSectionTitle('📍 Lokasi GPS'),
            _buildLocationButton(),
            const SizedBox(height: 16),

            _buildSectionTitle('📝 Informasi Dasar'),
            _buildTextField(
              _nameController,
              'Nama Spot',
              'Contoh: Waduk Kedung Ombo',
              true,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              _descController,
              'Deskripsi',
              'Ceritakan kondisi spot ini...',
              false,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _buildCommunityPicker(),
            const SizedBox(height: 16),

            _buildSectionTitle('🌊 Karakteristik Perairan'),
            _buildDropdown(
              'Kategori Perairan',
              _kategoriPerairan,
              _kategoriList,
              (v) => setState(() => _kategoriPerairan = v!),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              'Jenis Air',
              _jenisAir,
              _jenisAirList,
              (v) => setState(() => _jenisAir = v!),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              'Kondisi Dasar',
              _kondisiDasar,
              _kondisiDasarList,
              (v) => setState(() => _kondisiDasar = v!),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              'Kedalaman',
              _kedalaman,
              _kedalamanList,
              (v) => setState(() => _kedalaman = v!),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              'Arus Air',
              _arus,
              _arusList,
              (v) => setState(() => _arus = v!),
            ),
            const SizedBox(height: 16),

            _buildSectionTitle('🐟 Target Ikan'),
            _buildTextField(
              _ikanController,
              'Jenis Ikan',
              'Contoh: Gabus, Nila, Patin (pisahkan koma)',
              true,
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              'Waktu Terbaik',
              _waktuTerbaik,
              _waktuList,
              (v) => setState(() => _waktuTerbaik = v!),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              _teknikController,
              'Teknik & Umpan',
              'Contoh: Dasaran, umpan cacing tanah',
              false,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            _buildSectionTitle('🏕️ Fasilitas & Biaya'),
            _buildTextField(
              _fasilitasController,
              'Fasilitas',
              'Contoh: Toilet, Warung, Parkir',
              false,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              _biayaController,
              'Biaya',
              'Contoh: Gratis / Rp 10.000 per orang',
              false,
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('🚗 Aksesibilitas & Keamanan'),
            _buildDropdown(
              'Aksesibilitas',
              _aksesibilitas,
              _aksesibilitasList,
              (v) => setState(() => _aksesibilitas = v!),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              'Kebersihan Spot',
              _kebersihan,
              _kebersihanList,
              (v) => setState(() => _kebersihan = v!),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              'Keamanan',
              _keamanan,
              _keamananList,
              (v) => setState(() => _keamanan = v!),
            ),
            const SizedBox(height: 16),

            _buildSectionTitle('📋 Aturan & Etika'),
            _buildTextField(
              _aturanController,
              'Aturan Setempat',
              'Contoh: Tidak boleh pakai jala, wajib bayar retribusi',
              false,
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Catch & Release toggle
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text(
                  'Catch & Release',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Ikan yang tertangkap wajib/dianjurkan dilepas kembali',
                  style: TextStyle(fontSize: 12),
                ),
                value: _catchAndRelease,
                onChanged: (v) => setState(() => _catchAndRelease = v),
                activeThumbColor: const Color(0xFF1B5E20),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitSpot,
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
                        'Simpan Spot 🎣',
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

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
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
                    size: 48,
                    color: Color(0xFF1B5E20),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap untuk pilih foto spot',
                    style: TextStyle(color: Color(0xFF1B5E20)),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildLocationButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_latitude != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF1B5E20),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1B5E20),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  leading: const Icon(
                    Icons.my_location,
                    color: Color(0xFF1B5E20),
                  ),
                  title: const Text(
                    'GPS Otomatis',
                    style: TextStyle(fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Lokasi saat ini',
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: _getLocationGPS,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey[200]),
              Expanded(
                child: ListTile(
                  leading: const Icon(Icons.map, color: Color(0xFF1B5E20)),
                  title: const Text(
                    'Pilih di Peta',
                    style: TextStyle(fontSize: 13),
                  ),
                  subtitle: const Text(
                    'Lebih akurat',
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: _getLocationManual,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityPicker() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('communities').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        return FutureBuilder<List<QueryDocumentSnapshot>>(
          future: _filterJoinedCommunityDocs(docs, user.uid),
          builder: (context, joinedSnapshot) {
            if (joinedSnapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 56,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
                ),
              );
            }

            final joinedDocs = joinedSnapshot.data ?? [];
            if (joinedDocs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.groups, color: Color(0xFF1B5E20)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Gabung komunitas dulu jika ingin menautkan spot.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<String?>(
                initialValue: _selectedCommunityId,
                decoration: const InputDecoration(
                  labelText: 'Tautkan ke Komunitas',
                  border: InputBorder.none,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Tidak ditautkan'),
                  ),
                  ...joinedDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem<String?>(
                      value: doc.id,
                      child: Text(data['name'] ?? 'Komunitas'),
                    );
                  }),
                ],
                onChanged: (value) {
                  Map<String, dynamic>? selectedData;
                  for (final doc in joinedDocs) {
                    if (doc.id == value) {
                      selectedData = doc.data() as Map<String, dynamic>;
                      break;
                    }
                  }
                  setState(() {
                    _selectedCommunityId = value;
                    _selectedCommunityName = selectedData?['name'];
                  });
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<List<QueryDocumentSnapshot>> _filterJoinedCommunityDocs(
    List<QueryDocumentSnapshot> docs,
    String userId,
  ) async {
    final joined = <QueryDocumentSnapshot>[];
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['ownerId'] == userId) {
        joined.add(doc);
        continue;
      }
      final memberDoc = await FirebaseFirestore.instance
          .collection('communities')
          .doc(doc.id)
          .collection('members')
          .doc(userId)
          .get();
      if (memberDoc.exists) joined.add(doc);
    }
    return joined;
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
      validator: required
          ? (v) => v == null || v.isEmpty ? '$label wajib diisi' : null
          : null,
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
