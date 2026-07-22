import 'package:flutter/material.dart';

const _brandColor = Color(0xFF0B4778);

class RatingScreen extends StatefulWidget {
  const RatingScreen({super.key});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final _commentController = TextEditingController();
  final Set<String> _selectedTags = {'Tepat Waktu'};
  int _stars = 5;
  bool _isSending = false;

  final List<String> _tags = const [
    'Tepat Waktu',
    'Ramah',
    'Komunikatif',
    'Rapi',
    'Terpercaya',
    'Harga Sesuai',
  ];

  Future<void> _sendRating() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isSending = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 450));

    if (!mounted) return;
    setState(() {
      _isSending = false;
      _commentController.clear();
      _selectedTags
        ..clear()
        ..add('Tepat Waktu');
      _stars = 5;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rating siap disimpan ke Firebase.')),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Text(
            'Rating',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kelola reputasi dan berikan ulasan setelah pekerjaan selesai.',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const _RatingSummary(),
          const SizedBox(height: 14),
          _ReviewComposer(
            stars: _stars,
            commentController: _commentController,
            tags: _tags,
            selectedTags: _selectedTags,
            isSending: _isSending,
            onStarsChanged: (value) {
              setState(() {
                _stars = value;
              });
            },
            onTagToggle: (tag) {
              setState(() {
                if (_selectedTags.contains(tag)) {
                  _selectedTags.remove(tag);
                } else {
                  _selectedTags.add(tag);
                }
              });
            },
            onSubmit: _sendRating,
          ),
          const SizedBox(height: 18),
          const _SectionTitle(title: 'Riwayat Ulasan'),
          const SizedBox(height: 10),
          const _ReviewCard(
            name: 'Andi Budi',
            work: 'Angkut meja',
            stars: 5,
            comment:
                'Pekerjaan cepat, komunikasi jelas, dan barang sampai aman.',
            tags: ['Tepat Waktu', 'Rapi'],
          ),
          const _ReviewCard(
            name: 'Siti Rahma',
            work: 'Belanja kebutuhan',
            stars: 4,
            comment: 'Respons baik dan pembayaran sesuai kesepakatan.',
            tags: ['Ramah', 'Terpercaya'],
          ),
        ],
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _brandColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.star_rounded, color: Color(0xFFFBBF24)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '4.8 dari 5.0',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '24 ulasan selesai - reputasi sangat baik',
                  style: TextStyle(
                    color: Color(0xFFD9F0FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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

class _ReviewComposer extends StatelessWidget {
  final int stars;
  final TextEditingController commentController;
  final List<String> tags;
  final Set<String> selectedTags;
  final bool isSending;
  final ValueChanged<int> onStarsChanged;
  final ValueChanged<String> onTagToggle;
  final VoidCallback onSubmit;

  const _ReviewComposer({
    required this.stars,
    required this.commentController,
    required this.tags,
    required this.selectedTags,
    required this.isSending,
    required this.onStarsChanged,
    required this.onTagToggle,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.person_outline,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ulas pekerjaan terakhir',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Pilih kualitas layanan yang kamu rasakan.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Wrap(
              spacing: 2,
              children: List.generate(5, (index) {
                final value = index + 1;
                return IconButton(
                  tooltip: '$value bintang',
                  onPressed: () => onStarsChanged(value),
                  icon: Icon(
                    value <= stars
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 32,
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: commentController,
            maxLines: 4,
            decoration: InputDecoration(
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              hintText: 'Tulis komentar tentang pengerjaan...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags.map((tag) {
              final selected = selectedTags.contains(tag);
              return FilterChip(
                selected: selected,
                showCheckmark: false,
                label: Text(tag),
                avatar: Icon(
                  selected ? Icons.check_circle : Icons.add_circle_outline,
                  size: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                onSelected: (_) => onTagToggle(tag),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFB7C7D8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size.fromHeight(48),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            onPressed: isSending ? null : onSubmit,
            icon: isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.send_outlined),
            label: Text(isSending ? 'Mengirim...' : 'Kirim Rating'),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String name;
  final String work;
  final int stars;
  final String comment;
  final List<String> tags;

  const _ReviewCard({
    required this.name,
    required this.work,
    required this.stars,
    required this.comment,
    required this.tags,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  name.substring(0, 1),
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      work,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < stars
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: const Color(0xFFF59E0B),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags.map((tag) => _ReviewTag(label: tag)).toList(),
          ),
        ],
      ),
    );
  }
}

class _ReviewTag extends StatelessWidget {
  final String label;

  const _ReviewTag({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
    );
  }
}
