import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../../spots/screens/spot_detail_screen.dart';
import '../../../core/services/spot_like_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Circle> _heatCircles = {};
  bool _isLoading = true;
  MapType _currentMapType = MapType.hybrid;
  bool _showHeatmap = true;
  String _filterKategori = 'Semua';

  static const LatLng _defaultCenter = LatLng(-2.5489, 118.0149);

  final List<String> _kategoriList = [
    'Semua',
    'Rawa',
    'Danau/Waduk',
    'Kolam Pancing',
    'Sungai Kecil',
    'Sungai Besar',
    'Muara',
    'Tepi Pantai',
    'Laut Dalam',
    'Tambak',
  ];

  @override
  void initState() {
    super.initState();
    _loadSpots();
  }

  Future<void> _goToMyLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;
      final position = await Geolocator.getCurrentPosition();
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          14,
        ),
      );
    } catch (e) {
      // GPS tidak tersedia
    }
  }

  Future<void> _loadSpots() async {
    setState(() {
      _markers.clear();
      _heatCircles.clear();
      _isLoading = true;
    });

    try {
      Query query = FirebaseFirestore.instance.collection('spots');

      if (_filterKategori != 'Semua') {
        query = query.where('kategoriPerairan', isEqualTo: _filterKategori);
      }

      final snapshot = await query.get();
      final markers = <Marker>{};
      final circles = <Circle>{};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final lat = data['latitude'] as double?;
        final lng = data['longitude'] as double?;
        if (lat == null || lng == null) continue;

        final likes = SpotLikeService.getLikeCount(data);
        final views = data['views'] as int? ?? 0;
        final hotScore = likes * 2 + views;
        final status = data['status'] as String? ?? 'aktif';

        // Warna marker berdasarkan status & popularitas
        double markerHue;
        if (status == 'diragukan') {
          markerHue = BitmapDescriptor.hueOrange;
        } else if (hotScore > 20) {
          markerHue = BitmapDescriptor.hueRed;
        } else if (hotScore > 10) {
          markerHue = BitmapDescriptor.hueYellow;
        } else {
          markerHue = BitmapDescriptor.hueGreen;
        }

        markers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
            infoWindow: InfoWindow(
              title: data['name'] ?? 'Spot Mancing',
              snippet:
                  '${data['kategoriPerairan']} • ❤️$likes 👁️$views'
                  '${status == 'diragukan' ? ' ⚠️Diragukan' : ''}',
              onTap: () => _showSpotDetail(context, data, doc.id),
            ),
          ),
        );

        // Heatmap circle berdasarkan popularitas
        if (_showHeatmap && hotScore > 0) {
          circles.add(
            Circle(
              circleId: CircleId('heat_${doc.id}'),
              center: LatLng(lat, lng),
              radius: (50 + hotScore * 10).toDouble().clamp(50, 500),
              fillColor: _getHeatColor(hotScore),
              strokeWidth: 0,
            ),
          );
        }
      }

      setState(() {
        _markers.addAll(markers);
        _heatCircles.addAll(circles);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _getHeatColor(int score) {
    if (score > 30) {
      return Colors.red.withValues(alpha: 0.35);
    } else if (score > 20) {
      return Colors.orange.withValues(alpha: 0.3);
    } else if (score > 10) {
      return Colors.yellow.withValues(alpha: 0.25);
    } else {
      return Colors.green.withValues(alpha: 0.2);
    }
  }

  void _showSpotDetail(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (data['status'] == 'diragukan')
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange, size: 16),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '⚠️ Spot ini dilaporkan beberapa pengguna',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

            if (data['imageUrl'] != null && data['imageUrl'] != '')
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  data['imageUrl'],
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 12),

            Text(
              data['name'] ?? 'Spot Mancing',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildTag('🌊 ${data['kategoriPerairan'] ?? ''}'),
                _buildTag('💧 ${data['jenisAir'] ?? ''}'),
                _buildTag('⏰ ${data['waktuTerbaik'] ?? ''}'),
                _buildTag(
                  '❤️ ${SpotLikeService.getLikeCount(data)} • 👁️ ${data['views'] ?? 0}',
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (data['targetIkan'] != null)
              Text(
                '🐟 ${(data['targetIkan'] as List).join(', ')}',
                style: const TextStyle(fontSize: 14),
              ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SpotDetailScreen(data: data, docId: docId),
                    ),
                  );
                },
                icon: const Icon(Icons.info_outline),
                label: const Text('Lihat Detail Spot'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF1B5E20),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text(
          'Peta Spot Mancing',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location, color: Colors.white),
            onPressed: _goToMyLocation,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadSpots,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _kategoriList.length,
              itemBuilder: (context, index) {
                final k = _kategoriList[index];
                final isSelected = _filterKategori == k;
                return GestureDetector(
                  onTap: () {
                    setState(() => _filterKategori = k);
                    _loadSpots();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      k,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? const Color(0xFF1B5E20)
                            : Colors.white,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _defaultCenter,
              zoom: 5,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              _goToMyLocation();
            },
            markers: _markers,
            circles: _heatCircles,
            mapType: _currentMapType,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
          ),

          if (_isLoading)
            Container(
              color: Colors.white.withValues(alpha: 0.7),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
              ),
            ),

          // Legenda heatmap
          if (_showHeatmap)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tingkat Kepanasan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildLegendItem(Colors.red, 'Sangat Panas (30+)'),
                    _buildLegendItem(Colors.orange, 'Panas (20+)'),
                    _buildLegendItem(Colors.yellow, 'Hangat (10+)'),
                    _buildLegendItem(Colors.green, 'Normal'),
                  ],
                ),
              ),
            ),

          // Controls kanan bawah
          Positioned(
            bottom: 80,
            right: 16,
            child: Column(
              children: [
                // Toggle heatmap
                GestureDetector(
                  onTap: () {
                    setState(() => _showHeatmap = !_showHeatmap);
                    _loadSpots();
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _showHeatmap ? Colors.red : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.whatshot,
                          size: 20,
                          color: _showHeatmap ? Colors.white : Colors.red,
                        ),
                        Text(
                          'Heat',
                          style: TextStyle(
                            fontSize: 8,
                            color: _showHeatmap ? Colors.white : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildMapTypeButton(
                  Icons.satellite_alt,
                  'Satelit',
                  MapType.hybrid,
                ),
                const SizedBox(height: 8),
                _buildMapTypeButton(Icons.terrain, 'Terrain', MapType.terrain),
                const SizedBox(height: 8),
                _buildMapTypeButton(Icons.map, 'Normal', MapType.normal),
              ],
            ),
          ),

          // Info spot count
          Positioned(
            bottom: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Text(
                '🎣 ${_markers.length} Spot'
                '${_filterKategori != 'Semua' ? ' • $_filterKategori' : ''}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _buildMapTypeButton(IconData icon, String label, MapType type) {
    final isActive = _currentMapType == type;
    return GestureDetector(
      onTap: () => setState(() => _currentMapType = type),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1B5E20) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
            ),
          ],
          border: Border.all(
            color: isActive
                ? const Color(0xFF1B5E20)
                : Colors.grey.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? Colors.white : const Color(0xFF1B5E20),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                color: isActive ? Colors.white : const Color(0xFF1B5E20),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
