import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_radius.dart';
import '../theme/app_surfaces.dart';

/// A rounded network image with on-disk caching (instant repeat loads + offline)
/// and built-in loading + error states. Used for announcement/event banners.
class NetworkImageBox extends StatelessWidget {
  const NetworkImageBox({
    super.key,
    required this.url,
    this.height = 140,
    this.borderRadius = AppRadius.md,
  });

  final String url;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: url,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, _) => Container(
          height: height,
          color: surfaces.cardBorder,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, _, _) => Container(
          height: height,
          color: surfaces.cardBorder,
          alignment: Alignment.center,
          child: Icon(LucideIcons.imageOff, color: surfaces.secondaryText),
        ),
      ),
    );
  }
}
