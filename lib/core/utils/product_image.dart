import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Returns the local asset path for a product image based on its ID.
/// Product images are stored at assets/products/{id}.jpg
String getProductImagePath(String productId) {
  return 'assets/products/$productId.jpg';
}

/// Widget that displays a product image.
///
/// Priority order:
///   1. [imageBytes] – raw bytes from image_picker (works on web + native)
///   2. [imageUrl]   – an absolute file-system path (native only) or http URL
///   3. Asset image at `assets/products/{productId}.jpg`
///   4. Styled icon placeholder
class ProductImage extends StatelessWidget {
  final String productId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? placeholderColor;
  /// Raw bytes of a locally-picked image. Works on all platforms.
  final Uint8List? imageBytes;
  /// Stored image path/URL on the product model.
  final String? imageUrl;

  const ProductImage({
    super.key,
    required this.productId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderColor,
    this.imageBytes,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final color = placeholderColor ?? Theme.of(context).primaryColor;

    Widget placeholder() => Container(
          width: width,
          height: height,
          color: color.withValues(alpha: 0.06),
          child: Center(
            child: Icon(
              Icons.shopping_bag_outlined,
              size: (height ?? 80) * 0.4,
              color: color,
            ),
          ),
        );

    // 1. Locally-picked bytes (cross-platform – works on web & native)
    if (imageBytes != null) {
      return Image.memory(
        imageBytes!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (ctx, err, st) => placeholder(),
      );
    }

    // 2. imageUrl that is an absolute file path (native only)
    if (!kIsWeb &&
        imageUrl != null &&
        imageUrl!.isNotEmpty &&
        imageUrl!.startsWith('/')) {
      return Image.file(
        File(imageUrl!),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (ctx, err, st) => placeholder(),
      );
    }

    // 3. Asset image
    return Image.asset(
      getProductImagePath(productId),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (ctx, err, st) => placeholder(),
    );
  }
}
