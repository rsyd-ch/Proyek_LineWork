import 'package:flutter/material.dart';

class RatingScreen extends StatelessWidget {
  const RatingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Beri Rating',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF1B3D6E),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Bagikan pengalamanmu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Pilih bintang dan tulis komentar singkat.',
                  style: TextStyle(color: Color(0xFF8FD6FF), fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0E8F4)),
            ),
            child: Column(
              children: [
                Row(
                  children: const [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFFE8EEF6),
                      child: Text(
                        'AB',
                        style: TextStyle(
                          color: Color(0xFF1B3D6E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Andi Budi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1B3D6E),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Pekerja Angkut',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => const Icon(
                      Icons.star,
                      color: Color(0xFFF59E0B),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const TextField(
                  maxLines: 4,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Color(0xFFF4F7FB),
                    hintText: 'Tulis komentar tentang pengerjaan...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Color(0xFFE0E8F4)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _TagChip(label: 'Tepat Waktu', selected: true),
                    _TagChip(label: 'Ramah'),
                    _TagChip(label: 'Kuat'),
                    _TagChip(label: 'Terpercaya'),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FC3F7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: () {},
                  child: const Text(
                    'Kirim Rating',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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

class _TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  const _TagChip({required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF1B3D6E) : const Color(0xFFEBF5FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC5D8F0)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: selected ? Colors.white : const Color(0xFF1B3D6E),
        ),
      ),
    );
  }
}
