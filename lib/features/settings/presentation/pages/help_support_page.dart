import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../widgets/settings_section.dart';

class _Faq {
  const _Faq(this.question, this.answer);
  final String question;
  final String answer;
}

/// Answers describe what this app actually does — offline sending, message
/// editing, complaint states — rather than generic filler.
const _faqs = <_Faq>[
  _Faq(
    'My message shows a clock icon. What does that mean?',
    'It was written while you were offline or the network dropped, so it is '
        'queued on your device. It sends by itself once you are back online '
        'and the clock disappears. Queued messages survive closing the app.',
  ),
  _Faq(
    'A message says "Failed — tap to retry".',
    'The send was rejected rather than delayed. Tap the message to queue it '
        'again. If it keeps failing, check that you are still signed in.',
  ),
  _Faq(
    'Can I edit or delete something I sent?',
    'Yes. Press and hold your message, then choose Edit or Delete. Edited '
        'messages are marked "edited" so the conversation stays honest, and '
        'deleting hides the text for everyone.',
  ),
  _Faq(
    'How do I react to a message?',
    'Press and hold any message and pick an emoji from the row, or tap "+" '
        'for the full list. Tap a reaction again to take it back.',
  ),
  _Faq(
    'How do I reply to a specific message?',
    'Press and hold it and choose Reply. Your message appears with a quote of '
        'theirs above it.',
  ),
  _Faq(
    'How do I change my profile photo?',
    'Open Profile and tap your picture. You can take a new photo or pick one '
        'from your gallery. The photo uploads when you save your profile.',
  ),
  _Faq(
    'What happens after I file a request?',
    'It starts as Open. An administrator reviews it and moves it to In '
        'progress and then Resolved. You can follow it under Profile → My '
        'requests.',
  ),
  _Faq(
    'Why can I not see the admin screens?',
    'Dashboard and Approvals are only for accounts with the administrator '
        'role. If you should have that access, contact campus support.',
  ),
  _Faq(
    'The app looks out of date.',
    'Lists are cached so they open instantly offline. Pull down to refresh, '
        'or clear the cache under Settings → Cached data.',
  ),
];

/// Help centre: a connection check, FAQs about this app's behaviour, and ways
/// to reach a person.
class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final isAdmin = context.select<AuthBloc, bool>((b) => b.state.isAdmin);

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            SettingsSection(
              title: 'Get help',
              children: [
                // Filing a complaint is a real, tracked channel — better than
                // an email that lands nowhere.
                if (!isAdmin)
                  SettingsRow(
                    icon: LucideIcons.clipboardList,
                    label: 'Report a problem',
                    subtitle:
                        'Files a tracked request you can follow to resolution',
                    onTap: () => context.push(AppRoutes.complaints),
                  ),
                SettingsRow(
                  icon: LucideIcons.mail,
                  label: 'Email support',
                  subtitle: AppConstants.supportEmail,
                  onTap: () => _emailSupport(context),
                ),
                const _ConnectionRow(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.xs,
                bottom: AppSpacing.sm,
              ),
              child: Text(
                'COMMON QUESTIONS',
                style: AppTypography.inter(
                  size: AppTypography.xs,
                  weight: AppTypography.semiBold,
                  color: surfaces.secondaryText,
                ).copyWith(letterSpacing: 0.8),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: surfaces.cardBackground,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: surfaces.cardBorder),
              ),
              child: Theme(
                // Hide the default ExpansionTile divider lines; the card and
                // our own dividers already provide the structure.
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: Column(
                  children: [
                    for (var i = 0; i < _faqs.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          indent: AppSpacing.md,
                          color: surfaces.divider,
                        ),
                      ExpansionTile(
                        title: Text(
                          _faqs[i].question,
                          style: AppTypography.inter(
                            size: AppTypography.base,
                            weight: AppTypography.medium,
                            color: surfaces.primaryText,
                          ),
                        ),
                        iconColor: surfaces.accentText,
                        collapsedIconColor: surfaces.secondaryText,
                        childrenPadding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          AppSpacing.md,
                        ),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _faqs[i].answer,
                            style: AppTypography.inter(
                              size: AppTypography.base,
                              color: surfaces.secondaryText,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SettingsSection(
              title: 'About',
              footnote: 'Include the version above when you contact support — '
                  'it helps us reproduce what you saw.',
              children: [
                const SettingsRow(
                  icon: LucideIcons.info,
                  label: 'App version',
                  value: 'v${AppConstants.appVersion}',
                ),
                SettingsRow(
                  icon: LucideIcons.shield,
                  label: 'Privacy',
                  onTap: () => context.push(AppRoutes.privacy),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Live connectivity check — the first thing to rule out when something in the
/// app is not loading.
class _ConnectionRow extends StatefulWidget {
  const _ConnectionRow();

  @override
  State<_ConnectionRow> createState() => _ConnectionRowState();
}

class _ConnectionRowState extends State<_ConnectionRow> {
  bool _checking = false;
  bool? _online;

  Future<void> _check() async {
    setState(() => _checking = true);
    final online = await getIt<NetworkInfo>().isConnected;
    if (!mounted) return;
    setState(() {
      _checking = false;
      _online = online;
    });
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return SettingsRow(
      icon: LucideIcons.wifi,
      label: 'Check connection',
      subtitle: switch (_online) {
        null => 'Confirm the app can reach the campus server',
        true => 'Connected — the app can reach the server',
        false => 'No connection. Your work is saved and will sync later.',
      },
      trailing: _checking
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : (_online == null
              ? null
              : Icon(
                  _online! ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
                  size: 18,
                  color:
                      _online! ? surfaces.successText : surfaces.dangerText,
                )),
      onTap: _checking ? null : _check,
    );
  }
}

Future<void> _emailSupport(BuildContext context) async {
  final uri = Uri(
    scheme: 'mailto',
    path: AppConstants.supportEmail,
    query: 'subject=${Uri.encodeComponent('CampusConnect support')}'
        '&body=${Uri.encodeComponent('\n\n---\nApp version: '
            '${AppConstants.appVersion}')}',
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
