import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static Future<void> sendNotification({
    required String toUserId,
    required String title,
    required String body,
    required String type,
    String? spotId,
    Map<String, dynamic>? spotData,
    String? actorUserId,
    String? actorName,
    String? actorPhotoUrl,
  }) async {
    // Jangan kirim notif ke diri sendiri
    await FirebaseFirestore.instance
        .collection('users')
        .doc(toUserId)
        .collection('notifications')
        .add({
          'title': title,
          'body': body,
          'type': type,
          'spotId': spotId,
          'spotData': spotData,
          'actorUserId': actorUserId,
          'actorName': actorName,
          'actorPhotoUrl': actorPhotoUrl,
          'isRead': false,
          'createdAt': Timestamp.now(),
        });
  }

  static Future<void> notifyLike({
    required String spotOwnerId,
    required String likerName,
    required String spotName,
    required String spotId,
    required Map<String, dynamic> spotData,
  }) async {
    await sendNotification(
      toUserId: spotOwnerId,
      title: '❤️ Spot kamu disukai!',
      body: '$likerName menyukai spot "$spotName"',
      type: 'like',
      spotId: spotId,
      spotData: spotData,
    );
  }

  static Future<void> notifyComment({
    required String spotOwnerId,
    required String commenterName,
    required String spotName,
    required String spotId,
    required Map<String, dynamic> spotData,
  }) async {
    await sendNotification(
      toUserId: spotOwnerId,
      title: '💬 Komentar baru!',
      body: '$commenterName berkomentar di spot "$spotName"',
      type: 'comment',
      spotId: spotId,
      spotData: spotData,
    );
  }

  static Future<void> notifyFollow({
    required String followedUserId,
    required String followerId,
    required String followerName,
    String followerPhotoUrl = '',
  }) async {
    await sendNotification(
      toUserId: followedUserId,
      title: '👥 Follower baru!',
      body: '$followerName mulai mengikutimu',
      type: 'follow',
      actorUserId: followerId,
      actorName: followerName,
      actorPhotoUrl: followerPhotoUrl,
    );
  }

  static Future<void> notifyMancingBareng({
    required String toUserId,
    required String organizerName,
    required String spotName,
    required String tanggal,
  }) async {
    await sendNotification(
      toUserId: toUserId,
      title: '🎣 Ajakan Mancing Bareng!',
      body: '$organizerName mengajak mancing di $spotName pada $tanggal',
      type: 'mancing_bareng',
    );
  }
}
