import 'package:flutter/material.dart';

class AppLoading extends StatelessWidget {
  const AppLoading({
    super.key,
    this.size = 100,
    this.message,
  });

  final double size;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final gif = Image.asset(
      'assets/gifs/loading.gif',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => SizedBox(
        width: size * 0.6,
        height: size * 0.6,
        child: const CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );

    if (message == null) {
      return Center(child: gif);
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          gif,
          const SizedBox(height: 12),
          Text(
            message!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }
}
