import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final String judul;
  final String deskripsi;
  final String lokasi;
  final String tanggalMulai;
  final String tanggalSelesai;
  final String jamMulai;
  final String hadiah;
  final String biayaDaftar;
  final int maxPeserta;
  final List<String> pesertaIds;
  final String kategori;
  final String imageUrl;
  final Timestamp createdAt;
  final double? latitude;
  final double? longitude;

  EventModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhotoUrl,
    required this.judul,
    required this.deskripsi,
    required this.lokasi,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.jamMulai,
    required this.hadiah,
    required this.biayaDaftar,
    required this.maxPeserta,
    required this.pesertaIds,
    required this.kategori,
    required this.imageUrl,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  factory EventModel.fromMap(Map<String, dynamic> map, String docId) {
    return EventModel(
      id: docId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhotoUrl: map['userPhotoUrl'] ?? '',
      judul: map['judul'] ?? '',
      deskripsi: map['deskripsi'] ?? '',
      lokasi: map['lokasi'] ?? '',
      tanggalMulai: map['tanggalMulai'] ?? '',
      tanggalSelesai: map['tanggalSelesai'] ?? '',
      jamMulai: map['jamMulai'] ?? '',
      hadiah: map['hadiah'] ?? '',
      biayaDaftar: map['biayaDaftar'] ?? 'Gratis',
      maxPeserta: map['maxPeserta'] ?? 50,
      pesertaIds: List<String>.from(map['pesertaIds'] ?? []),
      kategori: map['kategori'] ?? 'Lomba Mancing',
      imageUrl: map['imageUrl'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }
}
