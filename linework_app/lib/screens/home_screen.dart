import 'package:flutter/material.dart';
import 'package:linework_app/models/task_model.dart';
import 'package:linework_app/screens/detail_screen.dart';
import 'package:linework_app/services/firestore_service.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Angkut Barang';
  final List<String> _categories = [
    'Semua',
    'Angkut Barang',
    'Belanja',
    'Bantu Angkut',
    'Borong',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Beranda',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1B3D6E),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'LineWork: Beresin urusan jadi ringan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Temukan tugas terdekat dan bantu tetangga dengan cepat.',
                  style: TextStyle(color: Color(0xFF8FD6FF), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Kategori',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B3D6E),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isActive = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFF1B3D6E) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFC5D8F0)),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 12,
                          color: isActive ? Colors.white : const Color(0xFF1B3D6E),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Pekerjaan Terdekat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B3D6E),
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<TaskModel>>(
            stream: FirestoreService.streamTasksFiltered(
              category: _selectedCategory == 'Semua' ? null : _selectedCategory,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final tasks = snapshot.data ?? [];

              if (tasks.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text('Tidak ada tugas tersedia.'),
                  ),
                );
              }

              return Column(
                children: tasks.map((task) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DetailScreen(task: task),
                        ),
                      );
                    },
                    child: _JobCard(task: task),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final TaskModel task;

  const _JobCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    final formattedPrice = priceFormat.format(task.price);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E8F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B3D6E),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formattedPrice,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4FC3F7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${task.category} · ${task.isCod ? 'COD' : 'Transfer'}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: task.status == 'open'
                  ? const Color(0xFFE1F5E8)
                  : const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              task.status.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                color: task.status == 'open'
                    ? const Color(0xFF1A7A3C)
                    : const Color(0xFFB07D00),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
