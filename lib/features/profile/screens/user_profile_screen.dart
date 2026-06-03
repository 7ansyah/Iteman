import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../spots/screens/spot_detail_screen.dart';
import '../../../core/services/notification_service.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isFollowing = false;
  bool _isLoadingFollow = false;
  int _followerCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _checkFollowStatus();
    _loadFollowCounts();
  }

  Future<void> _checkFollowStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('followers')
        .doc(currentUser.uid)
        .get();

    if (mounted) setState(() => _isFollowing = doc.exists);
  }

  Future<void> _loadFollowCounts() async {
    try {
      final followers = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('followers')
          .get();

      final following = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('following')
          .get();

      if (mounted) {
        setState(() {
          _followerCount = followers.docs.length;
          _followingCount = following.docs.length;
        });
      }
    } catch (e) {
      debugPrint('Follow count error: $e');
    }
  }

  Future<void> _toggleFollow() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    setState(() => _isLoadingFollow = true);

    try {
      final followerRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('followers')
          .doc(currentUser.uid);

      final followingRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('following')
          .doc(widget.userId);

      if (_isFollowing) {
        await followerRef.delete();
        await followingRef.delete();
        setState(() {
          _isFollowing = false;
          _followerCount = (_followerCount - 1).clamp(0, 999999);
        });
      } else {
        await followerRef.set({
          'userId': currentUser.uid,
          'userName': currentUser.displayName ?? '',
          'userPhotoUrl': currentUser.photoURL ?? '',
          'followedAt': Timestamp.now(),
        });
        await followingRef.set({
          'userId': widget.userId,
          'followedAt': Timestamp.now(),
        });
        setState(() {
          _isFollowing = true;
          _followerCount++;
        });

        // Kirim notifikasi
        await NotificationService.notifyFollow(
          followedUserId: widget.userId,
          followerId: currentUser.uid,
          followerName: currentUser.displayName ?? 'Pemancing',
          followerPhotoUrl: currentUser.photoURL ?? '',
        );
      }
    } catch (e) {
      debugPrint('Follow error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingFollow = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isOwnProfile = currentUser?.uid == widget.userId;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            );
          }

          final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: const Color(0xFF1B5E20),
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              userData['photoUrl'] != null &&
                                  userData['photoUrl'] != ''
                              ? NetworkImage(userData['photoUrl'])
                              : null,
                          child:
                              userData['photoUrl'] == null ||
                                  userData['photoUrl'] == ''
                              ? const Icon(
                                  Icons.person,
                                  size: 45,
                                  color: Color(0xFF1B5E20),
                                )
                              : null,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          userData['name'] ?? widget.userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          userData['email'] ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // Stats & Follow
                    // Ganti bagian stats di build method
                    FutureBuilder<Map<String, dynamic>>(
                      future: _getProfileStats(),
                      builder: (context, snapshot) {
                        final totalSpots = snapshot.data?['totalSpots'] ?? 0;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  _buildStat('$totalSpots', 'Spot'),
                                  _buildDivider(),
                                  _buildStat('$_followerCount', 'Follower'),
                                  _buildDivider(),
                                  _buildStat('$_followingCount', 'Following'),
                                ],
                              ),
                              if (!isOwnProfile) ...[
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: _isLoadingFollow
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF1B5E20),
                                          ),
                                        )
                                      : ElevatedButton.icon(
                                          onPressed: _toggleFollow,
                                          icon: Icon(
                                            _isFollowing
                                                ? Icons.person_remove
                                                : Icons.person_add,
                                          ),
                                          label: Text(
                                            _isFollowing
                                                ? 'Unfollow'
                                                : 'Follow Pemancing Ini',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _isFollowing
                                                ? Colors.grey
                                                : const Color(0xFF1B5E20),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Spot milik user ini
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              '📍 Spot dari ${userData['name'] ?? widget.userName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('spots')
                                .where('userId', isEqualTo: widget.userId)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Center(
                                    child: Text(
                                      'Belum ada spot yang dibagikan',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                );
                              }

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      childAspectRatio: 1,
                                    ),
                                itemCount: snapshot.data!.docs.length,
                                itemBuilder: (context, index) {
                                  final data =
                                      snapshot.data!.docs[index].data()
                                          as Map<String, dynamic>;
                                  final docId = snapshot.data!.docs[index].id;
                                  return GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SpotDetailScreen(
                                          data: data,
                                          docId: docId,
                                        ),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          data['imageUrl'] != null &&
                                                  data['imageUrl'] != ''
                                              ? CachedNetworkImage(
                                                  imageUrl: data['imageUrl'],
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  color: const Color(
                                                    0xFF1B5E20,
                                                  ).withValues(alpha: 0.1),
                                                  child: const Icon(
                                                    Icons.phishing,
                                                    color: Color(0xFF1B5E20),
                                                  ),
                                                ),
                                          // Overlay nama spot
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.black.withValues(
                                                      alpha: 0.7,
                                                    ),
                                                  ],
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                ),
                                              ),
                                              child: Text(
                                                data['name'] ?? '',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          );
        },
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
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getProfileStats() async {
    try {
      final spotsSnap = await FirebaseFirestore.instance
          .collection('spots')
          .where('userId', isEqualTo: widget.userId)
          .get();

      return {'totalSpots': spotsSnap.docs.length};
    } catch (e) {
      return {'totalSpots': 0};
    }
  }

  Widget _buildDivider() {
    return Container(height: 36, width: 1, color: Colors.grey[200]);
  }
}
