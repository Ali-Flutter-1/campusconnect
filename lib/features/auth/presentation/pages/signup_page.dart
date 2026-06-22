import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/animations/fade_slide_in.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/user_role.dart';
import '../bloc/auth_bloc.dart';

/// New-account screen. Accounts are created with the `student` role by default
/// (admins are promoted server-side). On success the router redirect navigates
/// to Home and this page is popped.
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _adminCode = TextEditingController();
  UserRole _role = UserRole.student;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _adminCode.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
          AuthSignUpRequested(
            fullName: _name.text.trim(),
            email: _email.text.trim().toLowerCase(),
            password: _password.text,
            // Only send a code when registering as admin; the server validates it.
            adminCode: _role == UserRole.admin ? _adminCode.text.trim() : null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          // On success the router redirect moves the user to their landing tab,
          // so we only need to surface errors here.
          listenWhen: (p, c) => p.errorMessage != c.errorMessage,
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            }
          },
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: FadeSlideIn(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Join your campus community',
                        style: AppTypography.inter(
                          size: AppTypography.lg,
                          weight: AppTypography.semiBold,
                          color: surfaces.primaryText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        controller: _name,
                        label: 'Full name',
                        hint: 'Jane Student',
                        icon: LucideIcons.user,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        validator: (v) => Validators.required(v, 'Name'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _email,
                        label: 'Email',
                        hint: 'you@campus.edu',
                        icon: LucideIcons.mail,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: Validators.email,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: _password,
                        label: 'Password',
                        hint: '••••••••',
                        icon: LucideIcons.lock,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.newPassword],
                        onSubmitted: (_) => _submit(),
                        validator: Validators.password,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _RoleField(
                        role: _role,
                        onChanged: (r) => setState(() => _role = r),
                      ),
                      // Admin code only appears when "Admin" is chosen.
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        child: _role == UserRole.admin
                            ? Padding(
                                padding:
                                    const EdgeInsets.only(top: AppSpacing.md),
                                child: AppTextField(
                                  controller: _adminCode,
                                  label: 'Admin access code',
                                  hint: 'Enter the admin phrase',
                                  icon: LucideIcons.shieldCheck,
                                  obscureText: true,
                                  validator: (v) =>
                                      (_role == UserRole.admin &&
                                              (v == null || v.trim().isEmpty))
                                          ? 'Enter the admin code'
                                          : null,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      BlocBuilder<AuthBloc, AuthState>(
                        buildWhen: (p, c) => p.isSubmitting != c.isSubmitting,
                        builder: (context, state) => AppButton(
                          label: 'Create account',
                          expand: true,
                          isLoading: state.isSubmitting,
                          onPressed: _submit,
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Labeled Student/Admin dropdown for the signup form.
class _RoleField extends StatelessWidget {
  const _RoleField({required this.role, required this.onChanged});

  final UserRole role;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Register as',
          style: AppTypography.inter(
            size: AppTypography.sm,
            weight: AppTypography.medium,
            color: surfaces.secondaryText,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<UserRole>(
          initialValue: role,
          icon: const Icon(LucideIcons.chevronDown, size: 18),
          decoration: InputDecoration(
            filled: true,
            fillColor: surfaces.cardBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: surfaces.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: surfaces.cardBorder),
            ),
          ),
          items: const [
            DropdownMenuItem(value: UserRole.student, child: Text('Student')),
            DropdownMenuItem(value: UserRole.admin, child: Text('Admin')),
          ],
          onChanged: (r) => onChanged(r ?? UserRole.student),
        ),
      ],
    );
  }
}
