import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfessionalImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const ProfessionalImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Check if URL is valid and likely an image
    final isValidUrl = _isValidUrl(imageUrl);
    final isImageUrl = _isImageUrl(imageUrl);

    if (!isValidUrl || !isImageUrl) {
      return _buildErrorWidget();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      imageBuilder: (context, imageProvider) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(10),
          image: DecorationImage(
            image: imageProvider,
            fit: fit,
          ),
        ),
      ),
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) => _buildErrorWidget(),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 200),
      memCacheWidth: width != null ? (width! * MediaQuery.of(context).devicePixelRatio).toInt() : null,
      memCacheHeight: height != null ? (height! * MediaQuery.of(context).devicePixelRatio).toInt() : null,
    );
  }

  Widget _buildPlaceholder() {
    return placeholder ??
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: borderRadius ?? BorderRadius.circular(10),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
            ),
          ),
        );
  }

  Widget _buildErrorWidget() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: borderRadius ?? BorderRadius.circular(10),
          ),
          child: const Center(
            child: Icon(
              Icons.image_not_supported,
              color: Colors.white54,
              size: 40,
            ),
          ),
        );
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  bool _isImageUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();
      final host = uri.host.toLowerCase();

      // Check for common image extensions
      final hasImageExtension = path.endsWith('.jpg') ||
             path.endsWith('.jpeg') ||
             path.endsWith('.png') ||
             path.endsWith('.gif') ||
             path.endsWith('.webp') ||
             path.endsWith('.bmp') ||
             path.endsWith('.svg');

      // Allow Unsplash and other image hosting services
      final isImageHost = host.contains('unsplash.com') ||
                         host.contains('pexels.com') ||
                         host.contains('pixabay.com') ||
                         host.contains('imgur.com') ||
                         host.contains('cloudinary.com') ||
                         host.contains('images.unsplash.com');

      // Allow direct image URLs without extensions (common with CDNs)
      final isLikelyImageUrl = !path.contains('.') ||
                              path.split('.').last.length <= 5; // Short extensions

      return hasImageExtension || isImageHost || isLikelyImageUrl;
    } catch (e) {
      return false;
    }
  }
}