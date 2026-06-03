import 'package:cloud_firestore/cloud_firestore.dart';

class MancingBarengModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String spotName;
  final String deskripsi;
  final String tanggal;
  final String jam;
  final String lokasi;
  final int maxPeserta;
  final List<String> pesertaIds;
  final Timestamp createdAt;
  final double? latitude;
  final double? longitude;

  MancingBarengModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.spotName,
    required this.deskripsi,
    required this.tanggal,
    required this.jam,
    required this.lokasi,
    required this.maxPeserta,
    required this.pesertaIds,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  factory MancingBarengModel.fromMap(Map<String, dynamic> map, String docId) {
    return MancingBarengModel(
      id: docId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhotoUrl: map['userPhotoUrl'] ?? '',
      spotName: map['spotName'] ?? '',
      deskripsi: map['deskripsi'] ?? '',
      tanggal: map['tanggal'] ?? '',
      jam: map['jam'] ?? '',
      lokasi: map['lokasi'] ?? '',
      maxPeserta: map['maxPeserta'] ?? 5,
      pesertaIds: List<String>.from(map['pesertaIds'] ?? []),
      createdAt: map['createdAt'] ?? Timestamp.now(),
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'spotName': spotName,
      'deskripsi': deskripsi,
      'tanggal': tanggal,
      'jam': jam,
      'lokasi': lokasi,
      'maxPeserta': maxPeserta,
      'pesertaIds': pesertaIds,
      'createdAt': createdAt,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
