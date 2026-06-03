import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/screens/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'emoji': '🗺️',
      'title': 'Temukan Spot Terbaik',
      'subtitle':
          'Ribuan spot mancing tersebar di seluruh Indonesia.\nTemukan yang terdekat dari lokasimu.',
      'color1': const Color(0xFF1B5E20),
      'color2': const Color(0xFF4CAF50),
    },
    {
      'emoji': '📍',
      'title': 'Bagikan Spot Favoritmu',
      'subtitle':
          'Jadilah yang pertama membagikan spot rahasia.\nBantu sesama pemancing menemukan spot terbaik.',
      'color1': const Color(0xFF1565C0),
      'color2': const Color(0xFF1E88E5),
    },
    {
      'emoji': '👥',
      'title': 'Komunitas Pemancing',
      'subtitle':
          'Ajak teman mancing bareng, catat hasil tangkapan,\ndan bagikan pengalamanmu bersama komunitas.',
      'color1': const Color(0xFF6A1B9A),
      'color2': const Color(0xFF9C27B0),
    },
    {
      'emoji': '🎣',
      'title': 'Siap Mancing!',
      'subtitle':
          'Bergabung dengan komunitas pemancing Indonesia.\nMulai petualangan mancingmu sekarang!',
      'color1': const Color(0xFFE65100),
      'color2': const Color(0xFFFF9800),
    },
  ];

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Pages
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              final page = _pages[index];
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [page['color1'], page['color2']],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),

                        // Logo di halaman pertama
                        if (index == 0) ...[
                          Image.asset(
                            'assets/images/logo_header.png',
                            width: 200,
                            height: 60,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 32),
                        ],

                        // Emoji ilustrasi
                        if (index > 0)
                          Text(
                            page['emoji'],
                            style: const TextStyle(fontSize: 100),
                          ),

                        const SizedBox(height: 32),

                        // Judul
                        Text(
                          page['title'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Subtitle
                        Text(
                          page['subtitle'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                            height: 1.6,
                          ),
                        ),

                        const Spacer(flex: 3),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(32, 20, 32, 40),
              child: Column(
                children: [
                  // Dots indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? Colors.white
                              : Colors.white38,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol
                  Row(
                    children: [
                      // Skip
                      if (_currentPage < _pages.length - 1)
                        TextButton(
                          onPressed: _finishOnboarding,
                          child: const Text(
                            'Lewati',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      const Spacer(),

                      // Next / Mulai
                      ElevatedButton(
                        onPressed: () {
                          if (_currentPage < _pages.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _finishOnboarding();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor:
                              _pages[_currentPage]['color1'] as Color,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _currentPage < _pages.length - 1
                              ? 'Selanjutnya →'
                              : 'Mulai Sekarang! 🎣',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
