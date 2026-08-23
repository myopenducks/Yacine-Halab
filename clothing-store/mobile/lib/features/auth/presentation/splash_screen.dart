import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLight ? AppColors.surfaceLight : AppColors.dark,
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLogo(
              size: 100,
              showText: true,
            ),
            SizedBox(height: 48),
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
