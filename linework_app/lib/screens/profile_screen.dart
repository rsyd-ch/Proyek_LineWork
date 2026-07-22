import 'package:flutter/material.dart';
import 'package:linework_app/models/user_profile.dart';
import 'package:linework_app/screens/profile_setup_screen.dart';
import 'package:linework_app/services/app_settings.dart';
import 'package:linework_app/services/auth_service.dart';
import 'package:linework_app/services/firestore_service.dart';

const _brandColor = Color(0xFF0B4778);
const _dangerColor = Color(0xFFDC2626);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _sendPasswordReset(BuildContext context) async {
    final email = AuthService.currentUser?.email;

    if (email == null || email.isEmpty || email.endsWith('@linework.local')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email akun belum tersedia.')),
      );
      return;
    }

    try {
      await AuthService.sendPasswordResetEmail(email);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Link ubah sandi dikirim ke $email.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengirim link ubah sandi. Coba lagi.'),
        ),
      );
    }
  }

  void _openProfileSetup(BuildContext context) {
    final user = AuthService.currentUser;
    if (user == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ProfileSetupScreen(uid: user.uid, email: user.email ?? ''),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await AuthService.signOut();

    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Akun belum aktif.')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profil'), elevation: 0),
      body: SafeArea(
        child: StreamBuilder<UserProfile?>(
          stream: FirestoreService.streamUserProfile(user.uid),
          builder: (context, snapshot) {
            final profile = snapshot.data;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(minHeight: 3),
                _PublicProfileCard(profile: profile, userEmail: user.email),
                const SizedBox(height: 18),
                const _SectionLabel('Profil Publik'),
                _PublicPreview(profile: profile),
                const SizedBox(height: 18),
                const _SectionLabel('Akun'),
                _SettingsTile(
                  icon: Icons.edit_outlined,
                  title: 'Edit profil',
                  subtitle: 'Foto, nama, bio, NIK, nomor WA, dan CV',
                  onTap: () => _openProfileSetup(context),
                ),
                _SettingsTile(
                  icon: Icons.lock_reset_outlined,
                  title: 'Ubah sandi',
                  subtitle: 'Kirim link reset sandi ke email akun',
                  onTap: () => _sendPasswordReset(context),
                ),
                const SizedBox(height: 18),
                const _SectionLabel('Tampilan'),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: AppSettings.themeMode,
                  builder: (context, themeMode, _) {
                    final isDark = themeMode == ThemeMode.dark;
                    return _SwitchSettingsTile(
                      icon: isDark
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      title: 'Mode malam',
                      subtitle: isDark
                          ? 'Tampilan malam aktif'
                          : 'Mode siang aktif',
                      value: isDark,
                      onChanged: AppSettings.setDarkMode,
                    );
                  },
                ),
                const SizedBox(height: 18),
                const _SectionLabel('Sesi'),
                _SettingsTile(
                  icon: Icons.logout,
                  iconColor: _dangerColor,
                  title: 'Keluar',
                  subtitle: 'Akhiri sesi akun di perangkat ini',
                  onTap: () => _signOut(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PublicProfileCard extends StatelessWidget {
  final UserProfile? profile;
  final String? userEmail;

  const _PublicProfileCard({required this.profile, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = profile?.name?.trim().isNotEmpty == true
        ? profile!.name!
        : 'Profil LineWork';
    final contact = profile?.contactMethod == 'whatsapp'
        ? 'Daftar via WhatsApp'
        : (userEmail?.endsWith('@linework.local') == true
              ? 'Akun aktif'
              : userEmail ?? 'Akun aktif');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: colorScheme.primaryContainer,
            backgroundImage: profile?.photoUrl == null
                ? null
                : NetworkImage(profile!.photoUrl!),
            child: profile?.photoUrl == null
                ? Icon(
                    Icons.person_outline,
                    size: 36,
                    color: colorScheme.onPrimaryContainer,
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contact,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _VerificationPill(isVerified: profile?.isVerified ?? false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PublicPreview extends StatelessWidget {
  final UserProfile? profile;

  const _PublicPreview({required this.profile});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bio = profile?.publicBio?.trim().isNotEmpty == true
        ? profile!.publicBio!
        : 'Belum ada bio publik.';

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
              Icon(Icons.public, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Yang terlihat orang lain',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            bio,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PreviewChip(
                icon: Icons.badge_outlined,
                label: profile?.name?.isNotEmpty == true
                    ? profile!.name!
                    : 'Nama publik',
              ),
              _PreviewChip(
                icon: Icons.description_outlined,
                label: profile?.cvUrl == null ? 'CV belum ada' : 'CV tersedia',
              ),
              const _PreviewChip(
                icon: Icons.visibility_off_outlined,
                label: 'NIK, HP, email tersembunyi',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerificationPill extends StatelessWidget {
  final bool isVerified;

  const _VerificationPill({required this.isVerified});

  @override
  Widget build(BuildContext context) {
    final background = isVerified
        ? const Color(0xFFE7F8EF)
        : const Color(0xFFFFF7ED);
    final foreground = isVerified
        ? const Color(0xFF15803D)
        : const Color(0xFFC2410C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isVerified ? 'Terverifikasi' : 'Belum terverifikasi',
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PreviewChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? _brandColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _SwitchSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchSettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: _brandColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        value: value,
        activeThumbColor: _brandColor,
        onChanged: onChanged,
      ),
    );
  }
}
