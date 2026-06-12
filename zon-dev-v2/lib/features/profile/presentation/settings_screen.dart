import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/photos/photo_service.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/privacy_repository.dart';
import '../../../data/repositories/location_sharing_repository.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _usernameCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  String? _avatarUrl;
  bool _isPrivate = false;
  bool _isGhostMode = false;
  UserPrivacy _privacy = const UserPrivacy();
  bool _loading = true;
  bool _savingProfile = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _displayNameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final locRepo = ref.read(locationSharingRepositoryProvider);
    final (profileRes, privacyRes, ghostMode) = await (
      ref.read(profileRepositoryProvider).getMyProfile(),
      ref.read(privacyRepositoryProvider).getMyPrivacy(),
      locRepo.getGhostMode(),
    ).wait;
    profileRes.fold(
      (e) => debugPrint('[Settings] profile load error: ${e.message}'),
      (p) {
        _usernameCtrl.text = p.username;
        _displayNameCtrl.text = p.displayName ?? '';
        _bioCtrl.text = p.bio ?? '';
        _avatarUrl = p.avatarUrl;
        _isPrivate = p.isPrivate;
      },
    );
    privacyRes.fold(
      (e) => debugPrint('[Settings] privacy load error: ${e.message}'),
      (pr) => _privacy = pr,
    );
    if (mounted) {
      setState(() {
        _isGhostMode = ghostMode;
        _loading = false;
      });
    }
  }

  Future<void> _pickAvatar() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final url = await PhotoService().uploadFile(File(picked.path), bucket: 'avatars');
    if (url == null) return;
    await ref.read(profileRepositoryProvider).updateProfile({'avatar_url': url});
    if (mounted) setState(() => _avatarUrl = url);
  }

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    final res = await ref.read(profileRepositoryProvider).updateProfile({
      'username': _usernameCtrl.text.trim(),
      'display_name': _displayNameCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
    });
    if (mounted) {
      setState(() => _savingProfile = false);
      res.fold(
        (e) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${e.message}'))),
        (_) => ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile saved'))),
      );
    }
  }

  Future<void> _updatePrivacy(Map<String, dynamic> updates, UserPrivacy next) async {
    setState(() => _privacy = next);
    await ref.read(privacyRepositoryProvider).update(updates);
  }

  Future<void> _setPrivateAccount(bool v) async {
    setState(() => _isPrivate = v);
    await ref.read(profileRepositoryProvider).updateProfile({'is_private': v});
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'This permanently deletes your account and all your data. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Supabase.instance.client.functions.invoke('delete-account');
      await Supabase.instance.client.auth.signOut();
      // authStateStream → GoRouter redirects to /login.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: Z.brand)));
    }

    final sections = [
      _Section('PROFILE', [
        _Row(icon: Icons.person, label: 'Edit name & bio',
            onTap: _showEditProfile),
        _Row(icon: Icons.photo_camera, label: 'Change avatar',
            avatarUrl: _avatarUrl,
            onTap: _pickAvatar),
      ]),
      _Section('PRIVACY', [
        _Row(icon: Icons.lock, label: 'Private account',
            sub: 'New followers must be approved',
            toggle: true, toggleValue: _isPrivate,
            onToggle: _setPrivateAccount),
        _Row(
          icon: Icons.lock,
          label: 'Default stamp visibility',
          customTrailing: SegmentedButton<StampVisibility>(
            segments: const [
              ButtonSegment(
                value: StampVisibility.private,
                icon: Icon(Icons.lock, size: 16),
              ),
              ButtonSegment(
                value: StampVisibility.public,
                icon: Icon(Icons.public, size: 16),
              ),
            ],
            selected: {_privacy.defaultStampVisibility},
            onSelectionChanged: (s) => _updatePrivacy(
              {'default_stamp_visibility': s.first.name},
              _privacy.copyWith(defaultStampVisibility: s.first),
            ),
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        _Row(
          icon: Icons.map,
          label: 'Share my trail on the map',
          sub: 'Let friends see your check-ins & route today',
          toggle: true,
          toggleValue: _privacy.locationSharingEnabled,
          onToggle: (v) => _updatePrivacy(
            {'location_sharing_enabled': v},
            _privacy.copyWith(locationSharingEnabled: v),
          ),
        ),
        _Row(
          icon: Icons.track_changes,
          label: 'Significant-change tracking',
          sub: 'Track location in the background',
          toggle: true,
          toggleValue: _privacy.significantChangeEnabled,
          onToggle: (v) => _updatePrivacy(
            {'significant_change_enabled': v},
            _privacy.copyWith(significantChangeEnabled: v),
          ),
        ),
        _Row(icon: Icons.visibility_off, label: 'Ghost mode',
            sub: 'Hide your live location from friends',
            toggle: true, toggleValue: _isGhostMode,
            onToggle: (v) async {
              setState(() => _isGhostMode = v);
              await ref.read(locationSharingRepositoryProvider).setGhostMode(v);
              ref.invalidate(ghostModeProvider);
            }),
        _Row(icon: Icons.people, label: 'Location visibility',
            sub: 'Choose who can see you', arrow: true,
            onTap: _isGhostMode ? null : () => context.push('/location-visibility'),
            enabled: !_isGhostMode),
        _Row(icon: Icons.shield_outlined, label: 'Data & Privacy',
            sub: 'Control how your data is used & shared', arrow: true,
            onTap: () => context.push('/data-privacy')),
      ]),
      _Section('NOTIFICATIONS', [
        _Row(icon: Icons.favorite, label: 'Likes',
            toggle: true, toggleValue: _privacy.notifyLikes,
            onToggle: (v) => _updatePrivacy(
                {'notify_likes': v},
                _privacy.copyWith(notifyLikes: v))),
        _Row(icon: Icons.chat_bubble, label: 'Comments & mentions',
            toggle: true, toggleValue: _privacy.notifyComments,
            onToggle: (v) => _updatePrivacy(
                {'notify_comments': v},
                _privacy.copyWith(notifyComments: v))),
        _Row(icon: Icons.person_add, label: 'Friend requests',
            toggle: true, toggleValue: _privacy.notifyFriendRequests,
            onToggle: (v) => _updatePrivacy(
                {'notify_friend_requests': v},
                _privacy.copyWith(notifyFriendRequests: v))),
        _Row(icon: Icons.photo_camera, label: 'Photo check-in suggestions',
            toggle: true, toggleValue: _privacy.photoAutoSuggest,
            onToggle: (v) => _updatePrivacy(
                {'photo_auto_suggest': v},
                _privacy.copyWith(photoAutoSuggest: v))),
        _Row(
          icon: Icons.brightness_2,
          label: 'Evening summary',
          sub: 'Daily recap notification in the evening',
          toggle: true,
          toggleValue: _privacy.eveningSummaryEnabled,
          onToggle: (v) => _updatePrivacy(
            {'evening_summary_enabled': v},
            _privacy.copyWith(eveningSummaryEnabled: v),
          ),
        ),
      ]),
      _Section('ACCOUNT', [
        _Row(icon: Icons.logout, label: 'Sign out', arrow: true,
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
            }),
        _Row(icon: Icons.delete, label: 'Delete account',
            arrow: true, destructive: true, onTap: _deleteAccount),
      ]),
    ];

    return Scaffold(
      backgroundColor: Z.surface0,
      body: Column(
        children: [
          // Header
          Container(
            color: Z.surface1,
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 4, 16, 12),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back,
                              size: 24, color: Z.text),
                        ),
                        const SizedBox(width: 4),
                        const Text('Settings',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Z.text)),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Z.outline),
                ],
              ),
            ),
          ),
          // Sections
          Expanded(
            child: ListView(
              children: [
                for (final sec in sections) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                    child: Text(sec.title,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Z.textMuted,
                            letterSpacing: 0.6)),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Z.surface1,
                      border: Border.symmetric(
                          horizontal: BorderSide(color: Z.outline)),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < sec.rows.length; i++) ...[
                          _buildRow(sec.rows[i]),
                          if (i < sec.rows.length - 1)
                            const Padding(
                              padding: EdgeInsets.only(left: 62),
                              child: Divider(height: 1, color: Z.outline),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text('ZON v2.0 · Made in Seoul',
                        style: TextStyle(fontSize: 12, color: Z.textFaint)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(_Row r) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: r.enabled == false
            ? null
            : (r.toggle
                ? () => r.onToggle?.call(!(r.toggleValue ?? false))
                : r.onTap),
        child: Opacity(
          opacity: r.enabled == false ? 0.45 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                // Icon badge
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: r.destructive
                        ? const Color(0x1AEF4444)
                        : Z.brandSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: r.avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: r.avatarUrl!,
                          fit: BoxFit.cover,
                        )
                      : Icon(r.icon,
                          size: 18,
                          color: r.destructive ? Z.error : Z.brand),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.label,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: r.destructive ? Z.error : Z.text)),
                      if (r.sub != null)
                        Text(r.sub!,
                            style: const TextStyle(
                                fontSize: 12, color: Z.textMuted)),
                    ],
                  ),
                ),
                if (r.toggle)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 48,
                    height: 28,
                    decoration: BoxDecoration(
                      color: (r.toggleValue ?? false) ? Z.brand : Z.surface3,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      alignment: (r.toggleValue ?? false)
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Color(0x2E000000), blurRadius: 4)
                          ],
                        ),
                      ),
                    ),
                  )
                else if (r.customTrailing != null)
                  r.customTrailing!
                else if (r.arrow)
                  const Icon(Icons.chevron_right,
                      size: 20, color: Z.textFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditProfile() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Z.surface1,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Profile',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Z.text)),
              const SizedBox(height: 16),
              TextField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _displayNameCtrl,
                decoration:
                    const InputDecoration(labelText: 'Display name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bioCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _savingProfile
                      ? null
                      : () async {
                           await _saveProfile();
                           if (mounted) Navigator.pop(context);
                         },
                  child: _savingProfile
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section {
  final String title;
  final List<_Row> rows;
  const _Section(this.title, this.rows);
}

class _Row {
  final IconData icon;
  final String label;
  final String? sub;
  final bool toggle;
  final bool? toggleValue;
  final void Function(bool)? onToggle;
  final Widget? customTrailing;
  final bool arrow;
  final bool destructive;
  final VoidCallback? onTap;
  final bool? enabled;
  final String? avatarUrl;

  const _Row({
    required this.icon,
    required this.label,
    this.sub,
    this.toggle = false,
    this.toggleValue,
    this.onToggle,
    this.customTrailing,
    this.arrow = false,
    this.destructive = false,
    this.onTap,
    this.enabled,
    this.avatarUrl,
  });
}
