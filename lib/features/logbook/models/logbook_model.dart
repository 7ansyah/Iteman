import 'package:cloud_firestore/cloud_firestore.dart';

class LogbookModel {
  final String id;
  final String userId;
  final String spotName;
  final String tanggal;
  final String cuaca;
  final String kondisiAir;
  final String teknik;
  final String umpan;
  final List<Map<String, dynamic>> tangkapan;
  final String catatan;
  final String imageUrl;
  final Timestamp createdAt;
  final double? latitude;
  final double? longitude;

  LogbookModel({
    required this.id,
    required this.userId,
    required this.spotName,
    required this.tanggal,
    required this.cuaca,
    required this.kondisiAir,
    required this.teknik,
    required this.umpan,
    required this.tangkapan,
    required this.catatan,
    required this.imageUrl,
    required this.createdAt,
    this.latitude,
    this.longitude,
  });

  factory LogbookModel.fromMap(Map<String, dynamic> map, String docId) {
    return LogbookModel(
      id: docId,
      userId: map['userId'] ?? '',
      spotName: map['spotName'] ?? '',
      tanggal: map['tanggal'] ?? '',
      cuaca: map['cuaca'] ?? '',
      kondisiAir: map['kondisiAir'] ?? '',
      teknik: map['teknik'] ?? '',
      umpan: map['umpan'] ?? '',
      tangkapan: List<Map<String, dynamic>>.from(map['tangkapan'] ?? []),
      catatan: map['catatan'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      createdAt: map['createdAt'] ?? Timestamp.now(),
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'spotName': spotName,
      'tanggal': tanggal,
      'cuaca': cuaca,
      'kondisiAir': kondisiAir,
      'teknik': teknik,
      'umpan': umpan,
      'tangkapan': tangkapan,
      'catatan': catatan,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  int get totalTangkapan =>
      tangkapan.fold(0, (total, t) => total + ((t['jumlah'] as int?) ?? 0));
}
