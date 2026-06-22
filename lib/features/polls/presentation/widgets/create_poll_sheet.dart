import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Result of the admin "new poll" form.
class NewPoll {
  const NewPoll({required this.question, required this.options});
  final String question;
  final List<String> options;
}

/// Admin-only modal to create a poll: a question plus 2–5 options.
class CreatePollSheet extends StatefulWidget {
  const CreatePollSheet({super.key});

  static Future<NewPoll?> show(BuildContext context) {
    return showModalBottomSheet<NewPoll>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const CreatePollSheet(),
    );
  }

  @override
  State<CreatePollSheet> createState() => _CreatePollSheetState();
}

class _CreatePollSheetState extends State<CreatePollSheet> {
  final _formKey = GlobalKey<FormState>();
  final _question = TextEditingController();
  final List<TextEditingController> _options = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    _question.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_options.length >= 5) return;
    setState(() => _options.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_options.length <= 2) return;
    setState(() {
      _options.removeAt(index).dispose();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final options = _options
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    if (options.length < 2) return;
    Navigator.of(context).pop(
      NewPoll(question: _question.text.trim(), options: options),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'New poll',
                style: AppTypography.inter(
                  size: AppTypography.lg,
                  weight: AppTypography.bold,
                  color: surfaces.primaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _question,
                label: 'Question',
                hint: 'What should we vote on?',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Question required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Options',
                style: AppTypography.inter(
                  size: AppTypography.sm,
                  weight: AppTypography.medium,
                  color: surfaces.secondaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              for (var i = 0; i < _options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _options[i],
                          hint: 'Option ${i + 1}',
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                      if (_options.length > 2)
                        IconButton(
                          icon: Icon(LucideIcons.x,
                              size: 18, color: surfaces.secondaryText),
                          onPressed: () => _removeOption(i),
                        ),
                    ],
                  ),
                ),
              if (_options.length < 5)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addOption,
                    icon: Icon(LucideIcons.plus,
                        size: 16, color: AppColors.primary.s400),
                    label: Text(
                      'Add option',
                      style: AppTypography.inter(
                        size: AppTypography.sm,
                        weight: AppTypography.medium,
                        color: AppColors.primary.s400,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              AppButton(label: 'Create poll', expand: true, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
