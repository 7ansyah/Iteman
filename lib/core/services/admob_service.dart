import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdmobService {
  // Gunakan test ID saat development
  // Ganti dengan ID asli saat release
  static const String _bannerAdUnitId =
      'ca-app-pub-3940256099942544/6300978111'; // Test ID

  // ID asli — uncomment saat release:
  // static const String _bannerAdUnitId = 'ca-app-pub-XXXXXXXX/XXXXXXXX';

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  static BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    );
  }
}
