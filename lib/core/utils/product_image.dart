import 'package:flutter/material.dart';

/// Returns the local asset path for a product image based on its ID.
/// Product images are stored at assets/products/{id}.jpg
String getProductImagePath(String productId) {
  return 'assets/products/$productId.jpg';
}

/// Widget that displays a product image from local assets.
/// Falls back to a styled icon placeholder if the image fails to load.
class ProductImage extends StatelessWidget {
  final String productId;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? placeholderColor;

  const ProductImage({
    super.key,
    required this.productId,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = placeholderColor ?? Theme.of(context).primaryColor;
    return Image.asset(
      getProductImagePath(productId),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
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
      },
    );
  }
}
