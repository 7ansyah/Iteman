import 'package:cloud_firestore/cloud_firestore.dart';

class LapakModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String userPhone;
  final String judul;
  final String deskripsi;
  final String harga;
  final String kategori;
  final String kondisi;
  final String imageUrl;
  final String wilayah;
  final double? latitude;
  final double? longitude;
  final bool isPremium;
  final bool isSold;
  final Timestamp createdAt;
  final Timestamp expiresAt;

  LapakModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.userPhone,
    required this.judul,
    required this.deskripsi,
    required this.harga,
    required this.kategori,
    required this.kondisi,
    required this.imageUrl,
    required this.wilayah,
    this.latitude,
    this.longitude,
    required this.isPremium,
    required this.isSold,
    required this.createdAt,
    required this.expiresAt,
  });

  factory LapakModel.fromMap(Map<String, dynamic> map, String docId) {
    return LapakModel(
      id: docId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhotoUrl: map['userPhotoUrl'] ?? '',
      userPhone: map['userPhone'] ?? '',
      judul: map['judul'] ?? '',
      deskripsi: map['deskripsi'] ?? '',
      harga: map['harga'] ?? '',
      kategori: map['kategori'] ?? '',
      kondisi: map['kondisi'] ?? 'Baru',
      imageUrl: map['imageUrl'] ?? '',
      wilayah: map['wilayah'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      isPremium: map['isPremium'] ?? false,
      isSold: map['isSold'] ?? false,
      createdAt: map['createdAt'] ?? Timestamp.now(),
      expiresAt: map['expiresAt'] ?? Timestamp.now(),
    );
  }
}
