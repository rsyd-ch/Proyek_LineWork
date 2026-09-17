import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:linework_app/models/task_model.dart';
import 'package:linework_app/services/auth_service.dart';
import 'package:linework_app/services/firestore_service.dart';
import 'package:linework_app/services/location_service.dart';
import 'package:uuid/uuid.dart';

const _brandColor = Color(0xFF0B4778);

class TaskPostingScreen extends StatefulWidget {
  const TaskPostingScreen({super.key});

  @override
  State<TaskPostingScreen> createState() => _TaskPostingScreenState();
}

class _TaskPostingScreenState extends State<TaskPostingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  String _category = 'Angkut Barang';
  bool _isPosting = false;
  bool _isLoadingLocation = false;
  String? _errorMessage;
  GeoPoint? _selectedLocation;

  final List<String> _categories = const [
    'Angkut Barang',
    'Belanja',
    'Bantu Angkut',
    'Borong',
    'Lainnya',
  ];

  final List<int> _pricePresets = const [25000, 50000, 75000, 100000];

  int _parsePrice() {
    final digits = _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  String _formatPrice(num price) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi.';
    }
    return null;
  }

  void _setPrice(int price) {
    setState(() {
      _priceController.text = price.toString();
    });
  }

  Future<void> _getCurrentLocation() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    try {
      final position = await LocationService.getCurrentLocation();
      if (position == null) {
        setState(() {
          _errorMessage =
              'Lokasi belum bisa diambil. Aktifkan GPS dan izinkan akses lokasi.';
        });
        return;
      }

      setState(() {
        _selectedLocation = GeoPoint(position.latitude, position.longitude);
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi tugas berhasil disimpan.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _postTask() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_selectedLocation == null) {
      setState(() {
        _errorMessage = 'Ambil lokasi tugas terlebih dahulu.';
      });
      return;
    }

    setState(() {
      _isPosting = true;
      _errorMessage = null;
    });

    try {
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      const uuid = Uuid();
      final taskId = uuid.v4();

      final task = TaskModel(
        id: taskId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        requesterId: user.uid,
        location: _selectedLocation!,
        price: _parsePrice().toDouble(),
        isCod: true,
        category: _category,
        createdAt: DateTime.now(),
      );

      await FirestoreService.createTask(task);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pekerjaan berhasil dibuat.')),
      );

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Pekerjaan belum bisa dibuat. Periksa koneksi dan coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final priceValue = _parsePrice();
    final pricePreview = priceValue > 0 ? _formatPrice(priceValue) : null;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Pekerjaan'), elevation: 0),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              const _HeaderCard(),
              const SizedBox(height: 16),
              const _SectionTitle(
                icon: Icons.edit_note_outlined,
                title: 'Detail pekerjaan',
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Judul pekerjaan',
                  hintText: 'Contoh: Angkut lemari ke lantai atas',
                  prefixIcon: const Icon(Icons.title),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: colorScheme.surface,
                ),
                validator: (value) => _validateRequired(value, 'Judul'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  hintText:
                      'Jelaskan barang, waktu, akses lokasi, dan catatan.',
                  prefixIcon: const Icon(Icons.notes_outlined),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: colorScheme.surface,
                  alignLabelWithHint: true,
                ),
                validator: (value) => _validateRequired(value, 'Deskripsi'),
              ),
              const SizedBox(height: 16),
              const _SectionTitle(
                icon: Icons.category_outlined,
                title: 'Kategori',
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((category) {
                  final selected = category == _category;
                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    showCheckmark: false,
                    selectedColor: colorScheme.primary,
                    backgroundColor: colorScheme.surface,
                    side: BorderSide(
                      color: selected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                    ),
                    labelStyle: TextStyle(
                      color: selected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onSelected: (_) {
                      setState(() {
                        _category = category;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const _SectionTitle(
                icon: Icons.payments_outlined,
                title: 'Harga dan pembayaran',
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Harga yang ditawarkan',
                  hintText: 'Contoh: 50000',
                  prefixIcon: const Icon(Icons.sell_outlined),
                  prefixText: 'Rp ',
                  suffixText: pricePreview,
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: colorScheme.surface,
                ),
                validator: (value) {
                  final price = _parsePrice();
                  if (value == null || value.trim().isEmpty) {
                    return 'Harga wajib diisi.';
                  }
                  if (price <= 0) {
                    return 'Harga harus lebih dari 0.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _pricePresets.map((price) {
                  return ActionChip(
                    label: Text(_formatPrice(price)),
                    avatar: const Icon(Icons.add, size: 16),
                    backgroundColor: colorScheme.surface,
                    side: BorderSide(color: colorScheme.outlineVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onPressed: () => _setPrice(price),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pembayaran dilakukan secara COD (Cash on Delivery) saat pekerjaan selesai.',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const _SectionTitle(
                icon: Icons.location_on_outlined,
                title: 'Lokasi tugas',
              ),
              const SizedBox(height: 10),
              _LocationPanel(
                location: _selectedLocation,
                isLoading: _isLoadingLocation,
                onPressed: _getCurrentLocation,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                _ErrorBanner(message: _errorMessage!),
              ],
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isPosting ? null : _postTask,
                icon: _isPosting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.publish_outlined),
                label: Text(_isPosting ? 'Menyimpan...' : 'Posting Pekerjaan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brandColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _brandColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.work_outline, color: Colors.white, size: 32),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Posting pekerjaan baru',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Isi detail yang jelas agar bantuan lebih cepat datang.',
                  style: TextStyle(color: Color(0xFFD9F0FF), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, color: colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _LocationPanel extends StatelessWidget {
  final GeoPoint? location;
  final bool isLoading;
  final VoidCallback onPressed;

  const _LocationPanel({
    required this.location,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasLocation = location != null;
    final title = hasLocation ? 'Lokasi siap digunakan' : 'Belum ada lokasi';
    final subtitle = hasLocation
        ? 'Lat ${location!.latitude.toStringAsFixed(5)}, Lon ${location!.longitude.toStringAsFixed(5)}'
        : 'Gunakan GPS perangkat untuk menyimpan titik tugas.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasLocation
                  ? const Color(0xFFE7F8EF)
                  : colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              hasLocation ? Icons.my_location : Icons.location_searching,
              color: hasLocation
                  ? const Color(0xFF15803D)
                  : colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: isLoading ? null : onPressed,
            tooltip: hasLocation ? 'Perbarui lokasi' : 'Ambil lokasi',
            style: IconButton.styleFrom(
              backgroundColor: _brandColor,
              foregroundColor: Colors.white,
              fixedSize: const Size(42, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(hasLocation ? Icons.refresh : Icons.gps_fixed),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
