import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Peta Interaktif',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [Color(0xFFDBEAFE), Color(0xFFE0F2FE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.18,
                    child: CustomPaint(painter: _MapGridPainter()),
                  ),
                ),
                const Positioned(
                  left: 120,
                  top: 103,
                  child: _LocationPin(label: 'Anda'),
                ),
                const Positioned(
                  left: 40,
                  top: 70,
                  child: _LocationPin(label: 'Tugas A'),
                ),
                const Positioned(
                  right: 36,
                  top: 50,
                  child: _LocationPin(label: 'Tugas B'),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE0E8F4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '3 tugas ditemukan di sekitar Anda',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1B3D6E),
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Tarif negosiasi · Radius 5 km · Aktif sekarang',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Filter Lokasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1B3D6E),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _FilterChip(label: 'Radius 5 km', active: true),
              _FilterChip(label: 'Hanya tugas baru'),
              _FilterChip(label: 'Prioritas COD'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationPin extends StatelessWidget {
  final String label;
  const _LocationPin({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF4FC3F7),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Center(
            child: Icon(Icons.location_on, color: Colors.white, size: 12),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF1B3D6E)),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  const _FilterChip({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1B3D6E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC5D8F0)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: active ? Colors.white : const Color(0xFF1B3D6E),
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF93C5FD);
    for (var y = 20.0; y < size.height; y += 40) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 2), paint);
    }
    for (var x = 20.0; x < size.width; x += 40) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 2, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
