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
        AppImagePlaceholder(
          width: width,
          height: height,
          text: 'Chưa có hình ảnh',
        );
  }
}

class AppImagePlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final String text;

  const AppImagePlaceholder({
    super.key,
    this.width,
    this.height,
    this.text = 'Chưa có ảnh mô tả',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        final showText = constraints.maxHeight >= 110 && constraints.maxWidth >= 110;
        final iconSize = constraints.maxHeight < 80 ? 24.0 : 48.0;
        return Container(
          width: width ?? double.infinity,
          height: height ?? 220,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0),
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: iconSize,
                color: isDark ? Colors.grey[600] : Colors.grey[450],
              ),
              if (showText) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
