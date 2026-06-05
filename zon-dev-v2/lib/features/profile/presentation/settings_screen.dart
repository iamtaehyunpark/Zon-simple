import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/photos/photo_service.dart';
import '../../../data/models/enums.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/privacy_repository.dart';

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
    final profileRes = await ref.read(profileRepositoryProvider).getMyProfile();
    final privacyRes = await ref.read(privacyRepositoryProvider).getMyPrivacy();
    profileRes.fold((_) {}, (p) {
      _usernameCtrl.text = p.username;
      _displayNameCtrl.text = p.displayName ?? '';
      _bioCtrl.text = p.bio ?? '';
      _avatarUrl = p.avatarUrl;
      _isPrivate = p.isPrivate;
    });
    privacyRes.fold((_) {}, (pr) => _privacy = pr);
    if (mounted) setState(() => _loading = false);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Edit profile ──────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: CircleAvatar(
                      radius: 44,
                      backgroundImage: _avatarUrl != null
                          ? CachedNetworkImageProvider(_avatarUrl!)
                          : null,
                      child: _avatarUrl == null
                          ? const Icon(Icons.add_a_photo, size: 28)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Username', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _displayNameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Display name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bioCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: 'Bio', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _savingProfile ? null : _saveProfile,
                    child: _savingProfile
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save profile'),
                  ),
                ),

                const Divider(height: 40),

                // ── Privacy & location ────────────────────────
                Text('Privacy & location',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Private account'),
                  subtitle: const Text(
                      'New followers must be approved; only followers see your public posts'),
                  value: _isPrivate,
                  onChanged: _setPrivateAccount,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Default stamp visibility'),
                  trailing: SegmentedButton<StampVisibility>(
                    segments: const [
                      ButtonSegment(
                          value: StampVisibility.private,
                          icon: Icon(Icons.lock)),
                      ButtonSegment(
                          value: StampVisibility.public,
                          icon: Icon(Icons.public)),
                    ],
                    selected: {_privacy.defaultStampVisibility},
                    onSelectionChanged: (s) => _updatePrivacy(
                      {'default_stamp_visibility': s.first.name},
                      _privacy.copyWith(defaultStampVisibility: s.first),
                    ),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Share my location on the map'),
                  subtitle: const Text(
                      'Let people you follow see your check-ins & route today'),
                  value: _privacy.locationSharingEnabled,
                  onChanged: (v) => _updatePrivacy(
                    {'location_sharing_enabled': v},
                    _privacy.copyWith(locationSharingEnabled: v),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Background significant-change tracking'),
                  value: _privacy.significantChangeEnabled,
                  onChanged: (v) => _updatePrivacy(
                    {'significant_change_enabled': v},
                    _privacy.copyWith(significantChangeEnabled: v),
                  ),
                ),

                const Divider(height: 40),

                // ── Notifications ─────────────────────────────
                Text('Notifications',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Suggest check-ins from my photos'),
                  value: _privacy.photoAutoSuggest,
                  onChanged: (v) => _updatePrivacy(
                    {'photo_auto_suggest': v},
                    _privacy.copyWith(photoAutoSuggest: v),
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Evening summary'),
                  value: _privacy.eveningSummaryEnabled,
                  onChanged: (v) => _updatePrivacy(
                    {'evening_summary_enabled': v},
                    _privacy.copyWith(eveningSummaryEnabled: v),
                  ),
                ),

                const Divider(height: 40),

                // ── Account ───────────────────────────────────
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.logout),
                  title: const Text('Sign out'),
                  onTap: () async {
                    await Supabase.instance.client.auth.signOut();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Delete account',
                      style: TextStyle(color: Colors.red)),
                  onTap: _deleteAccount,
                ),
              ],
            ),
    );
  }
}
