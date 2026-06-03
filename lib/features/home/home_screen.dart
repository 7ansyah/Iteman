import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../feed/screens/feed_screen.dart';
import '../map/screens/map_screen.dart';
import '../spots/screens/spots_screen.dart';
import '../search/screens/search_screen.dart';
import '../profile/screens/profile_screen.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../more/screens/more_menu_screen.dart';
import '../leaderboard/screens/leaderboard_screen.dart';
import '../communities/screens/communities_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  final List<Widget> _screens = [
    const FeedScreen(),
    const SearchScreen(),
    const MapScreen(),
    const SpotsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Konten utama
          Expanded(child: _screens[_currentIndex]),
          // Banner iklan tipis di atas navigation bar
          const BannerAdWidget(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF1B5E20).withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF1B5E20)),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search, color: Color(0xFF1B5E20)),
            label: 'Cari',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: Color(0xFF1B5E20)),
            label: 'Peta',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle, color: Color(0xFF1B5E20)),
            label: 'Tambah',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF1B5E20)),
            label: 'Profil',
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'communities_fab',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CommunitiesScreen()),
            ),
            backgroundColor: const Color(0xFF1565C0),
            child: const Icon(Icons.groups, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'leaderboard_fab',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
            ),
            backgroundColor: Colors.amber,
            child: const Icon(Icons.emoji_events, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'more_menu_fab',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MoreMenuScreen()),
            ),
            backgroundColor: const Color(0xFF1B5E20),
            child: const Icon(Icons.more_horiz, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
