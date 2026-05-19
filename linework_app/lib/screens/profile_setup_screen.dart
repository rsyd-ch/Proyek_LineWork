import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linework_app/services/firestore_service.dart';
import 'package:linework_app/services/storage_service.dart';
import 'package:linework_app/screens/main_shell.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String uid;
  final String email;

  const ProfileSetupScreen({required this.uid, required this.email, super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nikController = TextEditingController();
  String _role = 'Penyedia Jasa';
  File? _ktpFile;
  bool _isSaving = false;
  String? _errorMessage;

  Future<void> _pickKtp() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _ktpFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ktpFile == null) {
      setState(() {
        _errorMessage = 'Unggah foto KTP untuk melanjutkan.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final ktpUrl = await StorageService.uploadKtp(uid: widget.uid, file: _ktpFile!);
      await FirestoreService.createUserProfile(widget.uid, {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'nik': _nikController.text.trim(),
        'role': _role.toLowerCase(),
        'ktpUrl': ktpUrl,
        'isVerified': false,
        'updatedAt': DateTime.now(),
      });
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } catch (error) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan saat menyimpan profil. Coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lengkapi Profil'),
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
                const Text('Lengkapi data akun LineWork kamu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1B3D6E))),
                const SizedBox(height: 12),
                Text('Email terdaftar: ${widget.email}', style: const TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.isEmpty ? 'Nama wajib diisi.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Nomor Telepon', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value == null || value.isEmpty ? 'Telepon wajib diisi.' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nikController,
                  decoration: const InputDecoration(labelText: 'NIK', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.isEmpty ? 'NIK wajib diisi.' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: 'Peran', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Penyedia Jasa', child: Text('Penyedia Jasa')),
                    DropdownMenuItem(value: 'Pemohon', child: Text('Pemohon')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _role = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _pickKtp,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFEFF6FF),
                    foregroundColor: const Color(0xFF1B3D6E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(_ktpFile == null ? 'Unggah Foto KTP' : 'Ubah Foto KTP'),
                ),
                if (_ktpFile != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text('File dipilih: ${_ktpFile!.path.split('/').last}', style: const TextStyle(color: Color(0xFF1B3D6E))),
                  ),
                const SizedBox(height: 20),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  ),
                ElevatedButton(
                  onPressed: _isSaving ? null : _submitProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B3D6E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Simpan Profil', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
