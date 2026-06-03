import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../profile/screens/user_profile_screen.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/spot_like_service.dart';
import '../../../core/widgets/weather_widget.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/widgets/tidal_moon_widget.dart';
import '../../../core/widgets/comment_thread.dart';

class SpotDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;

  const SpotDetailScreen({super.key, required this.data, required this.docId});

  @override
  State<SpotDetailScreen> createState() => _SpotDetailScreenState();
}

class _SpotDetailScreenState extends State<SpotDetailScreen> {
  static const List<String> _tidalCategories = [
    'Muara',
    'Tepi Pantai',
    'Laut Dalam',
    'Tambak',
  ];
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _likeCount = SpotLikeService.getLikeCount(widget.data);
    _checkIfLiked();
    _incrementView();
  }

  Future<void> _laporkanSpot() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final alasan = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Laporkan Spot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Kenapa kamu melaporkan spot ini?',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ...[
              'Spot sudah tidak ada',
              'Lokasi berubah fungsi',
              'Info tidak akurat',
              'Foto tidak sesuai',
              'Spot berbahaya',
            ].map(
              (alasan) => ListTile(
                title: Text(alasan),
                leading: const Icon(Icons.flag_outlined, color: Colors.red),
                onTap: () => Navigator.pop(context, alasan),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );

    if (alasan == null) return;

    // Simpan laporan
    await FirebaseFirestore.instance
        .collection('spots')
        .doc(widget.docId)
        .collection('reports')
        .add({
          'userId': user.uid,
          'alasan': alasan,
          'createdAt': Timestamp.now(),
        });

    // Hitung total laporan
    final reports = await FirebaseFirestore.instance
        .collection('spots')
        .doc(widget.docId)
        .collection('reports')
        .count()
        .get();

    // Jika laporan >= 3, ubah status spot
    if ((reports.count ?? 0) >= 3) {
      await FirebaseFirestore.instance
          .collection('spots')
          .doc(widget.docId)
          .update({'status': 'diragukan'});
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan terkirim. Terima kasih! ✅'),
          backgroundColor: Color(0xFF1B5E20),
        ),
      );
    }
  }

  Future<void> _checkIfLiked() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('spots')
        .doc(widget.docId)
        .collection('likes')
        .doc(user.uid)
        .get();
    if (mounted) setState(() => _isLiked = doc.exists);
  }

  Future<void> _incrementView() async {
    await FirebaseFirestore.instance
        .collection('spots')
        .doc(widget.docId)
        .update({'views': FieldValue.increment(1)});
  }

  Future<void> _toggleLike() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final wasLiked = _isLiked;
    final previousLikeCount = _likeCount;
    setState(() {
      _isLiked = !wasLiked;
      _likeCount = wasLiked
          ? (_likeCount - 1).clamp(0, 999999).toInt()
          : _likeCount + 1;
    });

    try {
      final didLike = await SpotLikeService.toggleLike(
        spotId: widget.docId,
        userId: user.uid,
      );
      final latestSpot = await FirebaseFirestore.instance
          .collection('spots')
          .doc(widget.docId)
          .get();
      final latestLikes = SpotLikeService.getLikeCount(latestSpot.data() ?? {});

      if (mounted) {
        setState(() {
          _isLiked = didLike;
          _likeCount = latestLikes;
        });
      }

      if (didLike) {
        final spotOwnerId = widget.data['userId'] as String? ?? '';
        if (spotOwnerId.isNotEmpty && spotOwnerId != user.uid) {
          await NotificationService.notifyLike(
            spotOwnerId: spotOwnerId,
            likerName: user.displayName ?? 'Pemancing',
            spotName: widget.data['name'] ?? 'Spot Mancing',
            spotId: widget.docId,
            spotData: widget.data,
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLiked = wasLiked;
        _likeCount = previousLikeCount;
      });
      debugPrint('Like error: $e');
    }
  }

  Future<void> _notifySpotComment(Map<String, dynamic> commentData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final spotOwnerId = widget.data['userId'] as String? ?? '';
    if (spotOwnerId.isNotEmpty && spotOwnerId != user.uid) {
      await NotificationService.notifyComment(
        spotOwnerId: spotOwnerId,
        commenterName: user.displayName ?? 'Pemancing',
        spotName: widget.data['name'] ?? 'Spot Mancing',
        spotId: widget.docId,
        spotData: widget.data,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final createdAt = data['createdAt'] as Timestamp?;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          // Hero foto
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF1B5E20),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () {
                  SharePlus.instance.share(
                    ShareParams(
                      text:
                          '🙋‍♂️ Temanmu membagi spot mancing dari aplikasi Iteman: (Info TEmpat MANcing)\n\n'
                          '🎣 Cek spot mancing ini!\n'
                          '📍 ${widget.data['name']}\n'
                          '🌊 ${widget.data['kategoriPerairan']}\n'
                          '🐟 ${widget.data['targetIkan']}\n'
                          '📝 ${widget.data['description']}\n\n'
                          'Temukan spot mancing terbaik lainnya di aplikasi Iteman',
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.flag_outlined, color: Colors.white),
                onPressed: _laporkanSpot,
                tooltip: 'Laporkan Spot',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: data['imageUrl'] != null && data['imageUrl'] != ''
                  ? CachedNetworkImage(
                      imageUrl: data['imageUrl'],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFF1B5E20),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    )
                  : Container(
                      color: const Color(0xFF1B5E20),
                      child: const Icon(
                        Icons.phishing,
                        size: 80,
                        color: Colors.white54,
                      ),
                    ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header info
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              data['name'] ?? 'Spot Mancing',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _toggleLike,
                            child: Column(
                              children: [
                                Icon(
                                  _isLiked
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: _isLiked ? Colors.red : Colors.grey,
                                  size: 28,
                                ),
                                Text(
                                  '$_likeCount',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => UserProfileScreen(
                                  userId: data['userId'] ?? '',
                                  userName: data['userName'] ?? 'Pemancing',
                                ),
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF1B5E20),
                              backgroundImage:
                                  data['userPhotoUrl'] != null &&
                                      data['userPhotoUrl'] != ''
                                  ? NetworkImage(data['userPhotoUrl'])
                                  : null,
                              child:
                                  data['userPhotoUrl'] == null ||
                                      data['userPhotoUrl'] == ''
                                  ? const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 20,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            data['userName'] ?? 'Pemancing',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          Text(
                            createdAt != null
                                ? timeago.format(
                                    createdAt.toDate(),
                                    locale: 'id',
                                  )
                                : '',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (data['description'] != null &&
                          data['description'] != '')
                        Text(
                          data['description'],
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Cuaca real-time — hanya tampil kalau ada koordinat
                if (widget.data['latitude'] != null &&
                    widget.data['longitude'] != null) ...[
                  const SizedBox(height: 8),
                  WeatherWidget(
                    latitude: (widget.data['latitude'] as num).toDouble(),
                    longitude: (widget.data['longitude'] as num).toDouble(),
                    spotName: widget.data['name'] ?? 'Spot Mancing',
                  ),
                ],
                // Fase bulan & pasang surut
                // Tampilkan pasang surut hanya untuk spot laut/muara/pantai
                if (widget.data['latitude'] != null &&
                    widget.data['longitude'] != null) ...[
                  const SizedBox(height: 8),
                  TidalMoonWidget(
                    latitude: (widget.data['latitude'] as num).toDouble(),
                    longitude: (widget.data['longitude'] as num).toDouble(),
                    showTidal: _tidalCategories.contains(
                      widget.data['kategoriPerairan'] ?? '',
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                // Karakteristik
                _buildSection(
                  '🌊 Karakteristik Perairan',
                  Column(
                    children: [
                      _buildInfoRow(
                        'Kategori',
                        data['kategoriPerairan'] ?? '-',
                      ),
                      _buildInfoRow('Jenis Air', data['jenisAir'] ?? '-'),
                      _buildInfoRow(
                        'Kondisi Dasar',
                        data['kondisiDasar'] ?? '-',
                      ),
                      _buildInfoRow('Kedalaman', data['kedalaman'] ?? '-'),
                      _buildInfoRow('Arus', data['arus'] ?? '-'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Target ikan
                _buildSection(
                  '🐟 Target Ikan',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data['targetIkan'] != null &&
                          (data['targetIkan'] as List).isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: (data['targetIkan'] as List)
                              .map(
                                (ikan) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
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
                                    '🐟 $ikan',
                                    style: const TextStyle(
                                      color: Color(0xFF1B5E20),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        'Waktu Terbaik',
                        data['waktuTerbaik'] ?? '-',
                      ),
                      if (data['teknikUmpan'] != null &&
                          data['teknikUmpan'] != '')
                        _buildInfoRow('Teknik & Umpan', data['teknikUmpan']),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Fasilitas & Biaya
                _buildSection(
                  '🏕️ Fasilitas & Biaya',
                  Column(
                    children: [
                      if (data['fasilitas'] != null && data['fasilitas'] != '')
                        _buildInfoRow('Fasilitas', data['fasilitas']),
                      if (data['biaya'] != null && data['biaya'] != '')
                        _buildInfoRow('Biaya', data['biaya']),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _buildSection(
                  '🚗 Aksesibilitas & Keamanan',
                  Column(
                    children: [
                      if (data['aksesibilitas'] != null)
                        _buildInfoRow('Aksesibilitas', data['aksesibilitas']),
                      if (data['kebersihan'] != null)
                        _buildInfoRow('Kebersihan', data['kebersihan']),
                      if (data['keamanan'] != null)
                        _buildInfoRow('Keamanan', data['keamanan']),
                      if (data['aturanSetempat'] != null &&
                          data['aturanSetempat'] != '')
                        _buildInfoRow('Aturan', data['aturanSetempat']),
                      if (data['catchAndRelease'] == true)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
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
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.recycling,
                                color: Color(0xFF1B5E20),
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Catch & Release dianjurkan',
                                style: TextStyle(
                                  color: Color(0xFF1B5E20),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),

                // Komentar
                _buildSection(
                  '💬 Komentar',
                  CommentThread(
                    commentsRef: FirebaseFirestore.instance
                        .collection('spots')
                        .doc(widget.docId)
                        .collection('comments'),
                    ownerUserId: widget.data['userId'] ?? '',
                    onCommentAdded: _notifySpotComment,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
