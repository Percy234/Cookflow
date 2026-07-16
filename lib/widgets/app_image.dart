import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Widget hiển thị ảnh từ file path, tương thích cả Android và Web.
/// Trên Web (không hỗ trợ Image.file), hiển thị placeholder thay thế.
class AppImage extends StatelessWidget {
  final String? imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final BorderRadius? borderRadius;

  const AppImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final Widget image = _buildImage();
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _buildImage() {
    if (imagePath == null || imagePath!.isEmpty) {
      return _defaultPlaceholder();
    }

    // Flutter Web không hỗ trợ Image.file
    if (kIsWeb) {
      if (imagePath!.startsWith('http') || imagePath!.startsWith('blob:')) {
        return Image.network(
          imagePath!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => placeholder ?? _defaultPlaceholder(),
        );
      }
      return placeholder ?? _defaultPlaceholder();
    }

    return Image.file(
      File(imagePath!),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => placeholder ?? _defaultPlaceholder(),
    );
  }

  Widget _defaultPlaceholder() {
    return placeholder ??
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.3),
                AppColors.primaryDark.withValues(alpha: 0.5),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.restaurant_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
        );
  }
}
