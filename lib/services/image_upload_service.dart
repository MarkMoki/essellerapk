import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageUploadService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image?.path;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  Future<String?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return photo?.path;
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  Future<String> uploadImage(String imagePath, String fileName) async {
    try {
      final file = File(imagePath);
      final fileExtension = file.path.split('.').last.toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName.$fileExtension';

      // Upload to Supabase Storage
      final response = await _supabase.storage
          .from('product-images')
          .upload(
            uniqueFileName,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      if (response.isNotEmpty) {
        // Get public URL
        final publicUrl = _supabase.storage
            .from('product-images')
            .getPublicUrl(uniqueFileName);

        return publicUrl;
      } else {
        throw Exception('Upload failed: No response');
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract file name from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final fileName = pathSegments.last;

      await _supabase.storage
          .from('product-images')
          .remove([fileName]);
    } catch (e) {
      // Silently fail for delete operations
      // print('Failed to delete image: $e'); // Commented out for production
    }
  }
}