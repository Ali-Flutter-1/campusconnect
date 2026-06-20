import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Centered loading spinner, replacing the RN `ActivityIndicator` loading state.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary.s500),
        ),
      ),
    );
  }
}
