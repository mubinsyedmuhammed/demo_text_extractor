import 'package:demo_text_extractor/Services/api_fast.dart';
import 'package:demo_text_extractor/Services/getx.dart';
import 'package:demo_text_extractor/const.dart';
import 'package:demo_text_extractor/screens/cropp.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import 'package:demo_text_extractor/screens/roi_selection.dart';

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

      if (result.files.single.size > 2 * 1024 * 1024) { // 2MB limit
        throw Exception('Image size too large (max 2MB)');
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
      return LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: InteractiveViewer(
              maxScale: 4.0,
              minScale: 0.8,
              child: Transform.rotate(
                angle: _rotationAngle * 3.14159 / 180,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Image.memory(
                    selectedImageBytes!,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      return Center(child: Text('Error displaying image: $e'));
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
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              color: Colors.grey[100], // Background color
                              child: provider.isROISelectionActive
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
                            ),
                            _buildControlButtons(),
                          ],
                        ),
                      ),
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
            heroTag: 'rotateButton',
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
              SizedBox(width: 10),
              Text(
                'Loading....',
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

