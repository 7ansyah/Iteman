import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/notification_service.dart';
import '../../communities/models/community_model.dart';
import '../../communities/screens/communities_screen.dart';

class AdminVerificationScreen extends StatefulWidget {
  const AdminVerificationScreen({super.key});

  @override
  State<AdminVerificationScreen> createState() =>
      _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen> {
  String _status = 'pending';
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _buildNoAccess('Kamu belum login.');

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};
        final isAdmin = data['isAdmin'] == true || data['role'] == 'admin';
        if (!isAdmin) {
          return _buildNoAccess('Halaman ini khusus admin Iteman.');
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: AppBar(
            backgroundColor: const Color(0xFF1B5E20),
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text(
              'Admin Verifikasi',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: Column(
            children: [
              _buildStatusTabs(),
              Expanded(child: _buildRequestsList(user)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoAccess(String message) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Admin Iteman',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTabs() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      color: Colors.white,
      child: Row(
        children: [
          _statusChip('pending', 'Menunggu'),
          const SizedBox(width: 8),
          _statusChip('approved', 'Disetujui'),
          const SizedBox(width: 8),
          _statusChip('rejected', 'Ditolak'),
        ],
      ),
    );
  }

  Widget _statusChip(String status, String label) {
    final selected = _status == status;
    return Expanded(
      child: ChoiceChip(
        label: Center(child: Text(label)),
        selected: selected,
        onSelected: (_) => setState(() => _status = status),
        showCheckmark: false,
        selectedColor: const Color(0xFF1B5E20),
        backgroundColor: const Color(0xFFF1F1F1),
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildRequestsList(User admin) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('community_verification_requests')
          .where('status', isEqualTo: _status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
          );
        }

        final docs = [...(snapshot.data?.docs ?? [])];
        docs.sort((a, b) {
          final aTime = a.data()['createdAt'] as Timestamp?;
          final bTime = b.data()['createdAt'] as Timestamp?;
          return (bTime?.millisecondsSinceEpoch ?? 0).compareTo(
            aTime?.millisecondsSinceEpoch ?? 0,
          );
        });

        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _status == 'pending'
                    ? 'Belum ada pengajuan verifikasi.'
                    : 'Belum ada data pada status ini.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return _buildRequestCard(doc.id, doc.data(), admin);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(
    String communityId,
    Map<String, dynamic> data,
    User admin,
  ) {
    final createdAt = data['createdAt'] as Timestamp?;
    final reviewedAt = data['reviewedAt'] as Timestamp?;
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
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFF1B5E20),
                child: Icon(Icons.groups, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['communityName'] ?? 'Komunitas',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      data['region'] ?? 'Wilayah belum diisi',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(data['status']),
            ],
          ),
          const SizedBox(height: 12),
          _line(Icons.person, 'Owner: ${data['ownerName'] ?? '-'}'),
          _line(Icons.location_on, 'Basecamp: ${data['basecamp'] ?? '-'}'),
          _buildMemberCountLine(communityId, data),
          if (createdAt != null)
            _line(Icons.schedule, 'Diajukan: ${_formatDate(createdAt)}'),
          if (reviewedAt != null)
            _line(Icons.fact_check, 'Direview: ${_formatDate(reviewedAt)}'),
          if ((data['reason'] ?? '').toString().isNotEmpty)
            _line(Icons.info_outline, 'Alasan: ${data['reason']}'),
          if (_status == 'pending') ...[
            const SizedBox(height: 10),
            _buildRealtimeChecklist(communityId, data),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openCommunity(communityId),
                  icon: const Icon(Icons.visibility),
                  label: const Text('Lihat'),
                ),
              ),
              if (_status == 'pending') ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isBusy
                        ? null
                        : () => _rejectRequest(communityId, admin),
                    icon: const Icon(Icons.close),
                    label: const Text('Tolak'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isBusy
                        ? null
                        : () => _approveRequest(communityId, admin),
                    icon: const Icon(Icons.verified),
                    label: const Text('Setujui'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B5E20),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCountLine(String communityId, Map<String, dynamic> data) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('communities')
          .doc(communityId)
          .collection('members')
          .snapshots(),
      builder: (context, snapshot) {
        final fallback = (data['memberCount'] as num?)?.toInt() ?? 0;
        final count = snapshot.data?.docs.length ?? fallback;
        return _line(Icons.group, 'Anggota: $count');
      },
    );
  }

  Widget _buildRealtimeChecklist(
    String communityId,
    Map<String, dynamic> data,
  ) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('communities')
          .doc(communityId)
          .collection('members')
          .snapshots(),
      builder: (context, snapshot) {
        final fallback = (data['memberCount'] as num?)?.toInt() ?? 0;
        final memberCount = snapshot.data?.docs.length ?? fallback;
        return _buildChecklist(
          _verificationChecksFromRequest(data, memberCount: memberCount),
        );
      },
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildChecklist(List<_AdminVerificationCheck> checks) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: checks
            .map(
              (check) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      check.isMet
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: check.isMet
                          ? const Color(0xFF1B5E20)
                          : Colors.orange,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        check.title,
                        style: TextStyle(
                          fontSize: 12,
                          color: check.isMet ? Colors.black87 : Colors.orange,
                          fontWeight: check.isMet
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildStatusBadge(dynamic status) {
    final value = (status ?? 'pending').toString();
    final color = value == 'approved'
        ? const Color(0xFF1B5E20)
        : value == 'rejected'
        ? Colors.red
        : Colors.orange;
    final label = value == 'approved'
        ? 'Disetujui'
        : value == 'rejected'
        ? 'Ditolak'
        : 'Menunggu';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _line(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _openCommunity(String communityId) async {
    final doc = await FirebaseFirestore.instance
        .collection('communities')
        .doc(communityId)
        .get();
    if (!mounted) return;
    if (!doc.exists || doc.data() == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Komunitas tidak ditemukan.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommunityDetailScreen(
          community: CommunityModel.fromMap(doc.data()!, doc.id),
        ),
      ),
    );
  }

  Future<void> _approveRequest(String communityId, User admin) async {
    final communityDoc = await FirebaseFirestore.instance
        .collection('communities')
        .doc(communityId)
        .get();
    if (!mounted) return;
    if (!communityDoc.exists || communityDoc.data() == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Komunitas tidak ditemukan.')),
      );
      return;
    }

    final community = CommunityModel.fromMap(
      communityDoc.data()!,
      communityDoc.id,
    );
    final actualMemberCount = await _fetchMemberCount(communityId);
    final checks = _adminVerificationChecks(
      community,
      memberCount: actualMemberCount,
    );
    final missing = checks.where((check) => !check.isMet).toList();
    final confirm = await _confirm(
      title: 'Setujui verifikasi?',
      message: missing.isEmpty
          ? 'Komunitas ini memenuhi syarat dasar dan akan tampil sebagai komunitas terverifikasi.'
          : 'Ada syarat yang belum lengkap: ${missing.map((item) => item.title).join(', ')}. Tetap setujui?',
      action: 'Setujui',
      color: const Color(0xFF1B5E20),
    );
    if (confirm != true) return;

    if (mounted) setState(() => _isBusy = true);
    try {
      final now = Timestamp.now();
      final communityRef = FirebaseFirestore.instance
          .collection('communities')
          .doc(communityId);
      final requestRef = FirebaseFirestore.instance
          .collection('community_verification_requests')
          .doc(communityId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(communityRef, {
          'isVerified': true,
          'verificationStatus': 'approved',
          'verifiedAt': now,
          'verifiedBy': admin.uid,
        });
        transaction.update(requestRef, {
          'status': 'approved',
          'reviewedAt': now,
          'reviewedBy': admin.uid,
          'reason': '',
        });
      });

      await NotificationService.sendNotification(
        toUserId: community.ownerId,
        title: 'Komunitas terverifikasi',
        body:
            '${community.name} sudah disetujui sebagai komunitas terverifikasi.',
        type: 'community_verification_approved',
        actorUserId: admin.uid,
        actorName: admin.displayName ?? 'Admin Iteman',
        actorPhotoUrl: admin.photoURL ?? '',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Komunitas berhasil diverifikasi.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyetujui verifikasi: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  List<_AdminVerificationCheck> _adminVerificationChecks(
    CommunityModel community, {
    required int memberCount,
  }) {
    return [
      _AdminVerificationCheck('Minimal 3 anggota', memberCount >= 3),
      _AdminVerificationCheck(
        'Wilayah jelas',
        community.region.trim().isNotEmpty,
      ),
      _AdminVerificationCheck(
        'Basecamp jelas',
        community.basecamp.trim().isNotEmpty,
      ),
      _AdminVerificationCheck(
        'Deskripsi cukup',
        community.description.trim().length >= 20,
      ),
      _AdminVerificationCheck(
        'Aturan komunitas terisi',
        community.rules.trim().length >= 10,
      ),
      _AdminVerificationCheck(
        'Logo/foto komunitas',
        community.photoUrl.trim().isNotEmpty,
      ),
    ];
  }

  List<_AdminVerificationCheck> _verificationChecksFromRequest(
    Map<String, dynamic> data, {
    int? memberCount,
  }) {
    return [
      _AdminVerificationCheck(
        'Minimal 3 anggota',
        (memberCount ?? (data['memberCount'] as num?)?.toInt() ?? 0) >= 3,
      ),
      _AdminVerificationCheck(
        'Wilayah jelas',
        (data['region'] ?? '').toString().trim().isNotEmpty,
      ),
      _AdminVerificationCheck(
        'Basecamp jelas',
        (data['basecamp'] ?? '').toString().trim().isNotEmpty,
      ),
      _AdminVerificationCheck(
        'Deskripsi cukup',
        (data['description'] ?? '').toString().trim().length >= 20,
      ),
      _AdminVerificationCheck(
        'Aturan komunitas terisi',
        (data['rules'] ?? '').toString().trim().length >= 10,
      ),
      _AdminVerificationCheck(
        'Logo/foto komunitas',
        (data['photoUrl'] ?? '').toString().trim().isNotEmpty,
      ),
    ];
  }

  Future<int> _fetchMemberCount(String communityId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('communities')
        .doc(communityId)
        .collection('members')
        .get();
    return snapshot.docs.length;
  }

  Future<void> _rejectRequest(String communityId, User admin) async {
    final reason = await _askRejectReason();
    if (reason == null) return;

    if (mounted) setState(() => _isBusy = true);
    try {
      final communityDoc = await FirebaseFirestore.instance
          .collection('communities')
          .doc(communityId)
          .get();
      final communityData = communityDoc.data();
      final now = Timestamp.now();
      final communityRef = FirebaseFirestore.instance
          .collection('communities')
          .doc(communityId);
      final requestRef = FirebaseFirestore.instance
          .collection('community_verification_requests')
          .doc(communityId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(communityRef, {
          'isVerified': false,
          'verificationStatus': 'rejected',
          'verifiedAt': FieldValue.delete(),
          'verifiedBy': FieldValue.delete(),
        });
        transaction.update(requestRef, {
          'status': 'rejected',
          'reviewedAt': now,
          'reviewedBy': admin.uid,
          'reason': reason,
        });
      });

      final ownerId = communityData?['ownerId']?.toString() ?? '';
      if (ownerId.isNotEmpty) {
        await NotificationService.sendNotification(
          toUserId: ownerId,
          title: 'Verifikasi komunitas ditolak',
          body:
              'Pengajuan ${communityData?['name'] ?? 'komunitas'} ditolak: $reason',
          type: 'community_verification_rejected',
          actorUserId: admin.uid,
          actorName: admin.displayName ?? 'Admin Iteman',
          actorPhotoUrl: admin.photoURL ?? '',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan verifikasi ditolak.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menolak verifikasi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    required String action,
    required Color color,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  Future<String?> _askRejectReason() async {
    return showDialog<String>(
      context: context,
      builder: (context) => const _RejectVerificationDialog(),
    );
  }
}

class _AdminVerificationCheck {
  final String title;
  final bool isMet;

  const _AdminVerificationCheck(this.title, this.isMet);
}

class _RejectVerificationDialog extends StatefulWidget {
  const _RejectVerificationDialog();

  @override
  State<_RejectVerificationDialog> createState() =>
      _RejectVerificationDialogState();
}

class _RejectVerificationDialogState extends State<_RejectVerificationDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tolak verifikasi'),
      content: TextField(
        controller: _controller,
        minLines: 2,
        maxLines: 4,
        decoration: const InputDecoration(
          labelText: 'Alasan penolakan',
          hintText: 'Contoh: data basecamp belum jelas',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            final reason = _controller.text.trim();
            Navigator.pop(
              context,
              reason.isEmpty ? 'Data komunitas belum lengkap.' : reason,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Tolak'),
        ),
      ],
    );
  }
}
