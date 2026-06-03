import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CommentThread extends StatefulWidget {
  final CollectionReference<Map<String, dynamic>> commentsRef;
  final String ownerUserId;
  final Color accentColor;
  final bool darkMode;
  final bool canModerateAll;
  final Future<void> Function(Map<String, dynamic> commentData)? onCommentAdded;

  const CommentThread({
    super.key,
    required this.commentsRef,
    required this.ownerUserId,
    this.accentColor = const Color(0xFF1B5E20),
    this.darkMode = false,
    this.canModerateAll = false,
    this.onCommentAdded,
  });

  @override
  State<CommentThread> createState() => _CommentThreadState();
}

class _CommentThreadState extends State<CommentThread> {
  final _controller = TextEditingController();
  DocumentSnapshot<Map<String, dynamic>>? _replyTo;
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final user = FirebaseAuth.instance.currentUser;
    final text = _controller.text.trim();
    if (user == null || text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final replyData = _replyTo?.data();
      final commentData = {
        'userId': user.uid,
        'userName': user.displayName ?? 'Pemancing',
        'userPhotoUrl': user.photoURL ?? '',
        'text': text,
        'parentId': _replyTo?.id,
        'replyToName': replyData?['userName'],
        'isHidden': false,
        'createdAt': Timestamp.now(),
      };
      await widget.commentsRef.add(commentData);
      await widget.onCommentAdded?.call(commentData);
      _controller.clear();
      setState(() => _replyTo = null);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_replyTo != null) _buildReplyBanner(),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                style: TextStyle(
                  color: widget.darkMode ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: _replyTo == null
                      ? 'Tulis komentar...'
                      : 'Balas ${_replyTo!.data()?['userName'] ?? 'komentar'}...',
                  hintStyle: TextStyle(
                    color: widget.darkMode ? Colors.white38 : Colors.grey,
                  ),
                  filled: true,
                  fillColor: widget.darkMode
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFF5F5F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _isSending
                ? CircularProgressIndicator(color: widget.accentColor)
                : IconButton(
                    onPressed: _sendComment,
                    icon: Icon(Icons.send, color: widget.accentColor),
                  ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: widget.commentsRef
              .orderBy('createdAt', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Text(
                'Belum ada komentar. Jadilah yang pertama!',
                style: TextStyle(
                  color: widget.darkMode ? Colors.white54 : Colors.grey,
                ),
              );
            }

            final docs = snapshot.data!.docs;
            final topLevel = docs
                .where((doc) => (doc.data()['parentId'] ?? '') == '')
                .toList();
            if (topLevel.isEmpty) {
              return Text(
                'Belum ada komentar utama.',
                style: TextStyle(
                  color: widget.darkMode ? Colors.white54 : Colors.grey,
                ),
              );
            }

            return Column(
              children: topLevel
                  .map((doc) => _buildCommentWithReplies(doc, docs))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReplyBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Membalas ${_replyTo!.data()?['userName'] ?? 'komentar'}',
              style: TextStyle(
                color: widget.darkMode ? Colors.white : widget.accentColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _replyTo = null),
            child: Icon(
              Icons.close,
              size: 18,
              color: widget.darkMode ? Colors.white70 : widget.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentWithReplies(
    DocumentSnapshot<Map<String, dynamic>> doc,
    List<DocumentSnapshot<Map<String, dynamic>>> allDocs,
  ) {
    final replies = allDocs
        .where((reply) => reply.data()?['parentId'] == doc.id)
        .toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          _buildCommentTile(doc),
          if (replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 42, top: 8),
              child: Column(children: replies.map(_buildCommentTile).toList()),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final user = FirebaseAuth.instance.currentUser;
    final isOwner = user?.uid == widget.ownerUserId || widget.canModerateAll;
    final isAuthor = user?.uid == data['userId'];
    final isHidden = data['isHidden'] == true;
    final textColor = widget.darkMode ? Colors.white : Colors.black87;

    if (isHidden && !isOwner && !isAuthor) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Komentar disembunyikan',
          style: TextStyle(
            color: widget.darkMode ? Colors.white38 : Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: widget.accentColor,
          backgroundImage:
              data['userPhotoUrl'] != null && data['userPhotoUrl'] != ''
              ? NetworkImage(data['userPhotoUrl'])
              : null,
          child: data['userPhotoUrl'] == null || data['userPhotoUrl'] == ''
              ? const Icon(Icons.person, color: Colors.white, size: 18)
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data['userName'] ?? 'Pemancing',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_horiz,
                      size: 18,
                      color: widget.darkMode ? Colors.white70 : Colors.grey,
                    ),
                    onSelected: (value) => _handleCommentAction(value, doc),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'reply', child: Text('Balas')),
                      if (isOwner && !isHidden)
                        const PopupMenuItem(
                          value: 'hide',
                          child: Text('Sembunyikan'),
                        ),
                      if (isOwner && isHidden)
                        const PopupMenuItem(
                          value: 'show',
                          child: Text('Tampilkan lagi'),
                        ),
                      if (isOwner || isAuthor)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Hapus'),
                        ),
                    ],
                  ),
                ],
              ),
              if (data['replyToName'] != null)
                Text(
                  'Membalas ${data['replyToName']}',
                  style: TextStyle(color: widget.accentColor, fontSize: 11),
                ),
              Text(
                data['text'] ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: isHidden
                      ? (widget.darkMode ? Colors.white38 : Colors.grey)
                      : textColor,
                  fontStyle: isHidden ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleCommentAction(
    String value,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    if (value == 'reply') {
      setState(() => _replyTo = doc);
    } else if (value == 'hide') {
      await doc.reference.update({'isHidden': true});
    } else if (value == 'show') {
      await doc.reference.update({'isHidden': false});
    } else if (value == 'delete') {
      await doc.reference.delete();
    }
  }
}
