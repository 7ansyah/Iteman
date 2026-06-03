import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../models/community_model.dart';
import '../../spots/screens/spot_detail_screen.dart';
import '../../../core/widgets/comment_thread.dart';
import '../../../core/services/notification_service.dart';

class CommunitiesScreen extends StatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _mode = 'semua';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text(
          'Komunitas Iteman',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.white),
            onPressed: () => _showCreateCommunitySheet(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) =>
                      setState(() => _query = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Cari nama komunitas atau wilayah...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  children: [
                    _buildModeChip('semua', 'Semua'),
                    _buildModeChip('komunitasku', 'Komunitasku'),
                    _buildModeChip('terverifikasi', 'Terverifikasi'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('communities')
            .orderBy('memberCount', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(context);
          }

          final items = snapshot.data!.docs
              .map(
                (doc) => CommunityModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .where((community) {
                final matchesQuery =
                    _query.isEmpty ||
                    community.name.toLowerCase().contains(_query) ||
                    community.region.toLowerCase().contains(_query) ||
                    community.basecamp.toLowerCase().contains(_query);
                final matchesMode =
                    _mode == 'semua' ||
                    (_mode == 'terverifikasi' && community.isVerified) ||
                    (_mode == 'komunitasku' && user != null);
                return matchesQuery && matchesMode;
              })
              .toList();

          if (_mode == 'komunitasku' && user != null) {
            return _buildMyCommunitiesList(items, user.uid);
          }

          if (items.isEmpty) return _buildEmptyState(context);

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                _buildCommunityCard(context, items[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCommunitySheet(context),
        backgroundColor: const Color(0xFF1B5E20),
        icon: const Icon(Icons.groups, color: Colors.white),
        label: const Text(
          'Buat Komunitas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildModeChip(String mode, String label) {
    final selected = _mode == mode;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _mode = mode),
        selectedColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        labelStyle: TextStyle(
          color: selected
              ? const Color(0xFF1B5E20)
              : const Color.fromARGB(255, 125, 125, 125),
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildMyCommunitiesList(List<CommunityModel> items, String userId) {
    return FutureBuilder<List<CommunityModel>>(
      future: _filterJoinedCommunities(items, userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
          );
        }

        final joined = snapshot.data ?? [];
        if (joined.isEmpty) return _buildEmptyState(context);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: joined.length,
          itemBuilder: (context, index) =>
              _buildCommunityCard(context, joined[index]),
        );
      },
    );
  }

  Future<List<CommunityModel>> _filterJoinedCommunities(
    List<CommunityModel> items,
    String userId,
  ) async {
    final joined = <CommunityModel>[];
    for (final community in items) {
      final memberDoc = await FirebaseFirestore.instance
          .collection('communities')
          .doc(community.id)
          .collection('members')
          .doc(userId)
          .get();
      if (memberDoc.exists) joined.add(community);
    }
    return joined;
  }

  Widget _buildCommunityCard(BuildContext context, CommunityModel community) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CommunityDetailScreen(community: community),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 94,
              decoration: BoxDecoration(
                color: const Color(0xFF1B5E20),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
                image: community.photoUrl.isNotEmpty
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(community.photoUrl),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.25),
                          BlendMode.darken,
                        ),
                      )
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: community.photoUrl.isNotEmpty
                          ? CachedNetworkImageProvider(community.photoUrl)
                          : null,
                      child: community.photoUrl.isEmpty
                          ? const Icon(
                              Icons.groups,
                              color: Color(0xFF1B5E20),
                              size: 30,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  community.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (community.isVerified)
                                const Icon(
                                  Icons.verified,
                                  color: Colors.lightBlueAccent,
                                  size: 18,
                                ),
                            ],
                          ),
                          Text(
                            community.region.isEmpty
                                ? 'Wilayah belum diisi'
                                : community.region,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (community.description.isNotEmpty)
                    Text(
                      community.description,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStat('${community.memberCount}', 'Anggota'),
                      _buildStat('${community.spotCount}', 'Spot'),
                      _buildStat('${community.eventCount}', 'Event'),
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

  Widget _buildStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.groups_3, size: 72, color: Color(0xFF1B5E20)),
            const SizedBox(height: 16),
            const Text(
              'Belum ada komunitas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Buat rumah untuk komunitas mancingmu dan ajak anggota bergabung di Iteman.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _showCreateCommunitySheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Buat Komunitas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCommunitySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _CreateCommunitySheet(),
    );
  }
}

class CommunityDetailScreen extends StatefulWidget {
  final CommunityModel community;

  const CommunityDetailScreen({super.key, required this.community});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isBusy = false;
  final _postController = TextEditingController();
  bool _isPosting = false;
  bool _isAnnouncementPost = false;
  late CommunityModel _community;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _community = widget.community;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('communities')
          .doc(_community.id)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        if (data != null) {
          _community = CommunityModel.fromMap(data, _community.id);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: const Color(0xFF1B5E20),
                iconTheme: const IconThemeData(color: Colors.white),
                title: Text(
                  _community.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [_buildOwnerEditAction(user)],
                flexibleSpace: FlexibleSpaceBar(background: _buildHeader()),
                bottom: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: 'Info'),
                    Tab(text: 'Feed'),
                    Tab(text: 'Agenda'),
                    Tab(text: 'Spot'),
                    Tab(text: 'Anggota'),
                  ],
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(user),
                _buildCommunityFeed(user),
                _buildCommunityAgenda(user),
                _buildCommunitySpots(),
                _buildMembersTab(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOwnerEditAction(User? user) {
    if (user == null || user.uid != _community.ownerId) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('communities')
          .doc(_community.id)
          .collection('members')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.data?.exists != true) return const SizedBox.shrink();
        return IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: _showEditCommunitySheet,
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        image: _community.photoUrl.isNotEmpty
            ? DecorationImage(
                image: CachedNetworkImageProvider(_community.photoUrl),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.35),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _community.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_community.isVerified)
                    const Icon(Icons.verified, color: Colors.lightBlueAccent),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _community.region.isEmpty
                    ? 'Wilayah belum diisi'
                    : _community.region,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTab(User? user) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildJoinPanel(user),
        if (user?.uid == _community.ownerId && !_community.isVerified)
          _buildOwnerVerificationSlot(user!),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: 'Tentang Komunitas',
          child: Text(
            _community.description.isEmpty
                ? 'Belum ada deskripsi komunitas.'
                : _community.description,
            style: const TextStyle(height: 1.5),
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: 'Basecamp',
          child: Text(
            _community.basecamp.isEmpty
                ? 'Basecamp belum diisi.'
                : _community.basecamp,
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: 'Aturan Komunitas',
          child: Text(
            _community.rules.isEmpty
                ? 'Belum ada aturan komunitas.'
                : _community.rules,
            style: const TextStyle(height: 1.5),
          ),
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: 'Aktivitas',
          child: _buildRealtimeActivityStats(),
        ),
      ],
    );
  }

  Widget _buildRealtimeActivityStats() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('communities')
          .doc(_community.id)
          .collection('members')
          .snapshots(),
      builder: (context, snapshot) {
        final memberCount =
            snapshot.data?.docs.length ?? _community.memberCount;
        return Row(
          children: [
            _activityStat('$memberCount', 'Anggota'),
            _activityStat('${_community.spotCount}', 'Spot'),
            _activityStat('${_community.eventCount}', 'Event'),
          ],
        );
      },
    );
  }

  Widget _buildOwnerVerificationSlot(User user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('communities')
          .doc(_community.id)
          .collection('members')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.data?.exists != true) return const SizedBox.shrink();
        return Column(
          children: [const SizedBox(height: 12), _buildVerificationPanel(user)],
        );
      },
    );
  }

  Widget _buildVerificationPanel(User user) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('community_verification_requests')
          .doc(_community.id)
          .snapshots(),
      builder: (context, snapshot) {
        final request = snapshot.data?.data();
        final status =
            request?['status']?.toString() ?? _community.verificationStatus;
        final isPending = status == 'pending';
        final isRejected = status == 'rejected';
        final reason = request?['reason']?.toString() ?? '';
        final title = isPending
            ? 'Verifikasi sedang ditinjau'
            : isRejected
            ? 'Verifikasi ditolak'
            : 'Ajukan verifikasi';
        final subtitle = isPending
            ? 'Permintaanmu sudah masuk. Admin Iteman dapat meninjau data komunitas ini.'
            : isRejected
            ? (reason.isEmpty
                  ? 'Perbarui data komunitas, lalu ajukan ulang.'
                  : 'Alasan: $reason')
            : 'Komunitas terverifikasi lebih mudah ditemukan dan tampil di filter Terverifikasi.';
        final color = isPending
            ? Colors.orange
            : isRejected
            ? Colors.red
            : const Color(0xFF1B5E20);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isPending
                ? const Color(0xFFFFF8E1)
                : isRejected
                ? const Color(0xFFFFEBEE)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: (isPending || isRejected)
                ? Border.all(color: color.withValues(alpha: 0.55))
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
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(
                  isPending
                      ? Icons.hourglass_top
                      : isRejected
                      ? Icons.error_outline
                      : Icons.verified_outlined,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: isPending || _isBusy
                    ? null
                    : () => _requestVerification(user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  isPending
                      ? 'Diajukan'
                      : isRejected
                      ? 'Ajukan Ulang'
                      : 'Ajukan',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _requestVerification(User user) async {
    final actualMemberCount = await _fetchMemberCount();
    final requirements = _verificationRequirements(
      memberCount: actualMemberCount,
    );
    final accepted = await _showVerificationRequirements(requirements);
    if (accepted != true) return;

    final missing = requirements
        .where((requirement) => !requirement.isMet)
        .toList();
    if (missing.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lengkapi dulu: ${missing.map((item) => item.title).join(', ')}',
          ),
        ),
      );
      return;
    }

    setState(() => _isBusy = true);
    final communityRef = FirebaseFirestore.instance
        .collection('communities')
        .doc(_community.id);
    final requestRef = FirebaseFirestore.instance
        .collection('community_verification_requests')
        .doc(_community.id);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(communityRef, {
          'verificationStatus': 'pending',
          'verificationRequestedAt': Timestamp.now(),
        });
        transaction.set(requestRef, {
          'communityId': _community.id,
          'communityName': _community.name,
          'ownerId': _community.ownerId,
          'ownerName': _community.ownerName,
          'requestedBy': user.uid,
          'status': 'pending',
          'region': _community.region,
          'basecamp': _community.basecamp,
          'description': _community.description,
          'rules': _community.rules,
          'photoUrl': _community.photoUrl,
          'memberCount': actualMemberCount,
          'spotCount': _community.spotCount,
          'eventCount': _community.eventCount,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'reason': '',
        }, SetOptions(merge: true));
      });
      if (!mounted) return;
      setState(() {
        _community = CommunityModel(
          id: _community.id,
          name: _community.name,
          description: _community.description,
          region: _community.region,
          basecamp: _community.basecamp,
          rules: _community.rules,
          photoUrl: _community.photoUrl,
          ownerId: _community.ownerId,
          ownerName: _community.ownerName,
          joinPolicy: _community.joinPolicy,
          memberCount: actualMemberCount,
          spotCount: _community.spotCount,
          eventCount: _community.eventCount,
          isVerified: _community.isVerified,
          verificationStatus: 'pending',
          createdAt: _community.createdAt,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengajuan verifikasi komunitas dikirim.'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengajukan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<int> _fetchMemberCount() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('communities')
        .doc(_community.id)
        .collection('members')
        .get();
    return snapshot.docs.length;
  }

  List<_VerificationRequirement> _verificationRequirements({
    required int memberCount,
  }) {
    return [
      _VerificationRequirement(
        title: 'Minimal 3 anggota',
        description:
            'Komunitas sebaiknya sudah punya beberapa anggota aktif, bukan hanya akun pembuat.',
        isMet: memberCount >= 3,
      ),
      _VerificationRequirement(
        title: 'Wilayah komunitas jelas',
        description:
            'Isi wilayah utama komunitas, misalnya Banyuasin atau Musi.',
        isMet: _community.region.trim().isNotEmpty,
      ),
      _VerificationRequirement(
        title: 'Basecamp atau titik kumpul jelas',
        description:
            'Isi alamat basecamp, titik kumpul, atau area kegiatan komunitas.',
        isMet: _community.basecamp.trim().isNotEmpty,
      ),
      _VerificationRequirement(
        title: 'Tentang komunitas terisi',
        description:
            'Tambahkan deskripsi singkat tentang komunitas, kegiatan, dan karakter anggotanya.',
        isMet: _community.description.trim().length >= 20,
      ),
      _VerificationRequirement(
        title: 'Aturan komunitas terisi',
        description:
            'Cantumkan aturan dasar agar komunitas lebih sehat dan mudah dimoderasi.',
        isMet: _community.rules.trim().length >= 10,
      ),
      _VerificationRequirement(
        title: 'Logo atau foto komunitas',
        description:
            'Tambahkan identitas visual supaya komunitas mudah dikenali.',
        isMet: _community.photoUrl.trim().isNotEmpty,
      ),
    ];
  }

  Future<bool?> _showVerificationRequirements(
    List<_VerificationRequirement> requirements,
  ) {
    final allMet = requirements.every((requirement) => requirement.isMet);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Syarat Verifikasi Komunitas'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Komunitas terverifikasi diprioritaskan untuk komunitas yang identitasnya jelas dan cukup aktif.',
              ),
              const SizedBox(height: 12),
              ...requirements.map(
                (requirement) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        requirement.isMet
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: requirement.isMet
                            ? const Color(0xFF1B5E20)
                            : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              requirement.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              requirement.description,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: allMet ? () => Navigator.pop(context, true) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
            ),
            child: Text(allMet ? 'Ajukan Sekarang' : 'Belum Lengkap'),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinPanel(User? user) {
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('communities')
          .doc(_community.id)
          .collection('members')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final isMember = snapshot.data?.exists ?? false;
        if (!isMember && _community.joinPolicy == 'approval') {
          return _buildJoinRequestPanel(user);
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  isMember
                      ? 'Kamu sudah menjadi anggota komunitas ini.'
                      : 'Gabung untuk membawa komunitasmu hidup di Iteman.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isBusy ? null : () => _toggleMembership(isMember),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isMember
                      ? Colors.grey
                      : const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                ),
                child: Text(isMember ? 'Keluar' : 'Gabung'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJoinRequestPanel(User user) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('communities')
          .doc(_community.id)
          .collection('join_requests')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final status = data?['status']?.toString();
        final isPending = status == 'pending';
        final isRejected = status == 'rejected';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  isPending
                      ? 'Pengajuan gabungmu sedang menunggu persetujuan.'
                      : isRejected
                      ? 'Pengajuan sebelumnya ditolak. Kamu bisa mengajukan ulang.'
                      : 'Komunitas ini membutuhkan persetujuan admin atau moderator.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: isPending || _isBusy
                    ? null
                    : () => _requestMembership(user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                ),
                child: Text(isPending ? 'Menunggu' : 'Ajukan'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _requestMembership(User user) async {
    setState(() => _isBusy = true);
    try {
      await FirebaseFirestore.instance
          .collection('communities')
          .doc(_community.id)
          .collection('join_requests')
          .doc(user.uid)
          .set({
            'userId': user.uid,
            'userName': user.displayName ?? 'Pemancing',
            'userPhotoUrl': user.photoURL ?? '',
            'status': 'pending',
            'requestedAt': Timestamp.now(),
            'reviewedAt': FieldValue.delete(),
            'reviewedBy': FieldValue.delete(),
            'reason': '',
          }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengajuan gabung dikirim.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengajukan gabung: $e')));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _toggleMembership(bool isMember) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isBusy = true);
    final communityRef = FirebaseFirestore.instance
        .collection('communities')
        .doc(_community.id);
    final memberRef = communityRef.collection('members').doc(user.uid);

    try {
      if (isMember) {
        final members = await communityRef.collection('members').get();
        final otherMembers = members.docs
            .where((doc) => doc.id != user.uid)
            .toList();
        final isLastMember = otherMembers.isEmpty;
        if (isLastMember) {
          final confirmDelete = await _confirmDeleteEmptyCommunity();
          if (confirmDelete != true) return;
          await _deleteCommunityTree();
          if (mounted) Navigator.pop(context);
          return;
        }

        if (user.uid == _community.ownerId) {
          final replacement = await _selectNewOwner(otherMembers);
          if (replacement == null) return;
          await _leaveAsOwnerWithReplacement(
            communityRef: communityRef,
            currentMemberRef: memberRef,
            replacement: replacement,
          );
          return;
        }
      }

      if (isMember) {
        await memberRef.delete();
        await _tryUpdateCommunityCounter(communityRef, 'memberCount', -1);
      } else {
        await memberRef.set({
          'userId': user.uid,
          'userName': user.displayName ?? 'Pemancing',
          'userPhotoUrl': user.photoURL ?? '',
          'role': 'member',
          'joinedAt': Timestamp.now(),
        });
        await _tryUpdateCommunityCounter(communityRef, 'memberCount', 1);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isMember
                ? 'Gagal keluar dari komunitas: $e'
                : 'Gagal gabung komunitas: $e',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _tryUpdateCommunityCounter(
    DocumentReference<Map<String, dynamic>> communityRef,
    String field,
    int delta,
  ) async {
    try {
      await communityRef.update({field: FieldValue.increment(delta)});
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
      debugPrint('$field update skipped by Firestore rules: $e');
    }
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _selectNewOwner(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> members,
  ) {
    return showDialog<QueryDocumentSnapshot<Map<String, dynamic>>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih admin pengganti'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kamu pemilik komunitas ini. Sebelum keluar, pilih anggota yang akan menjadi admin utama.',
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final data = member.data();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF1B5E20),
                        backgroundImage:
                            data['userPhotoUrl'] != null &&
                                data['userPhotoUrl'] != ''
                            ? NetworkImage(data['userPhotoUrl'])
                            : null,
                        child:
                            data['userPhotoUrl'] == null ||
                                data['userPhotoUrl'] == ''
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Text(data['userName'] ?? 'Pemancing'),
                      subtitle: Text(_roleLabel(data['role'])),
                      onTap: () => Navigator.pop(context, member),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveAsOwnerWithReplacement({
    required DocumentReference<Map<String, dynamic>> communityRef,
    required DocumentReference<Map<String, dynamic>> currentMemberRef,
    required QueryDocumentSnapshot<Map<String, dynamic>> replacement,
  }) async {
    final replacementData = replacement.data();
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.update(communityRef, {
        'ownerId': replacement.id,
        'ownerName': replacementData['userName'] ?? 'Pemancing',
        'memberCount': FieldValue.increment(-1),
      });
      transaction.update(replacement.reference, {'role': 'admin'});
      transaction.delete(currentMemberRef);
    });

    if (!mounted) return;
    setState(() {
      final nextCount = _community.memberCount > 0
          ? _community.memberCount - 1
          : 0;
      _community = CommunityModel(
        id: _community.id,
        name: _community.name,
        description: _community.description,
        region: _community.region,
        basecamp: _community.basecamp,
        rules: _community.rules,
        photoUrl: _community.photoUrl,
        ownerId: replacement.id,
        ownerName: replacementData['userName'] ?? 'Pemancing',
        joinPolicy: _community.joinPolicy,
        memberCount: nextCount,
        spotCount: _community.spotCount,
        eventCount: _community.eventCount,
        isVerified: _community.isVerified,
        verificationStatus: _community.verificationStatus,
        createdAt: _community.createdAt,
      );
    });
    Navigator.pop(context);
  }

  Future<bool?> _confirmDeleteEmptyCommunity() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus komunitas?'),
        content: Text(
          'Kamu adalah anggota terakhir di ${_community.name}. '
          'Jika kamu keluar, komunitas ini akan dihapus agar tidak menjadi komunitas kosong.',
        ),
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
            child: const Text('Keluar & Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCommunityTree() async {
    final communityRef = FirebaseFirestore.instance
        .collection('communities')
        .doc(_community.id);

    await _deleteSubcollection(communityRef.collection('members'));
    await _deleteSubcollection(communityRef.collection('events'));
    await _deletePostSubtree(communityRef.collection('posts'));
    await communityRef.delete();
  }

  Future<void> _deletePostSubtree(
    CollectionReference<Map<String, dynamic>> postsRef,
  ) async {
    final posts = await postsRef.get();
    for (final post in posts.docs) {
      await _deleteSubcollection(post.reference.collection('likes'));
      await _deleteSubcollection(post.reference.collection('comments'));
      await post.reference.delete();
    }
  }

  Future<void> _deleteSubcollection(
    CollectionReference<Map<String, dynamic>> ref,
  ) async {
    final snapshot = await ref.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  void _showEditCommunitySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _EditCommunitySheet(
        community: _community,
        onSaved: (updated) => setState(() => _community = updated),
      ),
    );
  }

  Widget _buildCommunitySpots() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('spots')
          .where('communityId', isEqualTo: _community.id)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Belum ada spot yang ditautkan ke komunitas ini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
              leading: ClipRRect(
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
                        child: const Icon(Icons.phishing),
                      ),
              ),
              title: Text(data['name'] ?? 'Spot Mancing'),
              subtitle: Text(data['kategoriPerairan'] ?? ''),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SpotDetailScreen(data: data, docId: doc.id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCommunityAgenda(User? user) {
    return Column(
      children: [
        if (user != null)
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('communities')
                .doc(_community.id)
                .collection('members')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              final isMember = snapshot.data?.exists == true;
              if (!isMember) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCreateAgendaSheet(user),
                    icon: const Icon(Icons.event_available),
                    label: const Text('Buat Agenda Komunitas'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('communities')
                .doc(_community.id)
                .collection('events')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Belum ada agenda. Buat jadwal mancing bareng, kopdar, atau lomba kecil komunitasmu.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildAgendaCard(doc.id, data, user);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAgendaCard(
    String eventId,
    Map<String, dynamic> data,
    User? user,
  ) {
    final canDelete = user?.uid == data['userId'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.event, color: Color(0xFF1B5E20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['title'] ?? 'Agenda Komunitas',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data['dateText'] ?? '',
                      style: const TextStyle(
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (canDelete)
                _buildAgendaActions(eventId)
              else
                _buildModeratorAgendaActions(eventId, user),
            ],
          ),
          const SizedBox(height: 10),
          if ((data['location'] ?? '').toString().isNotEmpty)
            _agendaLine(Icons.location_on, data['location']),
          if ((data['description'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(data['description'], style: const TextStyle(height: 1.45)),
          ],
          const SizedBox(height: 10),
          Text(
            'Dibuat oleh ${data['userName'] ?? 'Pemancing'}',
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaActions(String eventId) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'delete') _deleteAgenda(eventId);
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'delete', child: Text('Hapus')),
      ],
    );
  }

  Widget _buildModeratorAgendaActions(String eventId, User? user) {
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('communities')
          .doc(_community.id)
          .collection('members')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!_canModerate(snapshot.data?.data())) {
          return const SizedBox.shrink();
        }
        return _buildAgendaActions(eventId);
      },
    );
  }

  Widget _agendaLine(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.black87, fontSize: 13),
          ),
        ),
      ],
    );
  }

  void _showCreateAgendaSheet(User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) =>
          _CreateCommunityAgendaSheet(communityId: _community.id, user: user),
    );
  }

  Future<void> _deleteAgenda(String eventId) async {
    await FirebaseFirestore.instance
        .collection('communities')
        .doc(_community.id)
        .collection('events')
        .doc(eventId)
        .delete();
    await _tryUpdateCommunityCounter(
      FirebaseFirestore.instance.collection('communities').doc(_community.id),
      'eventCount',
      -1,
    );
  }

  Widget _buildCommunityFeed(User? user) {
    return Column(
      children: [
        if (user != null)
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('communities')
                .doc(_community.id)
                .collection('members')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              final isMember = snapshot.data?.exists == true;
              if (!isMember) {
                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Gabung komunitas untuk ikut posting di feed komunitas.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }
              return _buildPostComposer(user);
            },
          ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('communities')
                .doc(_community.id)
                .collection('posts')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Belum ada obrolan komunitas. Mulai dengan kabar, rencana mancing, atau hasil tangkapan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }

              final docs = [...snapshot.data!.docs];
              docs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aPinned = aData['isAnnouncement'] == true ? 1 : 0;
                final bPinned = bData['isAnnouncement'] == true ? 1 : 0;
                if (aPinned != bPinned) return bPinned.compareTo(aPinned);
                final aTime = aData['createdAt'] as Timestamp?;
                final bTime = bData['createdAt'] as Timestamp?;
                return (bTime?.millisecondsSinceEpoch ?? 0).compareTo(
                  aTime?.millisecondsSinceEpoch ?? 0,
                );
              });

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildCommunityPostCard(doc.id, data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPostComposer(User user) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _postController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Bagikan kabar komunitas...',
              filled: true,
              fillColor: const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (user.uid == _community.ownerId) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Jadikan pengumuman',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              subtitle: const Text(
                'Pengumuman tampil lebih menonjol di bagian atas feed.',
                style: TextStyle(fontSize: 11),
              ),
              value: _isAnnouncementPost,
              onChanged: (value) => setState(() => _isAnnouncementPost = value),
              activeThumbColor: const Color(0xFF1B5E20),
            ),
            const SizedBox(height: 4),
          ],
          Row(
            children: [
              const Icon(Icons.groups, size: 18, color: Color(0xFF1B5E20)),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Postingan terlihat oleh semua pengunjung komunitas.',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ),
              ElevatedButton(
                onPressed: _isPosting ? null : () => _submitCommunityPost(user),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                ),
                child: _isPosting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Posting'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitCommunityPost(User user) async {
    final text = _postController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPosting = true);
    try {
      await FirebaseFirestore.instance
          .collection('communities')
          .doc(_community.id)
          .collection('posts')
          .add({
            'text': text,
            'userId': user.uid,
            'userName': user.displayName ?? 'Pemancing',
            'userPhotoUrl': user.photoURL ?? '',
            'isAnnouncement': _isAnnouncementPost,
            'likeCount': 0,
            'commentCount': 0,
            'createdAt': Timestamp.now(),
          });
      _postController.clear();
      setState(() => _isAnnouncementPost = false);
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Widget _buildCommunityPostCard(String postId, Map<String, dynamic> data) {
    final user = FirebaseAuth.instance.currentUser;
    final createdAt = data['createdAt'] as Timestamp?;
    final isAnnouncement = data['isAnnouncement'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isAnnouncement ? const Color(0xFFFFF8E1) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isAnnouncement
            ? Border.all(color: Colors.amber.withValues(alpha: 0.8), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF1B5E20),
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      createdAt == null
                          ? 'Baru saja'
                          : '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}',
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (isAnnouncement)
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.campaign, size: 14, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        'Pengumuman',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              _buildPostActions(postId, data, user),
            ],
          ),
          const SizedBox(height: 10),
          Text(data['text'] ?? '', style: const TextStyle(height: 1.45)),
          const SizedBox(height: 10),
          Row(
            children: [
              _CommunityPostLikeButton(
                communityId: _community.id,
                postId: postId,
                likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
              ),
              const SizedBox(width: 18),
              InkWell(
                onTap: () => _showPostComments(postId, data),
                child: Row(
                  children: [
                    const Icon(
                      Icons.comment_outlined,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${data['commentCount'] ?? 0} Komentar',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostActions(
    String postId,
    Map<String, dynamic> data,
    User? user,
  ) {
    if (user == null) return const SizedBox.shrink();
    final canDelete = user.uid == data['userId'];
    if (canDelete) return _buildPostDeleteMenu(postId);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('communities')
          .doc(_community.id)
          .collection('members')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!_canModerate(snapshot.data?.data())) {
          return const SizedBox.shrink();
        }
        return _buildPostDeleteMenu(postId);
      },
    );
  }

  Widget _buildPostDeleteMenu(String postId) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'delete') _deleteCommunityPost(postId);
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'delete', child: Text('Hapus')),
      ],
    );
  }

  bool _canModerate(Object? memberData) {
    if (memberData is! Map<String, dynamic>) return false;
    final role = memberData['role'];
    return role == 'admin' || role == 'moderator';
  }

  bool _canAdmin(Object? memberData) {
    if (memberData is! Map<String, dynamic>) return false;
    return memberData['role'] == 'admin';
  }

  Future<void> _deleteCommunityPost(String postId) async {
    final postRef = FirebaseFirestore.instance
        .collection('communities')
        .doc(_community.id)
        .collection('posts')
        .doc(postId);
    await _deleteSubcollection(postRef.collection('likes'));
    await _deleteSubcollection(postRef.collection('comments'));
    await postRef.delete();
  }

  void _showPostComments(String postId, Map<String, dynamic> postData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CommunityPostCommentsSheet(
        communityId: _community.id,
        postId: postId,
        postOwnerId: postData['userId'] ?? '',
        communityOwnerId: _community.ownerId,
      ),
    );
  }

  Widget _buildMembersTab() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('Login untuk melihat anggota.'));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('communities')
          .doc(_community.id)
          .collection('members')
          .doc(currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final memberData = snapshot.data?.data();
        final canModerate =
            currentUser.uid == _community.ownerId || _canModerate(memberData);
        final canManageRoles =
            currentUser.uid == _community.ownerId || _canAdmin(memberData);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (canModerate) _buildJoinRequestsSection(currentUser),
            _buildMembersList(currentUser, canManageRoles),
          ],
        );
      },
    );
  }

  Widget _buildJoinRequestsSection(User currentUser) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('communities')
          .doc(_community.id)
          .collection('join_requests')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();

        return _buildInfoCard(
          title: 'Pengajuan Bergabung',
          child: Column(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1B5E20),
                  backgroundImage:
                      (data['userPhotoUrl'] ?? '').toString().isNotEmpty
                      ? NetworkImage(data['userPhotoUrl'])
                      : null,
                  child: (data['userPhotoUrl'] ?? '').toString().isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                title: Text(data['userName'] ?? 'Pemancing'),
                subtitle: const Text('Menunggu persetujuan'),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'Tolak',
                      onPressed: () =>
                          _reviewJoinRequest(doc.id, data, false, currentUser),
                      icon: const Icon(Icons.close, color: Colors.red),
                    ),
                    IconButton(
                      tooltip: 'Setujui',
                      onPressed: () =>
                          _reviewJoinRequest(doc.id, data, true, currentUser),
                      icon: const Icon(
                        Icons.check_circle,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildMembersList(User currentUser, bool canManageRoles) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('communities')
          .doc(_community.id)
          .collection('members')
          .orderBy('joinedAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('Belum ada anggota.'));
        }

        return _buildInfoCard(
          title: 'Anggota (${docs.length})',
          child: Column(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final isSelf = currentUser.uid == data['userId'];
              final isOwner = doc.id == _community.ownerId;
              final canRemove = canManageRoles && !isSelf && !isOwner;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF1B5E20),
                  backgroundImage:
                      data['userPhotoUrl'] != null && data['userPhotoUrl'] != ''
                      ? NetworkImage(data['userPhotoUrl'])
                      : null,
                  child:
                      data['userPhotoUrl'] == null || data['userPhotoUrl'] == ''
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                title: Text(data['userName'] ?? 'Pemancing'),
                subtitle: Text(_roleLabel(data['role'])),
                trailing: canRemove
                    ? PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'remove') {
                            _confirmRemoveMember(doc.id, data);
                          } else {
                            _updateMemberRole(doc.id, value);
                          }
                        },
                        itemBuilder: (context) => [
                          if (data['role'] != 'admin')
                            const PopupMenuItem(
                              value: 'admin',
                              child: Text('Jadikan admin'),
                            ),
                          if (data['role'] != 'moderator')
                            const PopupMenuItem(
                              value: 'moderator',
                              child: Text('Jadikan moderator'),
                            ),
                          if (data['role'] != 'member')
                            const PopupMenuItem(
                              value: 'member',
                              child: Text('Kembalikan jadi anggota'),
                            ),
                          const PopupMenuItem(
                            value: 'remove',
                            child: Text('Keluarkan anggota'),
                          ),
                        ],
                      )
                    : null,
              );
            }).toList(),
          ),
        );
      },
    );
  }

  String _roleLabel(dynamic role) {
    if (role == 'admin') return 'Admin';
    if (role == 'moderator') return 'Moderator';
    return 'Anggota';
  }

  Future<void> _reviewJoinRequest(
    String userId,
    Map<String, dynamic> requestData,
    bool approved,
    User reviewer,
  ) async {
    final communityRef = FirebaseFirestore.instance
        .collection('communities')
        .doc(_community.id);
    final requestRef = communityRef.collection('join_requests').doc(userId);
    final memberRef = communityRef.collection('members').doc(userId);

    try {
      final now = Timestamp.now();
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(requestRef, {
          'status': approved ? 'approved' : 'rejected',
          'reviewedAt': now,
          'reviewedBy': reviewer.uid,
          'reason': approved ? '' : 'Belum disetujui oleh pengurus komunitas.',
        });
        if (approved) {
          transaction.set(memberRef, {
            'userId': userId,
            'userName': requestData['userName'] ?? 'Pemancing',
            'userPhotoUrl': requestData['userPhotoUrl'] ?? '',
            'role': 'member',
            'joinedAt': now,
            'approvedBy': reviewer.uid,
          });
        }
      });

      if (approved) {
        await _tryUpdateCommunityCounter(communityRef, 'memberCount', 1);
      }

      await NotificationService.sendNotification(
        toUserId: userId,
        title: approved
            ? 'Pengajuan gabung disetujui'
            : 'Pengajuan gabung ditolak',
        body: approved
            ? 'Kamu sekarang menjadi anggota ${_community.name}.'
            : 'Pengajuan gabung ke ${_community.name} belum disetujui.',
        type: approved ? 'community_join_approved' : 'community_join_rejected',
        actorUserId: reviewer.uid,
        actorName: reviewer.displayName ?? 'Pengurus Komunitas',
        actorPhotoUrl: reviewer.photoURL ?? '',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memproses pengajuan: $e')));
    }
  }

  Future<void> _updateMemberRole(String memberId, String role) async {
    await FirebaseFirestore.instance
        .collection('communities')
        .doc(_community.id)
        .collection('members')
        .doc(memberId)
        .update({'role': role});
  }

  Future<void> _confirmRemoveMember(
    String memberId,
    Map<String, dynamic> memberData,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluarkan anggota?'),
        content: Text(
          'Keluarkan ${memberData['userName'] ?? 'anggota'} dari ${_community.name}?',
        ),
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
            child: const Text('Keluarkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await FirebaseFirestore.instance
        .collection('communities')
        .doc(_community.id)
        .collection('members')
        .doc(memberId)
        .delete();
    await _tryUpdateCommunityCounter(
      FirebaseFirestore.instance.collection('communities').doc(_community.id),
      'memberCount',
      -1,
    );

    setState(() {
      final nextCount = _community.memberCount > 0
          ? _community.memberCount - 1
          : 0;
      _community = CommunityModel(
        id: _community.id,
        name: _community.name,
        description: _community.description,
        region: _community.region,
        basecamp: _community.basecamp,
        rules: _community.rules,
        photoUrl: _community.photoUrl,
        ownerId: _community.ownerId,
        ownerName: _community.ownerName,
        joinPolicy: _community.joinPolicy,
        memberCount: nextCount,
        spotCount: _community.spotCount,
        eventCount: _community.eventCount,
        isVerified: _community.isVerified,
        verificationStatus: _community.verificationStatus,
        createdAt: _community.createdAt,
      );
    });
  }

  Widget _buildInfoCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _activityStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1B5E20),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class _CreateCommunitySheet extends StatefulWidget {
  const _CreateCommunitySheet();

  @override
  State<_CreateCommunitySheet> createState() => _CreateCommunitySheetState();
}

class _CreateCommunitySheetState extends State<_CreateCommunitySheet> {
  final _nameController = TextEditingController();
  final _regionController = TextEditingController();
  final _basecampController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _joinPolicy = 'open';
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _regionController.dispose();
    _basecampController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _nameController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final communityRef = FirebaseFirestore.instance
          .collection('communities')
          .doc();
      final data = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'region': _regionController.text.trim(),
        'basecamp': _basecampController.text.trim(),
        'photoUrl': '',
        'ownerId': user.uid,
        'ownerName': user.displayName ?? 'Pemancing',
        'joinPolicy': _joinPolicy,
        'memberCount': 1,
        'spotCount': 0,
        'eventCount': 0,
        'isVerified': false,
        'verificationStatus': 'none',
        'createdAt': Timestamp.now(),
      };
      await communityRef.set(data);
      await communityRef.collection('members').doc(user.uid).set({
        'userId': user.uid,
        'userName': user.displayName ?? 'Pemancing',
        'userPhotoUrl': user.photoURL ?? '',
        'role': 'admin',
        'joinedAt': Timestamp.now(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat komunitas: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              'Buat Komunitas',
              style: TextStyle(
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            _buildField(_nameController, 'Nama komunitas', required: true),
            const SizedBox(height: 12),
            _buildField(_regionController, 'Wilayah', hint: 'Contoh: Cirebon'),
            const SizedBox(height: 12),
            _buildField(
              _basecampController,
              'Basecamp',
              hint: 'Contoh: Kolam atau titik kumpul',
            ),
            const SizedBox(height: 12),
            _buildField(
              _descriptionController,
              'Deskripsi komunitas',
              maxLines: 4,
            ),
            const SizedBox(height: 18),
            _buildJoinPolicySelector(),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Buat Komunitas',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    String? hint,
    bool required = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
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

  Widget _buildJoinPolicySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cara Bergabung',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'open',
              icon: Icon(Icons.group_add),
              label: Text('Langsung'),
            ),
            ButtonSegment(
              value: 'approval',
              icon: Icon(Icons.verified_user),
              label: Text('Persetujuan'),
            ),
          ],
          selected: {_joinPolicy},
          onSelectionChanged: (values) =>
              setState(() => _joinPolicy = values.first),
        ),
        const SizedBox(height: 6),
        Text(
          _joinPolicy == 'open'
              ? 'Siapa saja bisa langsung menjadi anggota.'
              : 'Calon anggota harus disetujui admin atau moderator.',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}

class _VerificationRequirement {
  final String title;
  final String description;
  final bool isMet;

  const _VerificationRequirement({
    required this.title,
    required this.description,
    required this.isMet,
  });
}

class _CreateCommunityAgendaSheet extends StatefulWidget {
  final String communityId;
  final User user;

  const _CreateCommunityAgendaSheet({
    required this.communityId,
    required this.user,
  });

  @override
  State<_CreateCommunityAgendaSheet> createState() =>
      _CreateCommunityAgendaSheetState();
}

class _CreateCommunityAgendaSheetState
    extends State<_CreateCommunityAgendaSheet> {
  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('communities')
          .doc(widget.communityId)
          .collection('events')
          .add({
            'title': _titleController.text.trim(),
            'dateText': _dateController.text.trim(),
            'location': _locationController.text.trim(),
            'description': _descriptionController.text.trim(),
            'userId': widget.user.uid,
            'userName': widget.user.displayName ?? 'Pemancing',
            'createdAt': Timestamp.now(),
          });
      try {
        await FirebaseFirestore.instance
            .collection('communities')
            .doc(widget.communityId)
            .update({'eventCount': FieldValue.increment(1)});
      } on FirebaseException catch (e) {
        if (e.code != 'permission-denied') rethrow;
        debugPrint('eventCount update skipped by Firestore rules: $e');
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              'Buat Agenda Komunitas',
              style: TextStyle(
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            _field(_titleController, 'Judul agenda *'),
            const SizedBox(height: 12),
            _field(
              _dateController,
              'Tanggal / waktu',
              hint: 'Contoh: Minggu, 7 Juli 2026 jam 06.00',
            ),
            const SizedBox(height: 12),
            _field(
              _locationController,
              'Lokasi',
              hint: 'Contoh: Spot Sungai Musi / Basecamp',
            ),
            const SizedBox(height: 12),
            _field(
              _descriptionController,
              'Catatan agenda',
              maxLines: 4,
              hint: 'Info iuran, perlengkapan, titik kumpul, dll.',
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Simpan Agenda',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    int maxLines = 1,
  }) {
    return TextField(
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
}

class _EditCommunitySheet extends StatefulWidget {
  final CommunityModel community;
  final ValueChanged<CommunityModel> onSaved;

  const _EditCommunitySheet({required this.community, required this.onSaved});

  @override
  State<_EditCommunitySheet> createState() => _EditCommunitySheetState();
}

class _EditCommunitySheetState extends State<_EditCommunitySheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _regionController;
  late final TextEditingController _basecampController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _rulesController;
  late String _joinPolicy;
  File? _imageFile;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.community.name);
    _regionController = TextEditingController(text: widget.community.region);
    _basecampController = TextEditingController(
      text: widget.community.basecamp,
    );
    _descriptionController = TextEditingController(
      text: widget.community.description,
    );
    _rulesController = TextEditingController(text: widget.community.rules);
    _joinPolicy = widget.community.joinPolicy;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _regionController.dispose();
    _basecampController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
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
    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
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

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);
    try {
      var photoUrl = widget.community.photoUrl;
      if (_imageFile != null) {
        photoUrl = await _uploadImage(_imageFile!);
      }

      final updateData = {
        'name': _nameController.text.trim(),
        'region': _regionController.text.trim(),
        'basecamp': _basecampController.text.trim(),
        'description': _descriptionController.text.trim(),
        'rules': _rulesController.text.trim(),
        'photoUrl': photoUrl,
        'joinPolicy': _joinPolicy,
        'updatedAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('communities')
          .doc(widget.community.id)
          .update(updateData);

      widget.onSaved(
        CommunityModel(
          id: widget.community.id,
          name: updateData['name'] as String,
          description: updateData['description'] as String,
          region: updateData['region'] as String,
          basecamp: updateData['basecamp'] as String,
          rules: updateData['rules'] as String,
          photoUrl: photoUrl,
          ownerId: widget.community.ownerId,
          ownerName: widget.community.ownerName,
          joinPolicy: updateData['joinPolicy'] as String,
          memberCount: widget.community.memberCount,
          spotCount: widget.community.spotCount,
          eventCount: widget.community.eventCount,
          isVerified: widget.community.isVerified,
          verificationStatus: widget.community.verificationStatus,
          createdAt: widget.community.createdAt,
        ),
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              'Edit Komunitas',
              style: TextStyle(
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF1B5E20)),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : widget.community.photoUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: CachedNetworkImage(
                          imageUrl: widget.community.photoUrl,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            color: Color(0xFF1B5E20),
                            size: 38,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tambah logo/foto komunitas',
                            style: TextStyle(color: Color(0xFF1B5E20)),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 14),
            _field(_nameController, 'Nama komunitas *'),
            const SizedBox(height: 12),
            _field(_regionController, 'Wilayah'),
            const SizedBox(height: 12),
            _field(_basecampController, 'Basecamp'),
            const SizedBox(height: 12),
            _field(_descriptionController, 'Tentang komunitas', maxLines: 4),
            const SizedBox(height: 12),
            _field(_rulesController, 'Aturan komunitas', maxLines: 4),
            const SizedBox(height: 18),
            _buildJoinPolicySelector(),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Simpan Perubahan',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
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

  Widget _buildJoinPolicySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cara Bergabung',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'open',
              icon: Icon(Icons.group_add),
              label: Text('Langsung'),
            ),
            ButtonSegment(
              value: 'approval',
              icon: Icon(Icons.verified_user),
              label: Text('Persetujuan'),
            ),
          ],
          selected: {_joinPolicy},
          onSelectionChanged: (values) =>
              setState(() => _joinPolicy = values.first),
        ),
        const SizedBox(height: 6),
        Text(
          _joinPolicy == 'open'
              ? 'Siapa saja bisa langsung menjadi anggota.'
              : 'Calon anggota harus disetujui admin atau moderator.',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }
}

class _CommunityPostLikeButton extends StatelessWidget {
  final String communityId;
  final String postId;
  final int likeCount;

  const _CommunityPostLikeButton({
    required this.communityId,
    required this.postId,
    required this.likeCount,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Row(
        children: [
          const Icon(Icons.favorite_border, size: 18, color: Colors.grey),
          const SizedBox(width: 4),
          Text('$likeCount', style: const TextStyle(color: Colors.grey)),
        ],
      );
    }

    final postRef = FirebaseFirestore.instance
        .collection('communities')
        .doc(communityId)
        .collection('posts')
        .doc(postId);
    final likeRef = postRef.collection('likes').doc(user.uid);

    return StreamBuilder<DocumentSnapshot>(
      stream: likeRef.snapshots(),
      builder: (context, snapshot) {
        final liked = snapshot.data?.exists ?? false;
        return InkWell(
          onTap: () async {
            await FirebaseFirestore.instance.runTransaction((
              transaction,
            ) async {
              final postSnap = await transaction.get(postRef);
              final current =
                  (postSnap.data()?['likeCount'] as num?)?.toInt() ?? 0;
              final likeSnap = await transaction.get(likeRef);
              if (likeSnap.exists) {
                transaction.delete(likeRef);
                transaction.update(postRef, {
                  'likeCount': current > 0 ? current - 1 : 0,
                });
              } else {
                transaction.set(likeRef, {
                  'userId': user.uid,
                  'likedAt': Timestamp.now(),
                });
                transaction.update(postRef, {'likeCount': current + 1});
              }
            });
          },
          child: Row(
            children: [
              Icon(
                liked ? Icons.favorite : Icons.favorite_border,
                size: 18,
                color: liked ? Colors.red : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                '$likeCount',
                style: TextStyle(color: liked ? Colors.red : Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CommunityPostCommentsSheet extends StatelessWidget {
  final String communityId;
  final String postId;
  final String postOwnerId;
  final String communityOwnerId;

  const _CommunityPostCommentsSheet({
    required this.communityId,
    required this.postId,
    required this.postOwnerId,
    required this.communityOwnerId,
  });

  @override
  Widget build(BuildContext context) {
    final postRef = FirebaseFirestore.instance
        .collection('communities')
        .doc(communityId)
        .collection('posts')
        .doc(postId);
    final user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.68,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              'Komentar Komunitas',
              style: TextStyle(
                color: Color(0xFF1B5E20),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildCommentThread(postRef, user)),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentThread(
    DocumentReference<Map<String, dynamic>> postRef,
    User? user,
  ) {
    if (user == null) return _thread(postRef, canModerateAll: false);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('communities')
          .doc(communityId)
          .collection('members')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final role = data is Map<String, dynamic> ? data['role'] : null;
        final canModerateAll =
            user.uid == communityOwnerId ||
            role == 'admin' ||
            role == 'moderator';
        return _thread(postRef, canModerateAll: canModerateAll);
      },
    );
  }

  Widget _thread(
    DocumentReference<Map<String, dynamic>> postRef, {
    required bool canModerateAll,
  }) {
    return SingleChildScrollView(
      child: CommentThread(
        commentsRef: postRef.collection('comments'),
        ownerUserId: postOwnerId,
        accentColor: const Color(0xFF1B5E20),
        canModerateAll: canModerateAll,
        onCommentAdded: (_) async {
          await postRef.update({'commentCount': FieldValue.increment(1)});
        },
      ),
    );
  }
}
