import 'package:flutter/material.dart';
import '../services/image_upload_service.dart';
import 'glassy_container.dart';
import 'glassy_button.dart';
import 'professional_image.dart';

class ImageUploadWidget extends StatefulWidget {
  final String? initialImageUrl;
  final Function(String?) onImageSelected;
  final String productName;

  const ImageUploadWidget({
    super.key,
    this.initialImageUrl,
    required this.onImageSelected,
    required this.productName,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final ImageUploadService _imageService = ImageUploadService();
  String? _selectedImageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _selectedImageUrl = widget.initialImageUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Image',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Current image preview
        if (_selectedImageUrl != null && _selectedImageUrl!.isNotEmpty)
          Column(
            children: [
              GlassyContainer(
                height: 200,
                child: ProfessionalImage(
                  imageUrl: _selectedImageUrl!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GlassyButton(
                      onPressed: _showImageSourceDialog,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Change Image'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.redAccent, width: 1),
                      ),
                      child: GlassyButton(
                        onPressed: _removeImage,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete, color: Colors.redAccent),
                            SizedBox(width: 8),
                            Text(
                              'Remove',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )
        else
          // No image selected
          Column(
            children: [
              GlassyContainer(
                height: 120,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        color: Colors.white54,
                        size: 40,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No image selected',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GlassyButton(
                onPressed: _showImageSourceDialog,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Add Image'),
                  ],
                ),
              ),
            ],
          ),

        const SizedBox(height: 16),

        // Upload progress indicator
        if (_isUploading)
          const Column(
            children: [
              LinearProgressIndicator(
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
              SizedBox(height: 8),
              Text(
                'Uploading image...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
      ],
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16213e),
          title: const Text(
            'Select Image Source',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white70),
                title: const Text(
                  'Gallery',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white70),
                title: const Text(
                  'Camera',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _takePhoto();
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickFromGallery() async {
    try {
      final imagePath = await _imageService.pickImage();
      if (imagePath != null) {
        await _uploadImage(imagePath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final imagePath = await _imageService.takePhoto();
      if (imagePath != null) {
        await _uploadImage(imagePath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _uploadImage(String imagePath) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final fileName = '${widget.productName.replaceAll(' ', '_').toLowerCase()}_image';
      final imageUrl = await _imageService.uploadImage(imagePath, fileName);

      setState(() {
        _selectedImageUrl = imageUrl;
      });

      widget.onImageSelected(imageUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageUrl = null;
    });
    widget.onImageSelected(null);

    // Optionally delete from storage
    if (widget.initialImageUrl != null) {
      _imageService.deleteImage(widget.initialImageUrl!);
    }
  }
}