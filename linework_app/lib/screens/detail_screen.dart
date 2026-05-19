import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:linework_app/models/task_model.dart';
import 'package:linework_app/screens/bids_screen.dart';
import 'package:linework_app/services/auth_service.dart';

class DetailScreen extends StatelessWidget {
  final TaskModel task;

  const DetailScreen({super.key, required this.task});

  void _openBidsScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BidsScreen(task: task),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwnTask = task.requesterId == AuthService.currentUser?.uid;
    final priceFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    final formattedPrice = priceFormat.format(task.price);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Pekerjaan'),
        backgroundColor: const Color(0xFF1B3D6E),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detail Pekerjaan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1B3D6E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${task.category} · ${task.isCod ? 'COD' : 'Transfer'} · Status: ${task.status}',
                    style: const TextStyle(color: Color(0xFF8FD6FF), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE0E8F4)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _DetailRow(
                    label: 'Deskripsi',
                    value: task.description,
                  ),
                  _DetailRow(
                    label: 'Lokasi',
                    value:
                        'Lat: ${task.location.latitude.toStringAsFixed(4)}, Lon: ${task.location.longitude.toStringAsFixed(4)}',
                  ),
                  _DetailRow(
                    label: 'Kategori',
                    value: task.category,
                  ),
                  _DetailRow(
                    label: 'Dibuat',
                    value: DateFormat('dd/MM/yyyy HH:mm').format(task.createdAt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF5FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC5D8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Harga Yang Ditawarkan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B3D6E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formattedPrice,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B3D6E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOwnTask
                        ? 'Ini adalah pekerjaan Anda. Lihat tawaran yang masuk.'
                        : 'Buat tawaran Anda untuk pekerjaan ini.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (!isOwnTask)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B3D6E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () => _openBidsScreen(context),
                child: const Text(
                  'Ajukan Penawaran',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            if (!isOwnTask)
              const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1B3D6E),
                side: const BorderSide(color: Color(0xFF1B3D6E)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                minimumSize: const Size.fromHeight(44),
              ),
              onPressed: () => _openBidsScreen(context),
              child: Text(
                isOwnTask ? 'Lihat Tawaran Masuk' : 'Lihat Tawaran Lain',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B3D6E),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
