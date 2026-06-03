import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../spots/screens/spot_detail_screen.dart';
import '../../mancing_bareng/screens/mancing_bareng_screen.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../../notifications/screens/notification_screen.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/weather_service.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/services/tidal_service.dart';
import '../../live_report/screens/live_report_screen.dart';
import '../../event/screens/event_screen.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/spot_like_service.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        elevation: 0,
        toolbarHeight: 64,
        title: Image.asset(
          'assets/images/logo_header.png',
          height: 52,
          fit: BoxFit.contain,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.live_tv, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LiveReportScreen()),
            ),
            tooltip: 'Live Report',
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EventScreen()),
            ),
            tooltip: 'Event & Lomba',
          ),
          IconButton(
            icon: const Icon(Icons.people_alt_outlined, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MancingBarengScreen()),
            ),
            tooltip: 'Mancing Bareng',
          ),
          IconButton(
            icon: _UnreadNotificationBadge(userId: user?.uid),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('spots')
            .orderBy('createdAt', descending: true)
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyFeed(user);
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            itemCount: snapshot.data!.docs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return _buildWelcomeBanner(user);
              final doc = snapshot.data!.docs[index - 1];
              final data = doc.data() as Map<String, dynamic>;
              return _buildSpotCard(context, data, doc.id);
            },
          );
        },
      ),
    );
  }

  Widget _buildWelcomeBanner(User? user) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getWeatherForBanner(),
      builder: (context, snapshot) {
        final weather = snapshot.data;
        return Container(
          margin: const EdgeInsets.all(16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, ${user?.displayName?.split(' ').first ?? "Pemancing"}! 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Spot mancing terbaru dari komunitas',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (weather != null)
                    Column(
                      children: [
                        Text(
                          weather['emoji'],
                          style: const TextStyle(fontSize: 32),
                        ),
                        Text(
                          '${weather['temperature']}°C',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (weather != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    weather['fishingAdvice'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              // Mini fase bulan di banner
              Builder(
                builder: (context) {
                  final moon = TidalService.getMoonPhase();
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          moon['emoji'],
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${moon['phase']} • ${moon['illumination']}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (moon['isFavorable']) ...[
                          const SizedBox(width: 6),
                          const Text('⭐', style: TextStyle(fontSize: 12)),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _getWeatherForBanner() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition();
      return WeatherService.getWeather(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      return null;
    }
  }

  Widget _buildEmptyFeed(User? user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildWelcomeBanner(user),
          const SizedBox(height: 32),
          const Icon(Icons.phishing, size: 60, color: Color(0xFFCCCCCC)),
          const SizedBox(height: 16),
          const Text(
            'Belum ada spot',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Jadilah yang pertama berbagi\nspot mancing di komunitasmu!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotCard(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
  ) {
    final createdAt = data['createdAt'] as Timestamp?;
    final timeAgoStr = createdAt != null
        ? timeago.format(createdAt.toDate(), locale: 'id')
        : '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SpotDetailScreen(data: data, docId: docId),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            // Header user
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['userName'] ?? 'Pemancing',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '📍 ${data['name'] ?? 'Spot Mancing'} • $timeAgoStr',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data['kategoriPerairan'] ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Foto spot
            if (data['imageUrl'] != null && data['imageUrl'] != '')
              CachedNetworkImage(
                imageUrl: data['imageUrl'],
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 220,
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 220,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),

            // Info spot
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildTag('💧 ${data['jenisAir'] ?? ''}'),
                      _buildTag('⏰ ${data['waktuTerbaik'] ?? ''}'),
                      if (data['targetIkan'] != null &&
                          (data['targetIkan'] as List).isNotEmpty)
                        _buildTag(
                          '🐟 ${(data['targetIkan'] as List).take(2).join(', ')}',
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Deskripsi
                  if (data['description'] != null && data['description'] != '')
                    Text(
                      data['description'],
                      style: const TextStyle(fontSize: 14, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),

                  // Action buttons
                  Row(
                    children: [
                      _buildFeedLikeButton(data, docId),
                      const SizedBox(width: 16),
                      _buildActionButton(
                        Icons.comment_outlined,
                        'Komentar',
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SpotDetailScreen(data: data, docId: docId),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Tombol Bagikan — fungsional
                      GestureDetector(
                        onTap: () {
                          final spotName = data['name'] ?? 'Spot Mancing';
                          final kategori = data['kategoriPerairan'] ?? '';
                          final ikan = data['targetIkan'] != null
                              ? (data['targetIkan'] as List).join(', ')
                              : '';
                          final deskripsi = data['description'] ?? '';
                          SharePlus.instance.share(
                            ShareParams(
                              text:
                                  '🙋‍♂️ Temanmu membagi spot mancing dari aplikasi Iteman: (Info TEmpat MANcing)\n\n'
                                  '🎣 Cek spot mancing keren ini!\n'
                                  '📍 $spotName\n'
                                  '🌊 $kategori\n'
                                  '🐟 Ikan: $ikan\n\n'
                                  '📝 $deskripsi\n\n'
                                  'Temukan spot mancing terbaik lainnya di aplikasi Iteman!',
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Icon(
                              Icons.share_outlined,
                              size: 20,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Bagikan',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Tombol Simpan — fungsional
                      _buildSaveButton(data, docId),
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

  Widget _buildFeedLikeButton(Map<String, dynamic> data, String docId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _buildActionButton(
        Icons.favorite_border,
        '${SpotLikeService.getLikeCount(data)}',
        null,
      );
    }

    final spotRef = FirebaseFirestore.instance.collection('spots').doc(docId);
    final likeRef = spotRef.collection('likes').doc(user.uid);

    return StreamBuilder<DocumentSnapshot>(
      stream: spotRef.snapshots(),
      builder: (context, spotSnapshot) {
        final latestData =
            spotSnapshot.data?.data() as Map<String, dynamic>? ?? data;
        final likes = SpotLikeService.getLikeCount(latestData);

        return StreamBuilder<DocumentSnapshot>(
          stream: likeRef.snapshots(),
          builder: (context, likeSnapshot) {
            final isLiked = likeSnapshot.data?.exists ?? false;
            return GestureDetector(
              onTap: () async {
                final didLike = await SpotLikeService.toggleLike(
                  spotId: docId,
                  userId: user.uid,
                );
                final spotOwnerId = latestData['userId'] as String? ?? '';
                if (didLike &&
                    spotOwnerId.isNotEmpty &&
                    spotOwnerId != user.uid) {
                  await NotificationService.notifyLike(
                    spotOwnerId: spotOwnerId,
                    likerName: user.displayName ?? 'Pemancing',
                    spotName: latestData['name'] ?? 'Spot Mancing',
                    spotId: docId,
                    spotData: latestData,
                  );
                }
              },
              child: Row(
                children: [
                  Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                    color: isLiked ? Colors.red : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$likes',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSaveButton(Map<String, dynamic> data, String docId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_spots')
          .doc(docId)
          .snapshots(),
      builder: (context, snapshot) {
        final isSaved = snapshot.data?.exists ?? false;
        return GestureDetector(
          onTap: () async {
            final ref = FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('saved_spots')
                .doc(docId);
            if (isSaved) {
              await ref.delete();
            } else {
              await ref.set({
                'spotId': docId,
                'savedAt': Timestamp.now(),
                'spotName': data['name'] ?? '',
                'imageUrl': data['imageUrl'] ?? '',
                'kategori': data['kategoriPerairan'] ?? '',
                'targetIkan': data['targetIkan'] ?? [],
              });
            }
          },
          child: Row(
            children: [
              Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                size: 20,
                color: isSaved ? const Color(0xFF1B5E20) : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                isSaved ? 'Tersimpan' : 'Simpan',
                style: TextStyle(
                  fontSize: 13,
                  color: isSaved ? const Color(0xFF1B5E20) : Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF1B5E20),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _UnreadNotificationBadge extends StatefulWidget {
  final String? userId;

  const _UnreadNotificationBadge({required this.userId});

  @override
  State<_UnreadNotificationBadge> createState() =>
      _UnreadNotificationBadgeState();
}

class _UnreadNotificationBadgeState extends State<_UnreadNotificationBadge> {
  int? _lastUnread;

  @override
  Widget build(BuildContext context) {
    final userId = widget.userId;
    if (userId == null) {
      return const Icon(Icons.notifications_outlined, color: Colors.white);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final unread = snapshot.data?.docs.length ?? 0;
        if (_lastUnread != null && unread > _lastUnread!) {
          SystemSound.play(SystemSoundType.alert);
        }
        _lastUnread = unread;

        return Badge(
          isLabelVisible: unread > 0,
          label: Text('$unread'),
          backgroundColor: Colors.red,
          child: const Icon(Icons.notifications_outlined, color: Colors.white),
        );
      },
    );
  }
}
