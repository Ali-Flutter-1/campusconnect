import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_typography.dart';

/// An image chosen by the user, ready to upload.
class PickedImage {
  const PickedImage({required this.bytes, required this.ext});
  final Uint8List bytes;
  final String ext;
}

/// A tappable field that lets an admin attach an optional image. Shows an
/// "Add image" prompt, then a preview with a remove button once picked.
/// Reports the selection via [onChanged].
class ImagePickerField extends StatefulWidget {
  const ImagePickerField({super.key, required this.onChanged});

  final ValueChanged<PickedImage?> onChanged;

  @override
  State<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<ImagePickerField> {
  final _picker = ImagePicker();
  Uint8List? _preview;

  Future<void> _pick() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 80,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
      setState(() => _preview = bytes);
      widget.onChanged(PickedImage(bytes: bytes, ext: ext));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not pick image.')),
        );
      }
    }
  }

  void _clear() {
    setState(() => _preview = null);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;

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
