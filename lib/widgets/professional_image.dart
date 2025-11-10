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

    // Clean and normalize the URL
    final cleanUrl = _normalizeImageUrl(imageUrl);

    return CachedNetworkImage(
      imageUrl: cleanUrl,
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
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.image_not_supported,
                  color: Colors.white54,
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  'Image unavailable',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
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
             path.endsWith('.svg') ||
             path.endsWith('.avif') ||
             path.endsWith('.tiff') ||
             path.endsWith('.ico');

      // Allow popular image hosting services
      final isImageHost = host.contains('unsplash.com') ||
                         host.contains('pexels.com') ||
                         host.contains('pixabay.com') ||
                         host.contains('imgur.com') ||
                         host.contains('cloudinary.com') ||
                         host.contains('images.unsplash.com') ||
                         host.contains('cdn.pixabay.com') ||
                         host.contains('raw.githubusercontent.com') ||
                         host.contains('githubusercontent.com') ||
                         host.contains('ibb.co') ||
                         host.contains('i.imgur.com') ||
                         host.contains('i.ibb.co') ||
                         host.contains('cdn.statically.io') ||
                         host.contains('via.placeholder.com');

      // Allow direct image URLs without extensions (common with CDNs)
      final isLikelyImageUrl = !path.contains('.') ||
                              path.split('.').last.length <= 5; // Short extensions

      // Allow URLs that look like they might be images (contains 'image', 'img', 'photo', etc.)
      final hasImageKeywords = path.contains('image') ||
                              path.contains('img') ||
                              path.contains('photo') ||
                              path.contains('picture') ||
                              path.contains('pic');

      return hasImageExtension || isImageHost || isLikelyImageUrl || hasImageKeywords;
    } catch (e) {
      return false;
    }
  }

  String _normalizeImageUrl(String url) {
    try {
      // Handle common URL issues
      String normalizedUrl = url.trim();

      // Remove any leading/trailing whitespace
      normalizedUrl = normalizedUrl.trim();

      // Handle URLs that might be missing protocol
      if (!normalizedUrl.startsWith('http://') && !normalizedUrl.startsWith('https://')) {
        // Assume https for modern websites
        if (normalizedUrl.contains('://')) {
          // Has protocol but not http/https
          return normalizedUrl;
        } else {
          // No protocol, assume https
          normalizedUrl = 'https://$normalizedUrl';
        }
      }

      // Handle common image hosting shortcuts
      if (normalizedUrl.contains('imgur.com') && !normalizedUrl.contains('i.imgur.com')) {
        // Convert album/gallery links to direct image links if possible
        // This is a basic conversion - in practice, you'd need more sophisticated parsing
        normalizedUrl = normalizedUrl.replaceFirst('imgur.com', 'i.imgur.com');
      }

      // Remove common tracking parameters that might break image loading
      final trackingParams = ['utm_source', 'utm_medium', 'utm_campaign', 'utm_term', 'utm_content', 'fbclid', 'gclid'];
      final parsedUri = Uri.parse(normalizedUrl);
      final queryParams = Map<String, String>.from(parsedUri.queryParameters);

      for (final param in trackingParams) {
        queryParams.remove(param);
      }

      final cleanUri = parsedUri.replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      normalizedUrl = cleanUri.toString();

      return normalizedUrl;
    } catch (e) {
      // If normalization fails, return original URL
      return url.trim();
    }
  }
}