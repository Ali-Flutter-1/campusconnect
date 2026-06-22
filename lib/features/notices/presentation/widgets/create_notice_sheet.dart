import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/notice.dart';

/// Result of the admin "new notice" form.
class NewNotice {
  const NewNotice({
    required this.title,
    required this.content,
    required this.category,
    required this.priority,
    this.department,
  });

  final String title;
  final String content;
  final String category;
  final String priority;
  final String? department;
}

/// Admin-only modal to post a notice.
class CreateNoticeSheet extends StatefulWidget {
  const CreateNoticeSheet({super.key, this.initial});

  /// When set, edits an existing notice.
  final Notice? initial;

  static Future<NewNotice?> show(BuildContext context, {Notice? initial}) {
    return showModalBottomSheet<NewNotice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CreateNoticeSheet(initial: initial),
    );
  }

  @override
  State<CreateNoticeSheet> createState() => _CreateNoticeSheetState();
}

class _CreateNoticeSheetState extends State<CreateNoticeSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title ?? '');
  late final _content =
      TextEditingController(text: widget.initial?.content ?? '');
  late final _department =
      TextEditingController(text: widget.initial?.department ?? '');
  late String _category = widget.initial?.category ?? 'general';
  late bool _pinned = widget.initial?.isPinned ?? false;

  bool get _isEditing => widget.initial != null;

  static const _categories = ['general', 'exams', 'holidays', 'fees', 'events'];

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _department.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(NewNotice(
      title: _title.text.trim(),
      content: _content.text.trim(),
      category: _category,
      priority: _pinned ? 'high' : 'normal',
      department: _department.text.trim().isEmpty ? null : _department.text.trim(),
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
                _isEditing ? 'Edit notice' : 'New notice',
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
                hint: 'Exam timetable released',
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
              AppTextField(
                controller: _department,
                label: 'Department (optional)',
                hint: 'Office of Registrar',
              ),
              const SizedBox(height: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _pinned,
                onChanged: (v) => setState(() => _pinned = v),
                title: Text(
                  'Pin this notice',
                  style: AppTypography.inter(
                    size: AppTypography.base,
                    color: surfaces.primaryText,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: _isEditing ? 'Save changes' : 'Post notice',
                expand: true,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
