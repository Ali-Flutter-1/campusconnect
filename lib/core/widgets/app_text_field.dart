import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_typography.dart';

/// Reusable themed text input used across the app. When [obscureText] is true it
/// renders a show/hide toggle. Supports [autofillHints] for password managers.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
    this.autofillHints,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final String? label;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final int maxLines;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final colorScheme = Theme.of(context).colorScheme;

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.inter(
              size: AppTypography.sm,
              weight: AppTypography.medium,
              color: surfaces.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextFormField(
          controller: widget.controller,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onFieldSubmitted: widget.onSubmitted,
          autofillHints: widget.autofillHints,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          style: AppTypography.inter(
            size: AppTypography.base,
            color: surfaces.primaryText,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTypography.inter(
              size: AppTypography.base,
              color: surfaces.secondaryText,
            ),
            prefixIcon: widget.icon == null
                ? null
                : Icon(widget.icon, size: 20, color: surfaces.secondaryText),
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscured ? LucideIcons.eye : LucideIcons.eyeOff,
                      size: 18,
                      color: surfaces.secondaryText,
                    ),
                    onPressed: () => setState(() => _obscured = !_obscured),
                    tooltip: _obscured ? 'Show password' : 'Hide password',
                  )
                : null,
            filled: true,
            fillColor: surfaces.cardBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            enabledBorder: border(surfaces.cardBorder),
            focusedBorder: border(colorScheme.primary, 1.5),
            errorBorder: border(colorScheme.error),
            focusedErrorBorder: border(colorScheme.error, 1.5),
          ),
        ),
      ],
    );
  }
}
