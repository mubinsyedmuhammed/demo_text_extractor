import 'dart:typed_data';

import 'package:demo_text_extractor/Services/api_fast.dart';
import 'package:demo_text_extractor/Services/getx.dart';
import 'package:demo_text_extractor/const.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import 'package:demo_text_extractor/screens/roi_selection.dart';
import 'package:photo_view/photo_view.dart';

class ImageUploader extends StatefulWidget {
  const ImageUploader({super.key});

  @override
  ImageUploaderState createState() => ImageUploaderState();
}

class ImageUploaderState extends State<ImageUploader> {
  String? extractedText;
  double _rotationAngle = 0;
  TextEditingController textController = TextEditingController();
  bool isLoading = false;

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result == null || result.files.single.bytes == null) {
        throw Exception('No image selected');
      }

      if (result.files.single.size > 10 * 1024 * 1024) { // 10MB limit
        throw Exception('Image size too large (max 10MB)');
      }

      setState(() {
        selectedImageBytes = result.files.single.bytes;
        croppedImages = null;
      });
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _clearImage() {
    setState(() {
      selectedImageBytes = null;
      croppedImages = null;
      extractedText = null;
    });
  }

  void _rotateImage() {
    setState(() {
      _rotationAngle = (_rotationAngle + 90) % 360;
    });
  }

  Widget _buildImageDisplay() {
    try {
      return ClipRect(
        child: PhotoView(
          imageProvider: MemoryImage(selectedImageBytes!),
          minScale: PhotoViewComputedScale.contained * 0.8,
          maxScale: PhotoViewComputedScale.covered * 3,
          initialScale: PhotoViewComputedScale.contained,
          backgroundDecoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          filterQuality: FilterQuality.high,
          enableRotation: true,
          basePosition: Alignment.center,
          // rotation: _rotationAngle * (3.14159265359 / 180),
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Text('Error loading image: $error'),
            );
          },
        ),
      );
    } catch (e) {
      return Center(
        child: Text('Error displaying image: $e'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Uploaded Document',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Consumer<RoiProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              selectedImageBytes == null
                  ? Center(
                      child: ElevatedButton(
                        onPressed: _pickImage,
                        child: const Text("Upload Image"),
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              provider.isROISelectionActive
                                  ? ROISelection(
                                      imageBytes: selectedImageBytes!,
                                      onROISelected: (croppedImg) async {
                                        setState(() {
                                          croppedImages = croppedImg;
                                        });
                                        provider.setLoading(true);
                                        OCRService apiService = OCRService();
                                        String extractedText = 
                                            await apiService.extractTextFromImageOcr(croppedImg);
                                        provider.processTextExtraction(extractedText);
                                        provider.setLoading(false);
                                      },
                                    )
                                  : _buildImageDisplay(),
                              // Control buttons
                              _buildControlButtons(),
                            ],
                          ),
                        ),
                      ],
                    ),
              if (provider.isLoading)
                _buildLoadingIndicator(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildControlButtons() {
    return Stack(
      children: [
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: _rotateImage,
            child: const Icon(Icons.rotate_right),
          ),
        ),
        Positioned(
          top: 20,
          right: 20,
          child: IconButton(
            onPressed: _clearImage,
            icon: const Icon(Icons.close),
            color: Colors.black87,
          ),
        ),
        Positioned(
          top: 20,
          left: 20,
          child: IconButton(
            onPressed: _previewCroppedImage,
            icon: const Icon(Icons.image),
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: Colors.black54,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Extracting text...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _previewCroppedImage() {
    if (croppedImages != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CroppedImageShow(image: croppedImages!),
        ),
      );    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cropped image available')),
      );
    }
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}

class CroppedImageShow extends StatelessWidget {
  final Uint8List image;

  const CroppedImageShow({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cropped Image'),
      ),
      body: Center(
        child: Image.memory(image),
      ),
    );
  }
}
