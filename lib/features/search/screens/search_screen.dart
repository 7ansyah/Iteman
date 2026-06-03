import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../spots/screens/spot_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/spot_like_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedKategori = 'Semua';
  String _selectedJenisAir = 'Semua';

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

  final List<String> _jenisAirList = ['Semua', 'Tawar', 'Payau', 'Asin'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Query _buildQuery() {
    Query query = FirebaseFirestore.instance.collection('spots');

    if (_selectedKategori != 'Semua' && _selectedJenisAir != 'Semua') {
      // Keduanya dipilih — butuh composite index
      query = query
          .where('kategoriPerairan', isEqualTo: _selectedKategori)
          .where('jenisAir', isEqualTo: _selectedJenisAir)
          .orderBy('createdAt', descending: true);
    } else if (_selectedKategori != 'Semua') {
      query = query
          .where('kategoriPerairan', isEqualTo: _selectedKategori)
          .orderBy('createdAt', descending: true);
    } else if (_selectedJenisAir != 'Semua') {
      query = query
          .where('jenisAir', isEqualTo: _selectedJenisAir)
          .orderBy('createdAt', descending: true);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    return query;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: const Text(
          'Cari Spot',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari nama spot atau jenis ikan...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                _buildFilterRow(
                  'Kategori:',
                  _kategoriList,
                  _selectedKategori,
                  (v) => setState(() => _selectedKategori = v),
                ),
                const SizedBox(height: 4),
                _buildFilterRow(
                  'Air:',
                  _jenisAirList,
                  _selectedJenisAir,
                  (v) => setState(() => _selectedJenisAir = v),
                ),
              ],
            ),
          ),

          // Hasil pencarian
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Tidak ada spot ditemukan',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Filter by search query
                final docs = snapshot.data!.docs.where((doc) {
                  if (_searchQuery.isEmpty) return true;
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final ikan = (data['targetIkan'] as List? ?? [])
                      .join(' ')
                      .toLowerCase();
                  final desc = (data['description'] ?? '')
                      .toString()
                      .toLowerCase();
                  return name.contains(_searchQuery) ||
                      ikan.contains(_searchQuery) ||
                      desc.contains(_searchQuery);
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 60,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada spot untuk "$_searchQuery"',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildSearchCard(context, data, docs[index].id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(
    String label,
    List<String> options,
    String selected,
    Function(String) onSelect,
  ) {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: options.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8, left: 4),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }
          final option = options[index - 1];
          final isSelected = selected == option;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(
                option,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => onSelect(option),
              backgroundColor: Colors.grey[100],
              selectedColor: const Color(0xFF1B5E20),
              checkmarkColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchCard(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SpotDetailScreen(data: data, docId: docId),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Foto
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: data['imageUrl'] != null && data['imageUrl'] != ''
                  ? CachedNetworkImage(
                      imageUrl: data['imageUrl'],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 100,
                      height: 100,
                      color: const Color(0xFF1B5E20).withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.phishing,
                        color: Color(0xFF1B5E20),
                        size: 32,
                      ),
                    ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'] ?? 'Spot Mancing',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data['kategoriPerairan']} • ${data['jenisAir']}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    if (data['targetIkan'] != null &&
                        (data['targetIkan'] as List).isNotEmpty)
                      Text(
                        '🐟 ${(data['targetIkan'] as List).take(3).join(', ')}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1B5E20),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.favorite, size: 12, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          '${SpotLikeService.getLikeCount(data)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.remove_red_eye,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${data['views'] ?? 0}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.chevron_right, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
