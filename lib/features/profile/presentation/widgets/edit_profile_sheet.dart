import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

/// Admin/student profile editor — updates name, course, department and year via
/// [AuthBloc]. Closes itself once the update lands.
class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // Reuse the app-wide AuthBloc inside the sheet's own context.
      builder: (_) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: const EditProfileSheet(),
      ),
    );
  }

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _course;
  late final TextEditingController _department;
  late final TextEditingController _year;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthBloc>().state.user;
    _name = TextEditingController(text: user?.fullName ?? '');
    _course = TextEditingController(text: user?.course ?? '');
    _department = TextEditingController(text: user?.department ?? '');
    _year = TextEditingController(text: user?.year ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _course.dispose();
    _department.dispose();
    _year.dispose();
    super.dispose();
  }

  void _save() {
    context.read<AuthBloc>().add(AuthProfileUpdateRequested(
          fullName: _name.text.trim(),
          course: _course.text.trim(),
          department: _department.text.trim(),
          year: _year.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (p, c) => p.isSubmitting && !c.isSubmitting,
      listener: (context, state) {
        // Close once the in-flight update completes (success or error toast
        // surfaces on the page behind).
        if (state.errorMessage == null) Navigator.of(context).maybePop();
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Edit profile',
              style: AppTypography.inter(
                size: AppTypography.lg,
                weight: AppTypography.bold,
                color: surfaces.primaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(controller: _name, label: 'Full name', hint: 'Your name'),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _course,
              label: 'Course',
              hint: 'e.g. Computer Science',
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _department,
                    label: 'Department',
                    hint: 'e.g. Engineering',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppTextField(
                    controller: _year,
                    label: 'Year',
                    hint: 'e.g. 2nd',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            BlocBuilder<AuthBloc, AuthState>(
              buildWhen: (p, c) => p.isSubmitting != c.isSubmitting,
              builder: (context, state) => AppButton(
                label: 'Save changes',
                expand: true,
                isLoading: state.isSubmitting,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
