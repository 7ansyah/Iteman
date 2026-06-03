import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../spots/screens/spot_detail_screen.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../../../core/services/spot_like_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text(
          '🏆 Papan Peringkat',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Spot Terpanas'),
            Tab(text: 'Pemancing Aktif'),
            Tab(text: 'Tangkapan Terbesar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHotSpotsTab(),
          _buildTopAnglerTab(),
          _buildBigCatchTab(),
        ],
      ),
    );
  }

  Widget _buildHotSpotsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('spots')
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmpty('Belum ada spot yang dinilai');
        }

        final docs = [...snapshot.data!.docs];
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          return SpotLikeService.getLikeCount(
            bData,
          ).compareTo(SpotLikeService.getLikeCount(aData));
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            final likes = SpotLikeService.getLikeCount(data);
            final views = data['views'] as int? ?? 0;
            final hotScore = likes * 2 + views;

            return _buildSpotRankCard(
              context: context,
              rank: index + 1,
              data: data,
              docId: docId,
              score: hotScore,
              scoreLabel: '🔥 $hotScore poin',
              subLabel: '❤️ $likes • 👁️ $views',
            );
          },
        );
      },
    );
  }

  Widget _buildTopAnglerTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .orderBy('totalSpots', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmpty('Belum ada pemancing terdaftar');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final data =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final userId = snapshot.data!.docs[index].id;

            return _buildUserRankCard(
              context: context,
              rank: index + 1,
              data: data,
              userId: userId,
            );
          },
        );
      },
    );
  }

  Widget _buildBigCatchTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('logbook').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmpty('Belum ada tangkapan yang dicatat di Log Book');
        }

        // Kumpulkan semua tangkapan & cari terberat
        final allCatches = <Map<String, dynamic>>[];
        for (final doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final tangkapan = (data['tangkapan'] as List? ?? []);
          for (final t in tangkapan) {
            final berat = _parseBerat(t['berat']);
            if (berat > 0) {
              allCatches.add({
                'namaIkan': t['namaIkan'] ?? '',
                'berat': berat,
                'jumlah': t['jumlah'] ?? 1,
                'spotName': data['spotName'] ?? '',
                'userId': data['userId'] ?? '',
                'tanggal': data['tanggal'] ?? '',
                'imageUrl': data['imageUrl'] ?? '',
              });
            }
          }
        }

        // Sort by berat
        allCatches.sort(
          (a, b) => (b['berat'] as double).compareTo(a['berat'] as double),
        );

        if (allCatches.isEmpty) {
          return _buildEmpty('Belum ada data berat tangkapan di Log Book');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allCatches.take(20).length,
          itemBuilder: (context, index) {
            final catch_ = allCatches[index];
            return _buildCatchRankCard(rank: index + 1, catch_: catch_);
          },
        );
      },
    );
  }

  double _parseBerat(dynamic value) {
    if (value is num) return value.toDouble();
    final text = value?.toString().trim().replaceAll(',', '.') ?? '';
    return double.tryParse(text) ?? 0;
  }

  Widget _buildSpotRankCard({
    required BuildContext context,
    required int rank,
    required Map<String, dynamic> data,
    required String docId,
    required int score,
    required String scoreLabel,
    required String subLabel,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SpotDetailScreen(data: data, docId: docId),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: rank <= 3
              ? Border.all(
                  color: _getRankColor(rank).withValues(alpha: 0.5),
                  width: 2,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 40,
              child: Center(
                child: rank <= 3
                    ? Text(
                        _getRankEmoji(rank),
                        style: const TextStyle(fontSize: 24),
                      )
                    : Text(
                        '#$rank',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),

            // Foto
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: data['imageUrl'] != null && data['imageUrl'] != ''
                  ? CachedNetworkImage(
                      imageUrl: data['imageUrl'],
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.phishing,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? 'Spot Mancing',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    data['kategoriPerairan'] ?? '',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    subLabel,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),

            // Score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _getRankColor(rank).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                scoreLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: _getRankColor(rank),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserRankCard({
    required BuildContext context,
    required int rank,
    required Map<String, dynamic> data,
    required String userId,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserProfileScreen(
            userId: userId,
            userName: data['name'] ?? 'Pemancing',
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: rank <= 3
              ? Border.all(
                  color: _getRankColor(rank).withValues(alpha: 0.5),
                  width: 2,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          children: [
            // Rank
            SizedBox(
              width: 40,
              child: Center(
                child: rank <= 3
                    ? Text(
                        _getRankEmoji(rank),
                        style: const TextStyle(fontSize: 24),
                      )
                    : Text(
                        '#$rank',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600],
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 10),

            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF1B5E20),
              backgroundImage:
                  data['photoUrl'] != null && data['photoUrl'] != ''
                  ? NetworkImage(data['photoUrl'])
                  : null,
              child: data['photoUrl'] == null || data['photoUrl'] == ''
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? 'Pemancing',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (data['lokasi'] != null && data['lokasi'] != '')
                    Text(
                      '📍 ${data['lokasi']}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
            ),

            // Total spot
            Column(
              children: [
                Text(
                  '${data['totalSpots'] ?? 0}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _getRankColor(rank),
                  ),
                ),
                const Text(
                  'spot',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatchRankCard({
    required int rank,
    required Map<String, dynamic> catch_,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: rank <= 3
            ? Border.all(
                color: _getRankColor(rank).withValues(alpha: 0.5),
                width: 2,
              )
            : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Center(
              child: rank <= 3
                  ? Text(
                      _getRankEmoji(rank),
                      style: const TextStyle(fontSize: 24),
                    )
                  : Text(
                      '#$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),

          const Text('🐟', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  catch_['namaIkan'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '📍 ${catch_['spotName']}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '📅 ${catch_['tanggal']}',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),

          Column(
            children: [
              Text(
                '${catch_['berat']} kg',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getRankColor(rank),
                ),
              ),
              Text(
                '${catch_['jumlah']} ekor',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🏆', style: TextStyle(fontSize: 60)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return const Color(0xFF1B5E20);
    }
  }

  String _getRankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '#$rank';
    }
  }
}
