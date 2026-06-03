import 'package:cloud_firestore/cloud_firestore.dart';

class SpotLikeService {
  static const String likesField = 'likes';
  static const String legacyTotalLikeField = 'total like';

  static int getLikeCount(Map<String, dynamic> data) {
    return (data[likesField] as num?)?.toInt() ??
        (data[legacyTotalLikeField] as num?)?.toInt() ??
        0;
  }

  static Future<bool> toggleLike({
    required String spotId,
    required String userId,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final spotRef = firestore.collection('spots').doc(spotId);
    final likeRef = spotRef.collection('likes').doc(userId);

    return firestore.runTransaction<bool>((transaction) async {
      final spotSnap = await transaction.get(spotRef);
      if (!spotSnap.exists) {
        throw StateError('Spot tidak ditemukan');
      }

      final likeSnap = await transaction.get(likeRef);
      final currentLikes = getLikeCount(spotSnap.data() ?? {});

      if (likeSnap.exists) {
        final nextLikes = currentLikes > 0 ? currentLikes - 1 : 0;
        transaction.delete(likeRef);
        transaction.update(spotRef, {
          likesField: nextLikes,
          legacyTotalLikeField: nextLikes,
        });
        return false;
      }

      transaction.set(likeRef, {'userId': userId, 'likedAt': Timestamp.now()});
      transaction.update(spotRef, {
        likesField: currentLikes + 1,
        legacyTotalLikeField: currentLikes + 1,
      });
      return true;
    });
  }
}
