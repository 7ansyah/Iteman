import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherService {
  static Future<Map<String, dynamic>?> getWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final uri = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$latitude'
        '&longitude=$longitude'
        '&current=temperature_2m,relative_humidity_2m,'
        'weather_code,wind_speed_10m,surface_pressure'
        '&timezone=Asia%2FJakarta'
        '&forecast_days=1',
      );

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current'] as Map<String, dynamic>;
        return {
          'temperature': current['temperature_2m'],
          'humidity': current['relative_humidity_2m'],
          'windSpeed': current['wind_speed_10m'],
          'pressure': current['surface_pressure'],
          'weatherCode': current['weather_code'],
          'description': _getDescription(current['weather_code'] as int),
          'emoji': _getEmoji(current['weather_code'] as int),
          'fishingAdvice': _getFishingAdvice(
            current['weather_code'] as int,
            current['surface_pressure'] as double,
          ),
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static String _getDescription(int code) {
    if (code == 0) return 'Cerah';
    if (code <= 3) return 'Berawan';
    if (code <= 49) return 'Berkabut';
    if (code <= 59) return 'Gerimis';
    if (code <= 69) return 'Hujan';
    if (code <= 79) return 'Salju';
    if (code <= 82) return 'Hujan Lebat';
    if (code <= 99) return 'Badai Petir';
    return 'Tidak Diketahui';
  }

  static String _getEmoji(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code <= 49) return '🌫️';
    if (code <= 59) return '🌦️';
    if (code <= 69) return '🌧️';
    if (code <= 79) return '❄️';
    if (code <= 82) return '⛈️';
    if (code <= 99) return '🌩️';
    return '🌡️';
  }

  static String _getFishingAdvice(int code, double pressure) {
    // Tekanan udara tinggi (>1013 hPa) = ikan aktif
    final highPressure = pressure > 1013;

    if (code == 0 && highPressure) {
      return '🎣 Kondisi SANGAT IDEAL untuk mancing! Ikan aktif bergerak.';
    } else if (code <= 3 && highPressure) {
      return '🎣 Kondisi BAIK untuk mancing. Coba teknik casting.';
    } else if (code <= 59) {
      return '🌦️ Gerimis ringan bagus untuk mancing — ikan naik ke permukaan!';
    } else if (code <= 69) {
      return '🌧️ Hujan lebat — sebaiknya tunggu reda. Waspadai banjir.';
    } else if (code >= 80) {
      return '⛈️ Cuaca buruk — tidak disarankan mancing. Keselamatan utama!';
    } else if (!highPressure) {
      return '📉 Tekanan udara rendah — ikan cenderung pasif. Pakai umpan wangi.';
    }
    return '🎣 Kondisi cukup untuk mancing. Pantau terus cuaca.';
  }
}
