import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';

/// Result of the "share feedback" form.
class NewComplaint {
  const NewComplaint({
    required this.title,
    required this.description,
    required this.category,
  });

  final String title;
  final String description;
  final String category;
}

/// Modal to file a complaint / share feedback.
class CreateComplaintSheet extends StatefulWidget {
  const CreateComplaintSheet({super.key});

  static Future<NewComplaint?> show(BuildContext context) {
    return showModalBottomSheet<NewComplaint>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const CreateComplaintSheet(),
    );
  }

  @override
  State<CreateComplaintSheet> createState() => _CreateComplaintSheetState();
}

class _CreateComplaintSheetState extends State<CreateComplaintSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  String _category = 'academics';

  static const _categories = [
    'academics',
    'facilities',
    'hostel',
    'cafeteria',
    'other',
  ];

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(NewComplaint(
      title: _title.text.trim(),
      description: _description.text.trim(),
      category: _category,
    ));
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
                'Share feedback',
                style: AppTypography.inter(
                  size: AppTypography.lg,
                  weight: AppTypography.bold,
                  color: surfaces.primaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Help us improve your campus experience.',
                style: AppTypography.inter(
                  size: AppTypography.sm,
                  color: surfaces.secondaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Category',
                  style: AppTypography.inter(
                    size: AppTypography.sm,
                    weight: AppTypography.medium,
                    color: surfaces.secondaryText,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final c in _categories)
                    ChoiceChip(
                      label: Text(c),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _title,
                label: 'Subject',
                hint: 'Brief title',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Subject required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _description,
                label: 'Your message',
                hint: "Tell us what's on your mind…",
                maxLines: 4,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Message required' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Submit feedback',
                expand: true,
                icon: Icons.send,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
