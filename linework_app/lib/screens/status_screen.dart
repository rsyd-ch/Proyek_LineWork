import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:linework_app/models/task_model.dart';
import 'package:linework_app/screens/detail_screen.dart';
import 'package:linework_app/services/auth_service.dart';
import 'package:linework_app/services/firestore_service.dart';
import 'package:linework_app/widgets/user_profile_link.dart';

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    if (user == null) {
      return const _StatusShell(
        child: _InfoState(
          icon: Icons.lock_outline,
          title: 'Masuk diperlukan',
          message: 'Silakan masuk untuk melihat status pekerjaan.',
        ),
      );
    }

    return _StatusShell(
      child: StreamBuilder<List<TaskModel>>(
        stream: FirestoreService.streamTasksForUser(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return const _InfoState(
              icon: Icons.cloud_off_outlined,
              title: 'Status belum bisa dimuat',
              message: 'Periksa koneksi Firebase lalu coba lagi.',
            );
          }

          final tasks = snapshot.data ?? [];

          if (tasks.isEmpty) {
            return const _InfoState(
              icon: Icons.timeline_outlined,
              title: 'Belum ada pekerjaan aktif',
              message:
                  'Pekerjaan yang Anda buat atau terima akan muncul di sini.',
            );
          }

          return Column(
            children: tasks.map((task) {
              return _WorkStatusCard(task: task, currentUserId: user.uid);
            }).toList(),
          );
        },
      ),
    );
  }
}

class _StatusShell extends StatelessWidget {
  final Widget child;

  const _StatusShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          const Text(
            'Status Pekerjaan',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Pantau pekerjaan terbuka, berjalan, dan selesai.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _WorkStatusCard extends StatefulWidget {
  final TaskModel task;
  final String currentUserId;

  const _WorkStatusCard({required this.task, required this.currentUserId});

  @override
  State<_WorkStatusCard> createState() => _WorkStatusCardState();
}

class _WorkStatusCardState extends State<_WorkStatusCard> {
  bool _isCompleting = false;

  bool get _isRequester => widget.task.requesterId == widget.currentUserId;

  Future<void> _completeTask() async {
    setState(() {
      _isCompleting = true;
    });

    try {
      await FirestoreService.completeTask(widget.task.id);

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

  void _openDetail() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => DetailScreen(task: widget.task)));
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final colorScheme = Theme.of(context).colorScheme;
    final money = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(task.price);
    final progress = switch (task.status) {
      'completed' => 1.0,
      'in_progress' => 0.66,
      _ => 0.33,
    };
    final canComplete = _isRequester && task.status == 'in_progress';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_isRequester ? 'Dibuat oleh Anda' : 'Dikerjakan oleh Anda'} - $money',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_counterpartId(task).isNotEmpty) ...[
                      const SizedBox(height: 6),
                      UserProfileLink(
                        userId: _counterpartId(task),
                        label: _isRequester
                            ? 'Penerima pekerjaan'
                            : 'Pemberi pekerjaan',
                        compact: true,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusPill(status: task.status),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 14),
          _Timeline(task: task),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openDetail,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Detail'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              if (canComplete) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isCompleting ? null : _completeTask,
                    icon: _isCompleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.task_alt),
                    label: Text(_isCompleting ? 'Menyimpan' : 'Selesai'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _counterpartId(TaskModel task) {
    if (_isRequester) {
      return task.acceptedProviderId ?? '';
    }
    return task.requesterId;
  }
}

class _Timeline extends StatelessWidget {
  final TaskModel task;

  const _Timeline({required this.task});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TimelineItem(
          title: 'Pekerjaan dibuat',
          time: _formatDate(task.createdAt),
          done: true,
        ),
        _TimelineItem(
          title: 'Tawaran diterima',
          time: task.acceptedAt == null
              ? 'Menunggu pilihan'
              : _formatDate(task.acceptedAt!),
          done: task.acceptedAt != null,
        ),
        _TimelineItem(
          title: 'Pekerjaan berjalan',
          time: task.status == 'open' ? 'Belum dimulai' : 'Sedang berjalan',
          done: task.status == 'in_progress' || task.status == 'completed',
        ),
        _TimelineItem(
          title: 'Pekerjaan selesai',
          time: task.completedAt == null
              ? 'Belum selesai'
              : _formatDate(task.completedAt!),
          done: task.status == 'completed',
          isLast: true,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(date);
  }
}

class _TimelineItem extends StatelessWidget {
  final String title;
  final String time;
  final bool done;
  final bool isLast;

  const _TimelineItem({
    required this.title,
    required this.time,
    required this.done,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dotColor = done ? const Color(0xFF16A34A) : colorScheme.outline;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: colorScheme.outlineVariant,
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = switch (status) {
      'completed' => (
        'Selesai',
        const Color(0xFFE7F8EF),
        const Color(0xFF15803D),
      ),
      'in_progress' => (
        'Berjalan',
        const Color(0xFFE0F2FE),
        const Color(0xFF0369A1),
      ),
      _ => ('Terbuka', const Color(0xFFFFF7ED), const Color(0xFFC2410C)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _InfoState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InfoState({
    required this.icon,
    required this.title,
    required this.message,
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
