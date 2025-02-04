import 'dart:typed_data';

import 'package:demo_text_extractor/Services/api_fast.dart';
import 'package:demo_text_extractor/Services/getx.dart';
import 'package:demo_text_extractor/Services/const.dart';
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
  TextEditingController textController = TextEditingController();
  bool isLoading = false;
  final TransformationController _transformationController = TransformationController();
  final ValueNotifier<double> _rotationNotifier = ValueNotifier(0.0);
  bool _showRotationSlider = false;

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
        // Reset zoom and rotation
        _transformationController.value = Matrix4.identity();
        _rotationNotifier.value = 0.0;
        _showRotationSlider = false;
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
      // Reset zoom and rotation
      _transformationController.value = Matrix4.identity();
      _rotationNotifier.value = 0.0;
      _showRotationSlider = false;
    });
  }

  void _rotateImage() {
    _rotationNotifier.value = ((_rotationNotifier.value + 90) % 360) - 180;
  }

  Widget _buildImageDisplay() {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 4.0,
      child: RotationAwareImage(
        imageBytes: selectedImageBytes!,
        rotationNotifier: _rotationNotifier,
      ),
    );
  }

  Widget _buildRotationControls() {
    return Positioned(
      bottom: 80,
      left: 16,
      right: 16,
      child: AnimatedOpacity(
        opacity: _showRotationSlider ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Rotation'),
                    Row(
                      children: [
                        Text('${_rotationNotifier.value.toStringAsFixed(1)}°'),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.restore, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _rotationNotifier.value = 0.0,
                          tooltip: 'Reset rotation',
                        ),
                      ],
                    ),
                  ],
                ),
                ValueListenableBuilder<double>(
                  valueListenable: _rotationNotifier,
                  builder: (context, rotation, child) {
                    return Slider(
                      value: rotation,
                      min: -180,
                      max: 180,
                      divisions: 360,
                      label: '${rotation.round()}°',
                      onChanged: (value) {
                        _rotationNotifier.value = value;
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                                    transformationController: _transformationController,
                                    rotationNotifier: _rotationNotifier,
                                  )
                                : _buildImageDisplay(),
                            _buildControlButtons(),
                          ],
                        ),
                      ),
                    ),
              if (selectedImageBytes != null) _buildRotationControls(),
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
        Positioned(
          bottom: 20,
          left: 20,
          child: FloatingActionButton(
            heroTag: 'rotationSliderButton',
            onPressed: () => setState(() => _showRotationSlider = !_showRotationSlider),
            child: Icon(_showRotationSlider ? Icons.rotate_left : Icons.rotate_90_degrees_cw),
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
    _transformationController.dispose();
    _rotationNotifier.dispose();
    textController.dispose();
    super.dispose();
  }
}

class RotationAwareImage extends StatelessWidget {
  final Uint8List imageBytes;
  final ValueNotifier<double> rotationNotifier;

  const RotationAwareImage({
    super.key,
    required this.imageBytes,
    required this.rotationNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: rotationNotifier,
      builder: (context, rotation, child) {
        return Transform.rotate(
          angle: rotation * 3.14159 / 180,
          child: Image.memory(
            imageBytes,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        );
      },
    );
  }
}

