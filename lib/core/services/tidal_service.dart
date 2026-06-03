import 'dart:math';
// Import Color untuk digunakan di service
import 'package:flutter/material.dart' show Color, Colors;

class TidalService {
  // Fase bulan berdasarkan tanggal
  static Map<String, dynamic> getMoonPhase([DateTime? date]) {
    final now = date ?? DateTime.now();

    // Algoritma fase bulan (berdasarkan siklus 29.53 hari)
    final referenceNewMoon = DateTime(2000, 1, 6);
    final daysSince = now.difference(referenceNewMoon).inDays.toDouble();
    final cyclePosition = (daysSince % 29.53) / 29.53;

    String phase;
    String emoji;
    String fishingEffect;
    double illumination;

    if (cyclePosition < 0.0625) {
      phase = 'Bulan Baru';
      emoji = '🌑';
      illumination = 0;
      fishingEffect =
          'Malam gelap — ikan aktif di permukaan! Waktu terbaik mancing malam.';
    } else if (cyclePosition < 0.1875) {
      phase = 'Bulan Sabit Awal';
      emoji = '🌒';
      illumination = cyclePosition * 4 * 100;
      fishingEffect =
          'Pasang mulai naik — ikan mulai aktif bergerak ke pinggir.';
    } else if (cyclePosition < 0.3125) {
      phase = 'Bulan Separuh Awal';
      emoji = '🌓';
      illumination = 50;
      fishingEffect = 'Kondisi cukup baik — ikan aktif di area dangkal.';
    } else if (cyclePosition < 0.4375) {
      phase = 'Bulan Cembung Awal';
      emoji = '🌔';
      illumination = 75;
      fishingEffect =
          'Mendekati purnama — aktivitas ikan meningkat signifikan!';
    } else if (cyclePosition < 0.5625) {
      phase = 'Bulan Purnama';
      emoji = '🌕';
      illumination = 100;
      fishingEffect =
          '🌟 PURNAMA! Pasang tertinggi — ikan sangat aktif! Waktu TERBAIK mancing.';
    } else if (cyclePosition < 0.6875) {
      phase = 'Bulan Cembung Akhir';
      emoji = '🌖';
      illumination = 75;
      fishingEffect = 'Pasca purnama — ikan masih cukup aktif, terutama subuh.';
    } else if (cyclePosition < 0.8125) {
      phase = 'Bulan Separuh Akhir';
      emoji = '🌗';
      illumination = 50;
      fishingEffect = 'Aktivitas ikan mulai menurun — fokus ke spot dalam.';
    } else if (cyclePosition < 0.9375) {
      phase = 'Bulan Sabit Akhir';
      emoji = '🌘';
      illumination = 25;
      fishingEffect =
          'Menjelang bulan baru — ikan mulai bergerak ke perairan dalam.';
    } else {
      phase = 'Bulan Baru';
      emoji = '🌑';
      illumination = 0;
      fishingEffect =
          'Malam gelap — ikan aktif di permukaan! Waktu terbaik mancing malam.';
    }

    // Hitung hari ke bulan baru berikutnya
    final daysToNext = ((1 - cyclePosition) * 29.53).round();
    final daysToFull = cyclePosition < 0.5
        ? ((0.5 - cyclePosition) * 29.53).round()
        : 0;

    return {
      'phase': phase,
      'emoji': emoji,
      'illumination': illumination.round(),
      'fishingEffect': fishingEffect,
      'daysToNextNew': daysToNext,
      'daysToFull': daysToFull,
      'cyclePosition': cyclePosition,
      'isFavorable': cyclePosition >= 0.4 && cyclePosition <= 0.6,
    };
  }

  // Prediksi pasang surut sederhana berdasarkan fase bulan
  static List<Map<String, dynamic>> getTidalPrediction({
    required double latitude,
    required double longitude,
    DateTime? date,
  }) {
    final now = date ?? DateTime.now();
    final moonPhase = getMoonPhase(now);
    final cyclePosition = moonPhase['cyclePosition'] as double;

    // Amplitudo pasang berdasarkan fase bulan
    final amplitude = sin(cyclePosition * 2 * pi).abs();
    final isSpringTide =
        cyclePosition < 0.1 || (cyclePosition > 0.45 && cyclePosition < 0.55);

    final tides = <Map<String, dynamic>>[];

    // Generate 4 pasang surut untuk hari ini
    for (int i = 0; i < 4; i++) {
      final hour = (i * 6 + 3) % 24;
      final isHighTide = i % 2 == 0;
      final height = isHighTide
          ? (1.5 + amplitude * 0.8).toStringAsFixed(1)
          : (0.3 + amplitude * 0.2).toStringAsFixed(1);

      tides.add({
        'time':
            '${hour.toString().padLeft(2, '0')}:${(i * 17 % 60).toString().padLeft(2, '0')}',
        'type': isHighTide ? 'Pasang' : 'Surut',
        'height': '$height m',
        'emoji': isHighTide ? '⬆️' : '⬇️',
        'fishingQuality': isHighTide
            ? (isSpringTide ? 'Sangat Baik' : 'Baik')
            : 'Cukup',
        'color': isHighTide
            ? (isSpringTide ? const Color(0xFF1B5E20) : const Color(0xFF4CAF50))
            : Colors.orange,
      });
    }

    return tides;
  }
}
