import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/widgets/photo_placeholder.dart';

/// Shows a saved clothing photo, or a placeholder if its file cannot be read.
class ClosetPhoto extends StatelessWidget {
  const ClosetPhoto({
    super.key,
    required this.photoPath,
    this.height,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.semanticLabel,
  });

  final String photoPath;
  final double? height;
  final BoxFit fit;
  final int? cacheWidth;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(photoPath),
        width: double.infinity,
        height: height,
        fit: fit,
        cacheWidth: cacheWidth,
        semanticLabel: semanticLabel,
        excludeFromSemantics: semanticLabel == null,
        errorBuilder: (_, _, _) => PhotoPlaceholder(height: height ?? 96),
      ),
    );
  }
}
