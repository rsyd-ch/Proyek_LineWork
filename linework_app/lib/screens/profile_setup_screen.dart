import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:linework_app/models/user_profile.dart';
import 'package:linework_app/screens/main_shell.dart';
import 'package:linework_app/services/firestore_service.dart';
import 'package:linework_app/services/storage_service.dart';

const _brandColor = Color(0xFF0B4778);

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
  final _bioController = TextEditingController();
  final _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasExistingProfile = false;
  String? _errorMessage;
  String? _photoUrl;
  String? _cvUrl;
  File? _selectedPhoto;
  File? _selectedCv;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final profile = await FirestoreService.getUserProfile(widget.uid);
    if (!mounted) return;

    if (profile != null) {
      _hasExistingProfile = true;
      _fillProfile(profile);
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _fillProfile(UserProfile profile) {
    _nameController.text = profile.name ?? '';
    _phoneController.text = profile.phone ?? '';
    _nikController.text = profile.nik ?? '';
    _bioController.text = profile.publicBio ?? '';
    _photoUrl = profile.photoUrl;
    _cvUrl = profile.cvUrl;
  }

  String _profileErrorMessage(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
        case 'unauthorized':
          return 'Aplikasi belum punya izin menyimpan profil di Firebase.';
        case 'network-request-failed':
        case 'unavailable':
          return 'Koneksi ke Firebase bermasalah. Coba lagi saat internet stabil.';
      }
    }

    return 'Terjadi kesalahan saat menyimpan profil. Coba lagi.';
  }

  Future<void> _pickPhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 1200,
    );
    if (image == null || !mounted) return;
    setState(() {
      _selectedPhoto = File(image.path);
    });
  }

  Future<void> _pickCv() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 86,
      maxWidth: 1600,
    );
    if (image == null || !mounted) return;
    setState(() {
      _selectedCv = File(image.path);
    });
  }

  Future<void> _submitProfile() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      var photoUrl = _photoUrl;
      var cvUrl = _cvUrl;
      var uploadWarning = false;

      if (_selectedPhoto != null) {
        try {
          photoUrl = await StorageService.uploadProfilePhoto(
            uid: widget.uid,
            file: _selectedPhoto!,
          );
        } catch (_) {
          uploadWarning = true;
        }
      }
      if (_selectedCv != null) {
        try {
          cvUrl = await StorageService.uploadCv(
            uid: widget.uid,
            file: _selectedCv!,
          );
        } catch (_) {
          uploadWarning = true;
        }
      }

      final profileData = <String, dynamic>{
        'uid': widget.uid,
        'email': widget.email,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'nik': _nikController.text.trim(),
        'photoUrl': photoUrl,
        'cvUrl': cvUrl,
        'publicBio': _bioController.text.trim(),
        'isVerified': false,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!_hasExistingProfile) {
        profileData['createdAt'] = FieldValue.serverTimestamp();
      }

      await FirestoreService.createUserProfile(widget.uid, profileData);

      if (!mounted) return;
      if (uploadWarning) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profil tersimpan, tapi foto/CV belum terunggah. Cek Firebase Storage besok.',
            ),
          ),
        );
      }
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _profileErrorMessage(error);
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
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nikController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Lengkapi Profil'), elevation: 0),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    Text(
                      'Profil LineWork',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Data privat tetap disembunyikan dari profil publik.',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _PhotoPicker(
                      photoUrl: _photoUrl,
                      selectedPhoto: _selectedPhoto,
                      onPick: _pickPhoto,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama lengkap',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Nama wajib diisi.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Nomor WhatsApp',
                        prefixIcon: Icon(Icons.phone_iphone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Nomor WhatsApp wajib diisi.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nikController,
                      decoration: const InputDecoration(
                        labelText: 'NIK',
                        prefixIcon: Icon(Icons.credit_card_outlined),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'NIK wajib diisi.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Bio publik',
                        hintText: 'Ceritakan kemampuan atau area layanan kamu.',
                        prefixIcon: Icon(Icons.notes_outlined),
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _CvPicker(
                      hasCv: _cvUrl != null || _selectedCv != null,
                      onPick: _pickCv,
                    ),
                    const SizedBox(height: 16),
                    const _PrivacyNotice(),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 14),
                      _ErrorBanner(message: _errorMessage!),
                    ],
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _submitProfile,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Profil'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brandColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFB7C7D8),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
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

class _PhotoPicker extends StatelessWidget {
  final String? photoUrl;
  final File? selectedPhoto;
  final VoidCallback onPick;

  const _PhotoPicker({
    required this.photoUrl,
    required this.selectedPhoto,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageProvider = selectedPhoto != null
        ? FileImage(selectedPhoto!)
        : photoUrl != null && photoUrl!.isNotEmpty
        ? NetworkImage(photoUrl!) as ImageProvider
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: colorScheme.primaryContainer,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Icon(
                    Icons.person_outline,
                    color: colorScheme.onPrimaryContainer,
                    size: 34,
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Foto profil',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Foto ini tampil di profil publik.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit foto',
            onPressed: onPick,
            style: IconButton.styleFrom(
              backgroundColor: _brandColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.photo_camera_outlined),
          ),
        ],
      ),
    );
  }
}

class _CvPicker extends StatelessWidget {
  final bool hasCv;
  final VoidCallback onPick;

  const _CvPicker({required this.hasCv, required this.onPick});

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
      child: Row(
        children: [
          Icon(
            hasCv ? Icons.verified_outlined : Icons.description_outlined,
            color: hasCv ? const Color(0xFF15803D) : colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasCv ? 'CV sudah dipilih' : 'Upload CV',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Saat ini memakai gambar CV/portofolio dari galeri.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onPick,
            icon: Icon(hasCv ? Icons.refresh : Icons.upload_file),
            label: Text(hasCv ? 'Ganti' : 'Pilih'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _brandColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.privacy_tip_outlined, color: Color(0xFF075985), size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Profil publik hanya menampilkan nama, foto, bio, status verifikasi, dan CV. NIK, nomor HP, dan email disembunyikan.',
              style: TextStyle(
                color: Color(0xFF075985),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
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
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF991B1B),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
