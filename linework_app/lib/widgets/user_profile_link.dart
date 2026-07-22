import 'package:flutter/material.dart';
import 'package:linework_app/models/user_profile.dart';
import 'package:linework_app/services/firestore_service.dart';

class UserProfileLink extends StatelessWidget {
  final String userId;
  final String label;
  final bool compact;

  const UserProfileLink({
    required this.userId,
    required this.label,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (userId.isEmpty) {
      return _UserLine(
        label: label,
        name: 'User belum tersedia',
        subtitle: '-',
        compact: compact,
        onTap: null,
      );
    }

    return StreamBuilder<UserProfile?>(
      stream: FirestoreService.streamPublicUserProfile(userId),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final displayName = _displayName(profile, userId);
        final subtitle = profile?.publicBio?.trim().isNotEmpty == true
            ? profile!.publicBio!.trim()
            : profile?.isVerified == true
            ? 'Terverifikasi'
            : 'Profil publik';

        return _UserLine(
          label: label,
          name: snapshot.connectionState == ConnectionState.waiting
              ? 'Memuat user...'
              : displayName,
          subtitle: subtitle,
          photoUrl: profile?.photoUrl,
          compact: compact,
          onTap: snapshot.connectionState == ConnectionState.waiting
              ? null
              : () => showUserProfileSheet(context, userId, profile),
          trailing: Icon(
            Icons.chevron_right,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
        );
      },
    );
  }
}

class UserNameTextButton extends StatelessWidget {
  final String userId;
  final String fallbackLabel;

  const UserNameTextButton({
    required this.userId,
    this.fallbackLabel = 'User LineWork',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<UserProfile?>(
      stream: FirestoreService.streamPublicUserProfile(userId),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final name = snapshot.connectionState == ConnectionState.waiting
            ? 'Memuat user...'
            : _displayName(profile, userId, fallbackLabel: fallbackLabel);

        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: snapshot.connectionState == ConnectionState.waiting
              ? null
              : () => showUserProfileSheet(context, userId, profile),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 3),
                Icon(Icons.open_in_new, size: 13, color: colorScheme.primary),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> showUserProfileSheet(
  BuildContext context,
  String userId,
  UserProfile? initialProfile,
) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return StreamBuilder<UserProfile?>(
        stream: FirestoreService.streamPublicUserProfile(userId),
        initialData: initialProfile,
        builder: (context, snapshot) {
          final profile = snapshot.data;
          return _UserProfileSheet(userId: userId, profile: profile);
        },
      );
    },
  );
}

class _UserLine extends StatelessWidget {
  final String label;
  final String name;
  final String subtitle;
  final String? photoUrl;
  final bool compact;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _UserLine({
    required this.label,
    required this.name,
    required this.subtitle,
    this.photoUrl,
    required this.compact,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 6 : 8),
          child: Row(
            children: [
              _UserAvatar(photoUrl: photoUrl, radius: compact ? 17 : 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: compact ? 13 : 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }
}

class _UserProfileSheet extends StatelessWidget {
  final String userId;
  final UserProfile? profile;

  const _UserProfileSheet({required this.userId, required this.profile});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final name = _displayName(profile, userId);
    final bio = profile?.publicBio?.trim().isNotEmpty == true
        ? profile!.publicBio!.trim()
        : 'User ini belum menulis bio publik.';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _UserAvatar(photoUrl: profile?.photoUrl, radius: 34),
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
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _VerificationPill(
                        isVerified: profile?.isVerified ?? false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Bio publik',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              bio,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ProfileChip(
                  icon: profile?.cvUrl == null
                      ? Icons.description_outlined
                      : Icons.task_alt,
                  label: profile?.cvUrl == null ? 'CV belum ada' : 'CV ada',
                ),
                _ProfileChip(
                  icon: Icons.visibility_off_outlined,
                  label: 'Kontak privat',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final double radius;

  const _UserAvatar({required this.photoUrl, required this.radius});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;

    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primaryContainer,
      backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
      child: hasPhoto
          ? null
          : Icon(
              Icons.person_outline,
              color: colorScheme.onPrimaryContainer,
              size: radius,
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

class _ProfileChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProfileChip({required this.icon, required this.label});

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

String _displayName(
  UserProfile? profile,
  String userId, {
  String fallbackLabel = 'User LineWork',
}) {
  final name = profile?.name?.trim();
  if (name != null && name.isNotEmpty) return name;
  if (userId.length >= 6) return '$fallbackLabel ${userId.substring(0, 6)}';
  return fallbackLabel;
}
