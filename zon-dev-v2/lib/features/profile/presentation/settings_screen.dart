import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../core/photos/photo_service.dart';
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
    profileRes.fold((_) {}, (p) {
      _usernameCtrl.text = p.username;
      _displayNameCtrl.text = p.displayName ?? '';
      _bioCtrl.text = p.bio ?? '';
      _isPrivate = p.isPrivate;
    });
    privacyRes.fold((_) {}, (pr) => _privacy = pr);
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
  }

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    await ref.read(profileRepositoryProvider).updateProfile({
      'username': _usernameCtrl.text.trim(),
      'display_name': _displayNameCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
    });
    if (mounted) {
      setState(() => _savingProfile = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile saved')));
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
            onTap: _pickAvatar),
      ]),
      _Section('PRIVACY', [
        _Row(icon: Icons.lock, label: 'Private account',
            sub: 'New followers must be approved',
            toggle: true, toggleValue: _isPrivate,
            onToggle: _setPrivateAccount),
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
      ]),
      _Section('NOTIFICATIONS', [
        _Row(icon: Icons.favorite, label: 'Likes',
            toggle: true, toggleValue: true, onToggle: (_) {}),
        _Row(icon: Icons.chat_bubble, label: 'Comments & mentions',
            toggle: true, toggleValue: true, onToggle: (_) {}),
        _Row(icon: Icons.person_add, label: 'Friend requests',
            toggle: true, toggleValue: true, onToggle: (_) {}),
        _Row(icon: Icons.photo_camera, label: 'Photo check-in suggestions',
            toggle: true, toggleValue: _privacy.photoAutoSuggest,
            onToggle: (v) => _updatePrivacy(
                {'photo_auto_suggest': v},
                _privacy.copyWith(photoAutoSuggest: v))),
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
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const SizedBox(width: 40, height: 40,
                              child: Icon(Icons.arrow_back,
                                  size: 24, color: Z.text)),
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
    return GestureDetector(
      onTap: r.enabled == false ? null : r.onTap,
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
                child: Icon(r.icon,
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
                GestureDetector(
                  onTap: () => r.onToggle?.call(!(r.toggleValue ?? false)),
                  child: AnimatedContainer(
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
                  ),
                )
              else if (r.arrow)
                const Icon(Icons.chevron_right,
                    size: 20, color: Z.textFaint),
            ],
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
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
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
  final bool arrow;
  final bool destructive;
  final VoidCallback? onTap;
  final bool? enabled;

  const _Row({
    required this.icon,
    required this.label,
    this.sub,
    this.toggle = false,
    this.toggleValue,
    this.onToggle,
    this.arrow = false,
    this.destructive = false,
    this.onTap,
    this.enabled,
  });
}
