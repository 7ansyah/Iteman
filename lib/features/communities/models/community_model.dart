import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityModel {
  final String id;
  final String name;
  final String description;
  final String region;
  final String basecamp;
  final String rules;
  final String photoUrl;
  final String ownerId;
  final String ownerName;
  final String joinPolicy;
  final int memberCount;
  final int spotCount;
  final int eventCount;
  final bool isVerified;
  final String verificationStatus;
  final Timestamp createdAt;

  const CommunityModel({
    required this.id,
    required this.name,
    required this.description,
    required this.region,
    required this.basecamp,
    required this.rules,
    required this.photoUrl,
    required this.ownerId,
    required this.ownerName,
    required this.joinPolicy,
    required this.memberCount,
    required this.spotCount,
    required this.eventCount,
    required this.isVerified,
    required this.verificationStatus,
    required this.createdAt,
  });

  factory CommunityModel.fromMap(Map<String, dynamic> map, String docId) {
    return CommunityModel(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      region: map['region'] ?? '',
      basecamp: map['basecamp'] ?? '',
      rules: map['rules'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      joinPolicy: map['joinPolicy'] ?? 'open',
      memberCount: (map['memberCount'] as num?)?.toInt() ?? 0,
      spotCount: (map['spotCount'] as num?)?.toInt() ?? 0,
      eventCount: (map['eventCount'] as num?)?.toInt() ?? 0,
      isVerified: map['isVerified'] == true,
      verificationStatus:
          map['verificationStatus'] ??
          (map['isVerified'] == true ? 'approved' : 'none'),
      createdAt: map['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'region': region,
      'basecamp': basecamp,
      'rules': rules,
      'photoUrl': photoUrl,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'joinPolicy': joinPolicy,
      'memberCount': memberCount,
      'spotCount': spotCount,
      'eventCount': eventCount,
      'isVerified': isVerified,
      'verificationStatus': verificationStatus,
      'createdAt': createdAt,
    };
  }
}
