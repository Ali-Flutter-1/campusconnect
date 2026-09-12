import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../injection.dart';
import '../widgets/settings_section.dart';

/// Plain-language account of what the app stores and who can see it.
///
/// Everything stated here matches the database's row-level security policies —
/// if those change, this screen has to change with them.
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Text(
                'CampusConnect keeps only what it needs to run the campus '
                'feed, chat and requests. Here is exactly what that means.',
                style: AppTypography.inter(
                  size: AppTypography.base,
                  color: surfaces.secondaryText,
                  height: 1.5,
                ),
              ),
            ),
            const SettingsSection(
              title: 'What we store',
              children: [
                SettingsRow(
                  icon: LucideIcons.user,
                  label: 'Your profile',
                  subtitle: 'Name, email, course, department, year and photo.',
                ),
                SettingsRow(
                  icon: LucideIcons.messageSquare,
                  label: 'Chat messages',
                  subtitle:
                      'What you post, when you posted it, and any edits or '
                      'reactions.',
                ),
                SettingsRow(
                  icon: LucideIcons.clipboardList,
                  label: 'Requests & complaints',
                  subtitle:
                      'The title, description, category and status of anything '
                      'you file.',
                ),
                SettingsRow(
                  icon: LucideIcons.barChart3,
                  label: 'Poll votes',
                  subtitle:
                      'Which option you chose, stored against your account so '
                      'you cannot vote twice.',
                ),
              ],
            ),
            const SettingsSection(
              title: 'Who can see it',
              footnote:
                  'These rules are enforced by the database itself, not just by '
                  'the app, so they hold even outside CampusConnect.',
              children: [
                SettingsRow(
                  icon: LucideIcons.users,
                  label: 'Everyone signed in',
                  subtitle:
                      'Your chat messages, and the name and photo shown beside '
                      'them.',
                ),
                SettingsRow(
                  icon: LucideIcons.shieldCheck,
                  label: 'You and administrators',
                  subtitle:
                      'Your full profile, and the requests and complaints you '
                      'file.',
                ),
                SettingsRow(
                  icon: LucideIcons.lock,
                  label: 'Only you',
                  subtitle:
                      'Your password — it is handled by the sign-in provider '
                      'and never visible to the app or to admins.',
                ),
              ],
            ),
            SettingsSection(
              title: 'Things worth knowing',
              children: [
                const SettingsRow(
                  icon: LucideIcons.imageOff,
                  label: 'Profile photos have public links',
                  subtitle:
                      'Photos sit in a public media bucket so they load fast. '
                      'Anyone holding the exact link can open it, even signed '
                      'out. Avoid uploading anything sensitive.',
                ),
                const SettingsRow(
                  icon: LucideIcons.history,
                  label: 'Deleted messages leave a trace',
                  subtitle:
                      'Deleting a message hides its text for everyone, but the '
                      'entry stays so replies to it still make sense.',
                ),
                SettingsRow(
                  icon: LucideIcons.smartphone,
                  label: 'Offline copies on this device',
                  subtitle:
                      'Recent lists are cached locally so the app works '
                      'without a connection. Clear them any time from '
                      'Settings → Cached data.',
                  onTap: () => _clearCache(context),
                ),
              ],
            ),
            SettingsSection(
              title: 'Your choices',
              children: [
                SettingsRow(
                  icon: LucideIcons.userX,
                  label: 'Request account deletion',
                  subtitle:
                      'Emails campus support to have your account and its data '
                      'removed.',
                  onTap: () => _email(
                    context,
                    subject: 'CampusConnect account deletion request',
                    body: 'Please delete my CampusConnect account and the data '
                        'associated with it.\n\n(Sent from the app.)',
                  ),
                ),
                SettingsRow(
                  icon: LucideIcons.mail,
                  label: 'Ask a privacy question',
                  subtitle: AppConstants.supportEmail,
                  onTap: () => _email(
                    context,
                    subject: 'CampusConnect privacy question',
                    body: '',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearCache(BuildContext context) async {
    await getIt<CacheService>().clear();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Cached data cleared.')));
  }
}

/// Opens the device mail composer, telling the user plainly when no mail app is
/// configured rather than failing silently.
Future<void> _email(
  BuildContext context, {
  required String subject,
  required String body,
}) async {
  final uri = Uri(
    scheme: 'mailto',
    path: AppConstants.supportEmail,
    query: 'subject=${Uri.encodeComponent(subject)}'
        '&body=${Uri.encodeComponent(body)}',
  );
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication)
      .catchError((_) => false);
  if (opened || !context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('No mail app found. Write to ${AppConstants.supportEmail}'),
    ));
}
