import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:linework_app/models/task_model.dart';
import 'package:linework_app/screens/detail_screen.dart';
import 'package:linework_app/screens/profile_screen.dart';
import 'package:linework_app/screens/task_posting_screen.dart';
import 'package:linework_app/services/firestore_service.dart';
import 'package:linework_app/widgets/user_profile_link.dart';

const _brandColor = Color(0xFF0B4778);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Semua';

  final List<String> _categories = const [
    'Semua',
    'Angkut Barang',
    'Belanja',
    'Bantu Angkut',
    'Borong',
  ];

  void _openTaskPosting() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TaskPostingScreen()));
  }

  void _openTaskDetail(TaskModel task) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => DetailScreen(task: task)));
  }

  void _openProfileScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
          children: [
            _BrandHeader(onProfilePressed: _openProfileScreen),
            const SizedBox(height: 14),
            _PrimaryAction(onPressed: _openTaskPosting),
            const SizedBox(height: 18),
            const _InsightRow(),
            const SizedBox(height: 22),
            const _SectionHeader(title: 'Kategori'),
            const SizedBox(height: 10),
            _CategorySelector(
              categories: _categories,
              selectedCategory: _selectedCategory,
              onSelected: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),
            const SizedBox(height: 22),
            StreamBuilder<List<TaskModel>>(
              stream: FirestoreService.streamTasksFiltered(
                category: _selectedCategory == 'Semua'
                    ? null
                    : _selectedCategory,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingTasks();
                }

                if (snapshot.hasError) {
                  return _InfoState(
                    icon: Icons.cloud_off,
                    title: 'Pekerjaan belum bisa dimuat',
                    message:
                        'Koneksi ke Firebase sedang terputus. Coba ganti jaringan atau matikan Private DNS sementara.',
                    actionLabel: 'Coba Muat Ulang',
                    onAction: () => setState(() {}),
                  );
                }

                final tasks = snapshot.data ?? [];

                if (tasks.isEmpty) {
                  return _InfoState(
                    icon: Icons.work_outline,
                    title: 'Belum ada pekerjaan',
                    message: _selectedCategory == 'Semua'
                        ? 'Jadilah yang pertama membuat pekerjaan hari ini.'
                        : 'Tidak ada pekerjaan di kategori $_selectedCategory.',
                    actionLabel: 'Buat Pekerjaan',
                    onAction: _openTaskPosting,
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                      title: 'Pekerjaan Terdekat',
                      trailing: '${tasks.length} tersedia',
                    ),
                    const SizedBox(height: 12),
                    ...tasks.map(
                      (task) => _JobCard(
                        task: task,
                        onTap: () => _openTaskDetail(task),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  final VoidCallback onProfilePressed;

  const _BrandHeader({required this.onProfilePressed});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colorScheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final logoHeight = (constraints.maxWidth * 0.16)
            .clamp(48.0, 64.0)
            .toDouble();

        return DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outlineVariant),
            boxShadow: isDark
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: 'LineWork, Beresin urusan jadi ringan',
                    image: true,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Image.asset(
                        'assets/images/nametag.png',
                        height: logoHeight,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Tooltip(
                  message: 'Profil',
                  child: IconButton(
                    onPressed: onProfilePressed,
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimaryContainer,
                      fixedSize: const Size(46, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.person_outline),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final VoidCallback onPressed;

  const _PrimaryAction({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _brandColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x180B4778),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ada urusan yang perlu dibantu?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Posting pekerjaan, temukan bantuan terdekat, lalu pantau prosesnya.',
            style: TextStyle(color: Color(0xFFD9F0FF), fontSize: 13),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.add_task),
              label: const Text('Buat Pekerjaan'),
              style: ElevatedButton.styleFrom(
                foregroundColor: _brandColor,
                backgroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _InsightItem(
            icon: Icons.payments_outlined,
            title: 'COD',
            subtitle: 'Bayar di tempat',
            color: Color(0xFF16A34A),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _InsightItem(
            icon: Icons.near_me_outlined,
            title: 'Dekat',
            subtitle: 'Area sekitar',
            color: Color(0xFF0284C7),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _InsightItem(
            icon: Icons.verified_user_outlined,
            title: 'Aman',
            subtitle: 'Status jelas',
            color: Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }
}

class _InsightItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _InsightItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 92,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const _CategorySelector({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isActive = category == selectedCategory;

          return ChoiceChip(
            selected: isActive,
            label: Text(category),
            labelStyle: TextStyle(
              color: isActive ? colorScheme.onPrimary : colorScheme.onSurface,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            selectedColor: colorScheme.primary,
            backgroundColor: colorScheme.surface,
            side: BorderSide(
              color: isActive
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onSelected: (_) => onSelected(category),
          );
        },
      ),
    );
  }
}

class _LoadingTasks extends StatelessWidget {
  const _LoadingTasks();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        _SectionHeader(title: 'Pekerjaan Terdekat'),
        SizedBox(height: 12),
        _LoadingCard(),
        _LoadingCard(),
        _LoadingCard(),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 98,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      ),
    );
  }
}

class _InfoState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _InfoState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(icon, color: colorScheme.primary, size: 34),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onAction,
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;

  const _JobCard({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final priceFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final formattedPrice = priceFormat.format(task.price);
    final isOpen = task.status == 'open';
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        formattedPrice,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Pemberi: ',
                      style: TextStyle(fontSize: 12),
                    ),
                    Expanded(
                      child: UserNameTextButton(userId: task.requesterId),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaPill(
                      icon: Icons.category_outlined,
                      label: task.category,
                    ),
                    _MetaPill(
                      icon: task.isCod
                          ? Icons.payments_outlined
                          : Icons.account_balance_wallet_outlined,
                      label: task.isCod ? 'COD' : 'Transfer',
                    ),
                    _StatusPill(
                      label: isOpen ? 'Terbuka' : task.status.toUpperCase(),
                      isOpen: isOpen,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final bool isOpen;

  const _StatusPill({required this.label, required this.isOpen});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isOpen
        ? const Color(0xFFE7F8EF)
        : const Color(0xFFFFF7ED);
    final foregroundColor = isOpen
        ? const Color(0xFF15803D)
        : const Color(0xFFC2410C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
