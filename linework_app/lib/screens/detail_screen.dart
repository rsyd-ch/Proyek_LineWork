import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:linework_app/models/task_model.dart';
import 'package:linework_app/screens/bids_screen.dart';
import 'package:linework_app/services/auth_service.dart';
import 'package:linework_app/services/firestore_service.dart';
import 'package:linework_app/widgets/user_profile_link.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailScreen extends StatefulWidget {
  final TaskModel task;

  const DetailScreen({super.key, required this.task});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isCompleting = false;

  void _openBidsScreen(BuildContext context, TaskModel task) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => BidsScreen(task: task)));
  }

  Future<void> _completeTask(TaskModel task) async {
    setState(() {
      _isCompleting = true;
    });

    try {
      await FirestoreService.completeTask(task.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pekerjaan ditandai selesai.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status belum bisa diperbarui. Coba lagi.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  Future<void> _openLocation(TaskModel task) async {
    final latitude = task.location.latitude;
    final longitude = task.location.longitude;
    final mapsUri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '$latitude,$longitude',
    });

    final opened = await launchUrl(
      mapsUri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi belum bisa dibuka.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pekerjaan'), elevation: 0),
      body: StreamBuilder<TaskModel?>(
        stream: FirestoreService.streamTask(widget.task.id),
        builder: (context, snapshot) {
          final task = snapshot.data ?? widget.task;
          final isOwnTask = task.requesterId == AuthService.currentUser?.uid;
          final canBid = !isOwnTask && task.status == 'open';
          final canComplete = isOwnTask && task.status == 'in_progress';
          final priceFormat = NumberFormat.currency(
            locale: 'id_ID',
            symbol: 'Rp ',
            decimalDigits: 0,
          );
          final formattedPrice = priceFormat.format(task.price);

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _HeaderPill(label: task.category),
                          const _HeaderPill(label: 'COD'),
                          _HeaderPill(label: _statusLabel(task.status)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _PricePanel(
                  price: formattedPrice,
                  caption: isOwnTask
                      ? _ownerCaption(task.status)
                      : _workerCaption(task.status),
                ),
                const SizedBox(height: 14),
                _DetailPanel(task: task),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _openLocation(task),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Buka Lokasi'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (canBid) ...[
                  ElevatedButton.icon(
                    onPressed: () => _openBidsScreen(context, task),
                    icon: const Icon(Icons.handshake_outlined),
                    label: const Text('Ajukan Penawaran'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (canComplete) ...[
                  ElevatedButton.icon(
                    onPressed: _isCompleting ? null : () => _completeTask(task),
                    icon: _isCompleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.task_alt),
                    label: Text(
                      _isCompleting ? 'Menyimpan...' : 'Konfirmasi Selesai',
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                OutlinedButton.icon(
                  onPressed: () => _openBidsScreen(context, task),
                  icon: const Icon(Icons.list_alt_outlined),
                  label: Text(
                    isOwnTask ? 'Lihat Tawaran Masuk' : 'Lihat Tawaran',
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _statusLabel(String status) {
    return switch (status) {
      'completed' => 'SELESAI',
      'in_progress' => 'BERJALAN',
      _ => 'TERBUKA',
    };
  }

  String _ownerCaption(String status) {
    return switch (status) {
      'completed' => 'Pekerjaan selesai. Lanjutkan dengan rating.',
      'in_progress' => 'Pekerjaan sedang berjalan. Konfirmasi saat selesai.',
      _ => 'Ini adalah pekerjaan Anda. Pantau tawaran yang masuk.',
    };
  }

  String _workerCaption(String status) {
    return switch (status) {
      'completed' => 'Pekerjaan ini sudah selesai.',
      'in_progress' => 'Pekerjaan sudah berjalan dengan penyedia terpilih.',
      _ => 'Ajukan penawaran terbaik untuk pekerjaan ini.',
    };
  }
}

class _HeaderPill extends StatelessWidget {
  final String label;

  const _HeaderPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colorScheme.onPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PricePanel extends StatelessWidget {
  final String price;
  final String caption;

  const _PricePanel({required this.price, required this.caption});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Harga yang ditawarkan',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailPanel extends StatelessWidget {
  final TaskModel task;

  const _DetailPanel({required this.task});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          UserProfileLink(
            userId: task.requesterId,
            label: 'Pemberi pekerjaan',
          ),
          if (task.acceptedProviderId != null &&
              task.acceptedProviderId!.isNotEmpty)
            UserProfileLink(
              userId: task.acceptedProviderId!,
              label: 'Penerima pekerjaan',
            ),
          const Divider(height: 20),
          _DetailRow(label: 'Deskripsi', value: task.description),
          _DetailRow(
            label: 'Lokasi',
            value:
                'Lat ${task.location.latitude.toStringAsFixed(5)}, Lon ${task.location.longitude.toStringAsFixed(5)}',
          ),
          _DetailRow(label: 'Kategori', value: task.category),
          const _DetailRow(
            label: 'Pembayaran',
            value: 'COD',
          ),
          _DetailRow(
            label: 'Dibuat',
            value: DateFormat(
              'dd MMM yyyy, HH:mm',
              'id_ID',
            ).format(task.createdAt),
          ),
        ],
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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
