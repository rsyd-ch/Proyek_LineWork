import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:linework_app/models/task_model.dart';
import 'package:linework_app/services/auth_service.dart';
import 'package:linework_app/services/firestore_service.dart';
import 'package:linework_app/services/location_service.dart';
import 'package:uuid/uuid.dart';

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
  final _locationController = TextEditingController();

  String _category = 'Angkut Barang';
  bool _isCod = true;
  bool _isPosting = false;
  bool _isLoadingLocation = false;
  String? _errorMessage;
  GeoPoint? _selectedLocation;

  final List<String> _categories = [
    'Angkut Barang',
    'Belanja',
    'Bantu Angkut',
    'Borong',
    'Lainnya',
  ];

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    try {
      final position = await LocationService.getCurrentLocation();
      if (position == null) {
        throw Exception('Gagal mendapatkan lokasi. Pastikan GPS aktif.');
      }

      setState(() {
        _selectedLocation = GeoPoint(position.latitude, position.longitude);
        _locationController.text =
            'Lat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)}';
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi berhasil diambil!')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _postTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      setState(() {
        _errorMessage = 'Silakan ambil lokasi terlebih dahulu.';
      });
      return;
    }

    setState(() {
      _isPosting = true;
      _errorMessage = null;
    });

    try {
      final user = AuthService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      const uuid = Uuid();
      final taskId = uuid.v4();

      final task = TaskModel(
        id: taskId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        requesterId: user.uid,
        location: _selectedLocation!,
        price: double.parse(_priceController.text),
        isCod: _isCod,
        category: _category,
        createdAt: DateTime.now(),
      );

      await FirestoreService.createTask(task);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tugas berhasil diposting!')),
      );

      Navigator.of(context).pop();
    } catch (error) {
      setState(() {
        _errorMessage = 'Gagal memposting tugas. Coba lagi.';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Tugas Baru'),
        backgroundColor: const Color(0xFF1B3D6E),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Buat Postingan Tugas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B3D6E)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Deskripsikan tugas yang perlu dibantu dengan jelas.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Judul Tugas',
                    hintText: 'Contoh: Angkut Lemari ke Lantai Atas',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Judul wajib diisi.' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Lengkap',
                    hintText: 'Jelaskan detail tugas, waktu, dan persyaratan khusus...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Deskripsi wajib diisi.' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga yang Ditawarkan (Rp)',
                    hintText: 'Contoh: 50000',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Harga wajib diisi.';
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) return 'Harga harus angka positif.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _locationController,
                      enabled: false,
                      decoration: InputDecoration(
                        labelText: 'Lokasi Tugas',
                        hintText: 'Tekan tombol untuk ambil lokasi GPS',
                        border: const OutlineInputBorder(),
                        suffixIcon: _selectedLocation != null
                            ? const Icon(Icons.location_on, color: Colors.green)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                      icon: _isLoadingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.location_searching),
                      label: Text(
                        _isLoadingLocation
                            ? 'Mengambil Lokasi...'
                            : _selectedLocation != null
                                ? 'Lokasi Terpilih ✓'
                                : 'Ambil Lokasi GPS',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedLocation != null
                            ? Colors.green
                            : const Color(0xFF1B3D6E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _category = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Checkbox(
                      value: _isCod,
                      onChanged: (value) {
                        setState(() {
                          _isCod = value ?? true;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Pembayaran Cash on Delivery (COD)',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'COD: Bayar langsung setelah tugas selesai.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),

                const SizedBox(height: 24),

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
                  onPressed: _isPosting ? null : _postTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B3D6E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: _isPosting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Post Tugas', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
