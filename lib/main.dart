import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'firebase_options.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/home_screen.dart';
import 'features/onboarding/screens/onboarding_screen.dart';
import 'features/leaderboard/screens/leaderboard_screen.dart';
import 'features/logbook/screens/logbook_screen.dart';
import 'features/live_report/screens/live_report_screen.dart';
import 'features/event/screens/event_screen.dart';
import 'features/communities/screens/communities_screen.dart';
import 'features/admin/screens/admin_verification_screen.dart';
import 'core/services/admob_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AdmobService.initialize();
  timeago.setLocaleMessages('id', timeago.IdMessages());
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Cek apakah ini fresh install
  final prefs = await SharedPreferences.getInstance();
  final isInstalled = prefs.getBool('app_installed') ?? false;
  if (!isInstalled) {
    // Fresh install — bersihkan semua cache auth
    await FirebaseAuth.instance.signOut();
    await prefs.clear();
    await prefs.setBool('app_installed', true);
  }

  runApp(const ItemanApp());
}

class ItemanApp extends StatelessWidget {
  const ItemanApp({super.key});

  // Pindahkan ke static agar bisa dipanggil dari mana saja
  static Future<void> saveUserToFirestore(User user) async {
    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final doc = await userRef.get();
      if (!doc.exists) {
        await userRef.set({
          'uid': user.uid,
          'name': user.displayName ?? 'Pemancing',
          'email': user.email ?? '',
          'photoUrl': user.photoURL ?? '',
          'bio': '',
          'phone': '',
          'lokasi': '',
          'createdAt': Timestamp.now(),
          'totalSpots': 0,
          'totalLikes': 0,
        });
      } else {
        // Update foto & nama dari Google kalau belum diubah manual
        final data = doc.data() ?? {};
        if (data['photoUrl'] == '' || data['photoUrl'] == null) {
          await userRef.update({'photoUrl': user.photoURL ?? ''});
        }
      }
    } catch (e) {
      debugPrint('Error saving user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iteman',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/leaderboard': (context) => const LeaderboardScreen(),
        '/logbook': (context) => const LogbookScreen(),
        '/live_report': (context) => const LiveReportScreen(),
        '/event': (context) => const EventScreen(),
        '/communities': (context) => const CommunitiesScreen(),
        '/admin_verification': (context) => const AdminVerificationScreen(),
      },
    );
  }
}
