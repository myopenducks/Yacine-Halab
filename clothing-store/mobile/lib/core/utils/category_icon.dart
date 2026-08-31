import 'package:flutter/material.dart';

/// Returns a unique, matching Material Icon for a category based on its name.
IconData getCategoryIcon(String categoryName) {
  final name = categoryName.trim().toLowerCase();

  if (name.contains('t-shirt') ||
      name.contains('tshirt') ||
      name.contains('tee') ||
      name.contains('chemise') ||
      name.contains('haut') ||
      name.contains('tricot') ||
      name.contains('pull') ||
      name.contains('sweat') ||
      name.contains('polo') ||
      name.contains('veste') ||
      name.contains('manteau')) {
    return Icons.dry_cleaning_rounded;
  }

  if (name.contains('shoe') ||
      name.contains('chauss') ||
      name.contains('basket') ||
      name.contains('sneaker') ||
      name.contains('boot') ||
      name.contains('nike') ||
      name.contains('adidas')) {
    return Icons.directions_walk_rounded;
  }

  if (name.contains('slipper') ||
      name.contains('claquette') ||
      name.contains('sandale') ||
      name.contains('pantoufle') ||
      name.contains('crocs')) {
    return Icons.beach_access_rounded;
  }

  if (name.contains('short') || name.contains('bermuda')) {
    return Icons.cut_outlined;
  }

  if (name.contains('pant') ||
      name.contains('jean') ||
      name.contains('jogging') ||
      name.contains('survêt') ||
      name.contains('survet')) {
    return Icons.airline_seat_legroom_extra_rounded;
  }

  if (name.contains('set') ||
      name.contains('ensemble') ||
      name.contains('costume')) {
    return Icons.style_rounded;
  }

  if (name.contains('robe') || name.contains('dress') || name.contains('jupe')) {
    return Icons.woman_rounded;
  }

  if (name.contains('access') ||
      name.contains('sac') ||
      name.contains('chapeau') ||
      name.contains('casquette') ||
      name.contains('ceinture') ||
      name.contains('montre')) {
    return Icons.watch_rounded;
  }

  return Icons.category_rounded;
}
