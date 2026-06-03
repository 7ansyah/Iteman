import 'package:cloud_firestore/cloud_firestore.dart';

class SpotModel {
  final String id;
  final String name;
  final String description;
  final String kategoriPerairan;
  final String jenisAir;
  final String kondisiDasar;
  final String kedalaman;
  final String arus;
  final List<String> targetIkan;
  final String waktuTerbaik;
  final String teknikUmpan;
  final String fasilitas;
  final String biaya;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final Timestamp createdAt;
  final int likes;
  final int views;

  SpotModel({
    required this.id,
    required this.name,
    required this.description,
    required this.kategoriPerairan,
    required this.jenisAir,
    required this.kondisiDasar,
    required this.kedalaman,
    required this.arus,
    required this.targetIkan,
    required this.waktuTerbaik,
    required this.teknikUmpan,
    required this.fasilitas,
    required this.biaya,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.createdAt,
    required this.likes,
    required this.views,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'kategoriPerairan': kategoriPerairan,
      'jenisAir': jenisAir,
      'kondisiDasar': kondisiDasar,
      'kedalaman': kedalaman,
      'arus': arus,
      'targetIkan': targetIkan,
      'waktuTerbaik': waktuTerbaik,
      'teknikUmpan': teknikUmpan,
      'fasilitas': fasilitas,
      'biaya': biaya,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'createdAt': createdAt,
      'likes': likes,
      'total like': likes,
      'views': views,
    };
  }

  factory SpotModel.fromMap(Map<String, dynamic> map, String docId) {
    return SpotModel(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      kategoriPerairan: map['kategoriPerairan'] ?? '',
      jenisAir: map['jenisAir'] ?? '',
      kondisiDasar: map['kondisiDasar'] ?? '',
      kedalaman: map['kedalaman'] ?? '',
      arus: map['arus'] ?? '',
      targetIkan: List<String>.from(map['targetIkan'] ?? []),
      waktuTerbaik: map['waktuTerbaik'] ?? '',
      teknikUmpan: map['teknikUmpan'] ?? '',
      fasilitas: map['fasilitas'] ?? '',
      biaya: map['biaya'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhotoUrl: map['userPhotoUrl'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      likes: map['likes'] ?? map['total like'] ?? 0,
      views: map['views'] ?? 0,
    );
  }
}
