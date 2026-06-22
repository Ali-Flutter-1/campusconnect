import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/image_picker_field.dart';
import '../../domain/entities/announcement.dart';

/// The result of the admin "new announcement" form.
class NewAnnouncement {
  const NewAnnouncement({
    required this.title,
    required this.content,
    required this.category,
    this.image,
  });
  final String title;
  final String content;
  final String category;
  final PickedImage? image;
}

/// Admin-only modal sheet to compose an announcement. Returns a
/// [NewAnnouncement] via `Navigator.pop` when submitted.
class CreateAnnouncementSheet extends StatefulWidget {
  const CreateAnnouncementSheet({super.key, this.initial});

  /// When set, the sheet edits an existing announcement instead of creating one.
  final Announcement? initial;

  static Future<NewAnnouncement?> show(
    BuildContext context, {
    Announcement? initial,
  }) {
    return showModalBottomSheet<NewAnnouncement>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CreateAnnouncementSheet(initial: initial),
    );
  }

  @override
  State<CreateAnnouncementSheet> createState() =>
      _CreateAnnouncementSheetState();
}

class _CreateAnnouncementSheetState extends State<CreateAnnouncementSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _title =
      TextEditingController(text: widget.initial?.title ?? '');
  late final _content =
      TextEditingController(text: widget.initial?.content ?? '');
  late String _category = widget.initial?.category ?? 'general';
  PickedImage? _image;

  bool get _isEditing => widget.initial != null;

  static const _categories = ['general', 'academic', 'urgent', 'event'];

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      NewAnnouncement(
        title: _title.text.trim(),
        content: _content.text.trim(),
        category: _category,
        image: _image,
      ),
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
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isEditing ? 'Edit announcement' : 'New announcement',
              style: AppTypography.inter(
                size: AppTypography.lg,
                weight: AppTypography.bold,
                color: surfaces.primaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: _title,
              label: 'Title',
              hint: 'Midterm schedule released',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _content,
              label: 'Content',
              hint: 'Details…',
              maxLines: 3,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Content required' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            // Image upload is only offered when creating (edit keeps the image).
            if (!_isEditing) ...[
              ImagePickerField(onChanged: (img) => _image = img),
              const SizedBox(height: AppSpacing.md),
            ],
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
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: _isEditing ? 'Save changes' : 'Publish',
              expand: true,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
