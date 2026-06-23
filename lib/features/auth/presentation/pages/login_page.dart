import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/animations/fade_slide_in.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/brand.dart';
import '../bloc/auth_bloc.dart';

/// Email/password sign-in. On success the router redirect (driven by [AuthBloc])
/// sends the user to their role's landing tab automatically.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
          AuthSignInRequested(
            email: _email.text.trim().toLowerCase(),
            password: _password.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandGradient(
        child: SafeArea(
          child: BlocListener<AuthBloc, AuthState>(
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
                        const _Header(),
                        const SizedBox(height: AppSpacing.xl),
                        AppTextField(
                          controller: _email,
                          label: 'Email',
                          hint: 'you@campus.edu',
                          icon: LucideIcons.mail,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [
                            AutofillHints.username,
                            AutofillHints.email,
                          ],
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
                          autofillHints: const [AutofillHints.password],
                          validator: Validators.password,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        BlocBuilder<AuthBloc, AuthState>(
                          buildWhen: (p, c) => p.isSubmitting != c.isSubmitting,
                          builder: (context, state) => AppButton(
                            label: 'Sign in',
                            expand: true,
                            isLoading: state.isSubmitting,
                            onPressed: _submit,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Center(
                          child: TextButton(
                            onPressed: () => context.push(AppRoutes.register),
                            child: Text(
                              "Don't have an account? Sign up",
                              style: AppTypography.inter(
                                size: AppTypography.base,
                                weight: AppTypography.medium,
                                color: AppColors.primary.s400,
                              ),
                            ),
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
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const BrandMark(size: 72),
        const SizedBox(height: AppSpacing.md),
        const BrandWordmark(fontSize: 26),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Sign in to your campus account',
          style: AppTypography.inter(
            size: AppTypography.base,
            color: AppColors.secondary.s300,
          ),
        ),
      ],
    );
  }
}
