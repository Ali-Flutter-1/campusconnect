import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/image_picker_field.dart';
import '../../domain/entities/event.dart';

/// Result of the admin "new event" form.
class NewEvent {
  const NewEvent({
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.category,
    this.image,
  });

  final String title;
  final String description;
  final DateTime date;
  final String time;
  final String location;
  final String category;
  final PickedImage? image;
}

/// Admin-only modal to schedule an event.
class CreateEventSheet extends StatefulWidget {
  const CreateEventSheet({super.key, this.initial});

  /// When set, edits an existing event.
  final Event? initial;

  static Future<NewEvent?> show(BuildContext context, {Event? initial}) {
    return showModalBottomSheet<NewEvent>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CreateEventSheet(initial: initial),
    );
  }

  @override
  State<CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<CreateEventSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title ?? '');
  late final _description =
      TextEditingController(text: widget.initial?.description ?? '');
  late final _time = TextEditingController(text: widget.initial?.time ?? '');
  late final _location =
      TextEditingController(text: widget.initial?.location ?? '');
  late String _category = widget.initial?.category ?? 'academic';
  late DateTime _date =
      widget.initial?.date ?? DateTime.now().add(const Duration(days: 1));
  PickedImage? _image;

  bool get _isEditing => widget.initial != null;

  static const _categories = ['academic', 'social', 'sports'];

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _time.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      // Allow an already-past date when editing an older event.
      firstDate: _date.isBefore(now) ? _date : now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(NewEvent(
      title: _title.text.trim(),
      description: _description.text.trim(),
      date: _date,
      time: _time.text.trim(),
      location: _location.text.trim(),
      category: _category,
      image: _image,
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
                _isEditing ? 'Edit event' : 'New event',
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
                hint: 'Tech talk',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title required' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _description,
                label: 'Description',
                hint: 'What is it about?',
              ),
              const SizedBox(height: AppSpacing.md),
              if (!_isEditing) ...[
                ImagePickerField(onChanged: (img) => _image = img),
                const SizedBox(height: AppSpacing.md),
              ],
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _time,
                      label: 'Time',
                      hint: '4:00 PM',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppTextField(
                      controller: _location,
                      label: 'Location',
                      hint: 'Hall A',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(DateFormat('MMM d, yyyy').format(_date)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
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
                label: _isEditing ? 'Save changes' : 'Create event',
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
