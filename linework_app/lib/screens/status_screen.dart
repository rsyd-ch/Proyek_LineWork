import 'package:flutter/material.dart';

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Pekerjaan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const _TimelineItem(
            title: 'Tugas dibuat',
            time: '09:20',
            status: TimelineStatus.done,
          ),
          const _TimelineItem(
            title: 'Penawaran diterima',
            time: '09:35',
            status: TimelineStatus.done,
          ),
          const _TimelineItem(
            title: 'Pekerjaan dimulai',
            time: '09:50',
            status: TimelineStatus.active,
          ),
          const _TimelineItem(
            title: 'Selesaikan pekerjaan',
            time: '10:30',
            status: TimelineStatus.idle,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE0E8F4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kemajuan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E8F4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.6,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF4FC3F7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '60% selesai',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A7A3C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () {},
                  child: const Text(
                    'Konfirmasi Selesai',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum TimelineStatus { done, active, idle }

class _TimelineItem extends StatelessWidget {
  final String title;
  final String time;
  final TimelineStatus status;
  const _TimelineItem({
    required this.title,
    required this.time,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    switch (status) {
      case TimelineStatus.done:
        dotColor = const Color(0xFF1A7A3C);
        break;
      case TimelineStatus.active:
        dotColor = const Color(0xFF1B3D6E);
        break;
      default:
        dotColor = const Color(0xFFE0E8F4);
        break;
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              Container(width: 2, height: 48, color: const Color(0xFFE0E8F4)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B3D6E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
