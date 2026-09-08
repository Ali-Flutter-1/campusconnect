import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/image_picking.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_typography.dart';
import 'image_source_sheet.dart';

export '../services/image_picking.dart' show PickedImage;

/// A tappable field that lets an admin attach an optional image, from the
/// camera or the gallery. Shows an "Add image" prompt, then a preview with a
/// remove button once picked. Reports the selection via [onChanged].
class ImagePickerField extends StatefulWidget {
  const ImagePickerField({super.key, required this.onChanged});

  final ValueChanged<PickedImage?> onChanged;

  @override
  State<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<ImagePickerField> {
  Uint8List? _preview;
  bool _loading = false;

  Future<void> _pick() async {
    if (_loading) return;
    final choice = await showImageSourceSheet(context, title: 'Add an image');
    if (choice?.pickSource == null || !mounted) return;

    // Reading/decoding the picked file can take a beat — show a spinner.
    setState(() => _loading = true);
    try {
      final picked = await pickImage(choice!.pickSource!);
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

  void _clear() {
    setState(() => _preview = null);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;

    if (_loading) {
      return Container(
        height: 96,
        decoration: BoxDecoration(
          color: surfaces.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: surfaces.cardBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primary.s400),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Loading image…',
              style: AppTypography.inter(
                size: AppTypography.sm,
                color: surfaces.secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    if (_preview != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image.memory(
              _preview!,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _clear,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(LucideIcons.x, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return InkWell(
      onTap: _pick,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: surfaces.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: surfaces.cardBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.imagePlus, color: AppColors.primary.s400),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Add image (optional)',
              style: AppTypography.inter(
                size: AppTypography.sm,
                color: surfaces.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
