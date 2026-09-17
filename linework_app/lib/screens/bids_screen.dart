import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:linework_app/models/bid_model.dart';
import 'package:linework_app/models/task_model.dart';
import 'package:linework_app/services/auth_service.dart';
import 'package:linework_app/services/firestore_service.dart';
import 'package:linework_app/widgets/user_profile_link.dart';
import 'package:uuid/uuid.dart';

class BidsScreen extends StatefulWidget {
  final TaskModel task;

  const BidsScreen({super.key, required this.task});

  @override
  State<BidsScreen> createState() => _BidsScreenState();
}

class _BidsScreenState extends State<BidsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;
  bool _isAccepting = false;
  String? _errorMessage;

  int _parseAmount() {
    final digits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  String _formatMoney(num value) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  Future<void> _submitBid() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      const uuid = Uuid();
      final bid = BidModel(
        id: uuid.v4(),
        taskId: widget.task.id,
        providerId: user.uid,
        amount: _parseAmount().toDouble(),
        message: _messageController.text.trim(),
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await FirestoreService.createBid(bid);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tawaran berhasil dikirim.')),
      );

      _amountController.clear();
      _messageController.clear();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Tawaran belum bisa dikirim. Coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _acceptBid(BidModel bid) async {
    setState(() {
      _isAccepting = true;
      _errorMessage = null;
    });

    try {
      await FirestoreService.acceptBid(taskId: widget.task.id, bidId: bid.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tawaran diterima. Pekerjaan dimulai.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Tawaran belum bisa diterima. Coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAccepting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Penawaran'), elevation: 0),
      body: StreamBuilder<TaskModel?>(
        stream: FirestoreService.streamTask(widget.task.id),
        builder: (context, taskSnapshot) {
          final task = taskSnapshot.data ?? widget.task;
          final isOwnTask = task.requesterId == AuthService.currentUser?.uid;
          final canBid = !isOwnTask && task.status == 'open';
          final canAcceptBid = isOwnTask && task.status == 'open';

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _TaskSummary(task: task),
                if (_errorMessage != null && !canBid) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (!canBid && !isOwnTask) ...[
                  const SizedBox(height: 16),
                  _InfoBox(
                    icon: Icons.lock_clock_outlined,
                    title: 'Penawaran ditutup',
                    message: 'Pekerjaan ini sudah berjalan atau selesai.',
                  ),
                ],
                if (canBid) ...[
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Buat tawaran',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: 'Nominal tawaran',
                              hintText: 'Contoh: 50000',
                              prefixIcon: const Icon(Icons.sell_outlined),
                              prefixText: 'Rp ',
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: colorScheme.surface,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nominal tawaran wajib diisi.';
                              }
                              if (_parseAmount() <= 0) {
                                return 'Nominal tawaran harus lebih dari 0.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _messageController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: 'Pesan singkat',
                              hintText:
                                  'Contoh: Saya bisa datang sore ini dan membawa alat bantu.',
                              prefixIcon: const Icon(Icons.chat_bubble_outline),
                              border: const OutlineInputBorder(),
                              filled: true,
                              fillColor: colorScheme.surface,
                              alignLabelWithHint: true,
                            ),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: colorScheme.error,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: _isSubmitting ? null : _submitBid,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_outlined),
                            label: Text(
                              _isSubmitting ? 'Mengirim...' : 'Kirim Tawaran',
                            ),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Text(
                  isOwnTask ? 'Tawaran masuk' : 'Tawaran lain',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                StreamBuilder<List<BidModel>>(
                  stream: FirestoreService.streamBidsForTask(widget.task.id),
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
                      return _InfoBox(
                        icon: Icons.cloud_off_outlined,
                        title: 'Tawaran belum bisa dimuat',
                        message: 'Periksa koneksi Firebase lalu coba lagi.',
                      );
                    }

                    final bids = snapshot.data ?? [];
                    if (bids.isEmpty) {
                      return _InfoBox(
                        icon: Icons.inbox_outlined,
                        title: 'Belum ada tawaran',
                        message: isOwnTask
                            ? 'Tawaran dari penyedia jasa akan muncul di sini.'
                            : 'Kirim tawaran pertama untuk membuka negosiasi.',
                      );
                    }

                    return Column(
                      children: bids.map((bid) {
                        return _BidCard(
                          bid: bid,
                          money: _formatMoney(bid.amount),
                          canAccept: canAcceptBid && !_isAccepting,
                          onAccept: () => _acceptBid(bid),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}

class _TaskSummary extends StatelessWidget {
  final TaskModel task;

  const _TaskSummary({required this.task});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final money = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(task.price);

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
            task.title,
            style: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$money - ${task.category} - COD',
            style: TextStyle(
              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          UserProfileLink(
            userId: task.requesterId,
            label: 'Pemberi pekerjaan',
            compact: true,
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _InfoBox({
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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

class _BidCard extends StatelessWidget {
  final BidModel bid;
  final String money;
  final bool canAccept;
  final VoidCallback onAccept;

  const _BidCard({
    required this.bid,
    required this.money,
    required this.canAccept,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPending = bid.status == 'pending';
    final isAccepted = bid.status == 'accepted';

    final statusColor = isPending
        ? const Color(0xFFF59E0B)
        : isAccepted
        ? const Color(0xFF16A34A)
        : colorScheme.error;

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
          UserProfileLink(
            userId: bid.providerId,
            label: 'Penawar',
            compact: true,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  money,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bid.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (bid.message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              bid.message,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Dikirim ${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(bid.createdAt)}',
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
          ),
          if (canAccept && bid.status == 'pending') ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onAccept,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Terima Tawaran'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
