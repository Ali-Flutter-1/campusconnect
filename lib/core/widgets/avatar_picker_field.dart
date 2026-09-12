import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/image_picking.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_typography.dart';
import 'avatar_circle.dart';
import 'image_source_sheet.dart';

/// Circular profile-photo picker: shows the user's current avatar until they
/// choose a new one, then previews the pick. Tapping opens the camera/gallery
/// sheet; [onChanged] reports the selection (null once the pick is cleared).
///
/// The chosen image is not uploaded here — it rides along with the profile save
/// so a half-finished edit never changes the user's picture.
class AvatarPickerField extends StatefulWidget {
  const AvatarPickerField({
    super.key,
    required this.name,
    required this.onChanged,
    this.currentImageUrl,
    this.size = 96,
    this.enabled = true,
  });

  /// Used for the initials fallback when there is no photo.
  final String name;
  final ValueChanged<PickedImage?> onChanged;
  final String? currentImageUrl;
  final double size;

  /// False while a save is in flight, so the picker cannot be re-opened.
  final bool enabled;

  @override
  State<AvatarPickerField> createState() => _AvatarPickerFieldState();
}

class _AvatarPickerFieldState extends State<AvatarPickerField> {
  Uint8List? _preview;
  bool _loading = false;

  Future<void> _open() async {
    if (_loading || !widget.enabled) return;
    final choice = await showImageSourceSheet(
      context,
      canRemove: _preview != null,
      title: 'Profile photo',
    );
    if (choice == null || !mounted) return;

    if (choice == ImageSourceChoice.remove) {
      setState(() => _preview = null);
      widget.onChanged(null);
      return;
    }

    setState(() => _loading = true);
    try {
      final picked = await pickImage(choice.pickSource!, maxWidth: 800);
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (picked != null) _preview = picked.bytes;
      });
      if (picked != null) widget.onChanged(picked);
    } on ImagePickException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final size = widget.size;

    return Column(
      children: [
        GestureDetector(
          onTap: _open,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_preview != null)
                ClipOval(
                  child: Image.memory(
                    _preview!,
                    width: size,
                    height: size,
                    fit: BoxFit.cover,
                  ),
                )
              else
                AvatarCircle(
                  name: widget.name,
                  imageUrl: widget.currentImageUrl,
                  size: size,
                ),
              // Dim + spinner while the pick is being read and decoded.
              if (_loading)
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.white),
                    ),
                  ),
                ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.s500,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: surfaces.scaffoldBackground,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    LucideIcons.camera,
                    size: 13,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _loading
              ? 'Loading photo…'
              : (_preview != null ? 'New photo selected' : 'Change photo'),
          style: AppTypography.inter(
            size: AppTypography.sm,
            weight: AppTypography.medium,
            color: _preview != null
                ? surfaces.accentText
                : surfaces.secondaryText,
          ),
        ),
      ],
    );
  }
}
