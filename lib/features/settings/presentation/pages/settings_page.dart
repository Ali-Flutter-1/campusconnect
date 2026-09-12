import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../injection.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../profile/presentation/widgets/edit_profile_sheet.dart';
import '../widgets/settings_section.dart';

/// App settings. Every row here is backed by something the app actually does —
/// the outbox, the Hive cache, the session — rather than toggles with nothing
/// behind them.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _sync = getIt<SyncService>();
  final _cache = getIt<CacheService>();
  bool _flushing = false;

  Future<void> _retryPending() async {
    if (_flushing) return;
    setState(() => _flushing = true);
    await _sync.processPending();
    if (!mounted) return;
    final left = _sync.pendingAll.length;
    setState(() => _flushing = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(
          left == 0
              ? 'Everything is uploaded.'
              : '$left item${left == 1 ? '' : 's'} still waiting — check your '
                  'connection.',
        ),
      ));
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cached data?'),
        content: const Text(
          'Removes the offline copies of announcements, events, notices and '
          'complaints. Nothing you have posted is deleted, and anything still '
          'waiting to upload is kept. Screens will reload next time you open '
          'them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) return;
    await _cache.clear();
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Cached data cleared.')));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthBloc, AppUser?>((b) => b.state.user);
    final isAdmin = context.select<AuthBloc, bool>((b) => b.state.isAdmin);
    final pending = _sync.pendingAll.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            SettingsSection(
              title: 'Account',
              children: [
                SettingsRow(
                  icon: LucideIcons.userCog,
                  label: 'Edit profile',
                  subtitle: 'Name, photo, course and department',
                  onTap: () => EditProfileSheet.show(context),
                ),
                SettingsRow(
                  icon: LucideIcons.mail,
                  label: 'Signed in as',
                  subtitle: user?.email ?? '—',
                  value: isAdmin ? 'Admin' : 'Student',
                ),
                SettingsRow(
                  icon: LucideIcons.clipboardList,
                  label: 'My requests',
                  subtitle: 'Complaints and requests you have filed',
                  onTap: () => context.push(AppRoutes.complaints),
                ),
              ],
            ),
            SettingsSection(
              title: 'Offline & storage',
              footnote:
                  'Messages and requests you create without a connection are '
                  'queued on this device and sent automatically once you are '
                  'back online.',
              children: [
                SettingsRow(
                  icon: LucideIcons.uploadCloud,
                  label: 'Waiting to upload',
                  subtitle: pending == 0
                      ? 'Everything is synced'
                      : '$pending item${pending == 1 ? '' : 's'} queued',
                  trailing: _flushing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                  // Nothing queued means nothing to retry.
                  onTap: pending == 0 || _flushing ? null : _retryPending,
                ),
                SettingsRow(
                  icon: LucideIcons.database,
                  label: 'Cached data',
                  subtitle: _cache.entryCount == 0
                      ? 'No offline copies stored'
                      : '${_cache.entryCount} cached list'
                          '${_cache.entryCount == 1 ? '' : 's'}',
                  onTap: _cache.entryCount == 0 ? null : _clearCache,
                ),
              ],
            ),
            SettingsSection(
              title: 'Support',
              children: [
                SettingsRow(
                  icon: LucideIcons.shield,
                  label: 'Privacy',
                  subtitle: 'What the app stores and who can see it',
                  onTap: () => context.push(AppRoutes.privacy),
                ),
                SettingsRow(
                  icon: LucideIcons.helpCircle,
                  label: 'Help & support',
                  subtitle: 'Answers, troubleshooting and contact',
                  onTap: () => context.push(AppRoutes.help),
                ),
              ],
            ),
            SettingsSection(
              title: 'About',
              children: [
                const SettingsRow(
                  icon: LucideIcons.info,
                  label: 'CampusConnect',
                  subtitle: 'Your campus community, in one app',
                  value: 'v${AppConstants.appVersion}',
                ),
                SettingsRow(
                  icon: LucideIcons.logOut,
                  label: 'Sign out',
                  destructive: true,
                  onTap: () => _confirmSignOut(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final bloc = context.read<AuthBloc>();
    final pending = _sync.pendingAll.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        // Warn rather than silently stranding queued work on the device.
        content: Text(
          pending == 0
              ? 'You can sign back in at any time.'
              : '$pending item${pending == 1 ? '' : 's'} still waiting to '
                  'upload will stay on this device until you sign back in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) bloc.add(const AuthSignOutRequested());
  }
}
