import 'package:flutter/material.dart';
import 'package:linework_app/models/bid_model.dart';
import 'package:linework_app/models/task_model.dart';
import 'package:linework_app/services/auth_service.dart';
import 'package:linework_app/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class BidsScreen extends StatefulWidget {
  final TaskModel task;

  const BidsScreen({super.key, required this.task});

  @override
  State<BidsScreen> createState() => _BidsScreenState();
}

class _BidsScreenState extends State<BidsScreen> {
  final _amountController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _submitBid() async {
    if (_amountController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Harga tawaran wajib diisi.';
      });
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() {
        _errorMessage = 'Harga tawaran harus angka positif.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final user = AuthService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      const uuid = Uuid();
      final bid = BidModel(
        id: uuid.v4(),
        taskId: widget.task.id,
        providerId: user.uid,
        amount: amount,
        message: _messageController.text.trim(),
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await FirestoreService.createBid(bid);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tawaran berhasil dikirim!')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengirim tawaran. Coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tawar Pekerjaan'),
        backgroundColor: const Color(0xFF1B3D6E),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detail Pekerjaan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B3D6E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.task.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Harga: Rp ${NumberFormat.decimalPattern('id_ID').format(widget.task.price)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF4FC3F7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.task.description,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Buat Tawaran Anda',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B3D6E),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga Tawaran (Rp)',
                  hintText: 'Contoh: 50000',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Pesan (Opsional)',
                  hintText: 'Jelaskan mengapa Anda cocok untuk pekerjaan ini...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitBid,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B3D6E),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Kirim Tawaran', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 20),
              const Text(
                'Daftar Tawaran',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B3D6E),
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<List<BidModel>>(
                stream: FirestoreService.streamBidsForTask(widget.task.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final bids = snapshot.data ?? [];

                  if (bids.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Text('Belum ada tawaran.'),
                      ),
                    );
                  }

                  return Column(
                    children: bids.map((bid) {
                      return _BidCard(bid: bid);
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
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

class _BidCard extends StatelessWidget {
  final BidModel bid;

  const _BidCard({required this.bid});

  @override
  Widget build(BuildContext context) {
    final statusColor = bid.status == 'pending'
        ? const Color(0xFFFFF8E1)
        : bid.status == 'accepted'
            ? const Color(0xFFE1F5E8)
            : const Color(0xFFFFE8E8);

    final statusTextColor = bid.status == 'pending'
        ? const Color(0xFFB07D00)
        : bid.status == 'accepted'
            ? const Color(0xFF1A7A3C)
            : const Color(0xFFC7254E);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E8F4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rp ${NumberFormat.decimalPattern('id_ID').format(bid.amount)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4FC3F7),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  bid.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusTextColor,
                  ),
                ),
              ),
            ],
          ),
          if (bid.message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              bid.message,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Ditawarkan: ${DateFormat('dd/MM/yyyy HH:mm').format(bid.createdAt)}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
