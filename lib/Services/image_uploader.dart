import 'package:demo_text_extractor/Services/getx.dart';
import 'package:demo_text_extractor/const.dart';
import 'package:demo_text_extractor/screens/cropp.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import 'dart:math' as math;
import 'package:demo_text_extractor/screens/roi_selection.dart';
import 'package:photo_view/photo_view.dart';

class ImageUploader extends StatefulWidget {
  const ImageUploader({super.key});

  @override
  ImageUploaderState createState() => ImageUploaderState();
}

class ImageUploaderState extends State<ImageUploader> {
  bool _showROI = false;
  String? extractedText;
  double _rotationAngle = 0;
  TextEditingController textController = TextEditingController();
  bool isLoading = false;
<<<<<<< Updated upstream
=======
  final TransformationController _transformationController = TransformationController();
  final ValueNotifier<double> _rotationNotifier = ValueNotifier(0.0);
  bool _showRotationSlider = false;
  final GlobalKey _imageKey = GlobalKey();
  Matrix4? _lastTransformation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerImage();
    });
  }
>>>>>>> Stashed changes

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        selectedImageBytes = result.files.single.bytes;
        croppedImages = null; // Reset cropped image on new upload
      });
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected or invalid file')),
      );
    }
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
      _rotationAngle += 90;
    });
  }

<<<<<<< Updated upstream
  void _previewCroppedImage() {
    if (croppedImages != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CroppedImageShow(image: croppedImages!),
=======
  void _centerImage() {
    if (selectedImageBytes == null) return;
    final image = img.decodeImage(selectedImageBytes!);
    if (image == null) return;

    // Reset any existing transformation
    _transformationController.value = Matrix4.identity();
    _lastTransformation = Matrix4.identity();

    // Schedule a frame to allow layout to complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? box = _imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return;

      final viewSize = box.size;
      final imageSize = Size(image.width.toDouble(), image.height.toDouble());

      final scale = math.min(
        viewSize.width / imageSize.width,
        viewSize.height / imageSize.height
      );

      final matrix = Matrix4.identity()
        ..translate(
          (viewSize.width - imageSize.width * scale) / 2,
          (viewSize.height - imageSize.height * scale) / 2
        )
        ..scale(scale);

      setState(() {
        _transformationController.value = matrix;
        _lastTransformation = matrix.clone();
      });
    });
  }

  Widget _buildImageDisplay() {
    final image = img.decodeImage(selectedImageBytes!);
    final double imageWidth = image?.width.toDouble() ?? 1.0;
    final double imageHeight = image?.height.toDouble() ?? 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          key: _imageKey,
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 4.0,
            onInteractionEnd: (details) {
              setState(() {
                _lastTransformation = _transformationController.value.clone();
              });
            },
            child: Center(
              child: AspectRatio(
                aspectRatio: imageWidth / imageHeight,
                child: RotationAwareImage(
                  imageBytes: selectedImageBytes!,
                  rotationNotifier: _rotationNotifier,
                ),
              ),
            ),
          ),
        );
      }
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
>>>>>>> Stashed changes
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cropped image available')),
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
          return selectedImageBytes == null
              ? Center(
                  child: ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text("Upload Image"),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Stack(
                          children: [
<<<<<<< Updated upstream
                            Center(
                              child: provider.isROISelectionActive
                                  ? ROISelection(
                                      imageBytes: selectedImageBytes!,
                                      onROISelected: (croppedImg) {
                                        setState(() {
                                          croppedImages = croppedImg; // Store cropped image
                                        });
                                        provider.disableROISelection();
                                      },
                                    )
                                  : GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _showROI = !_showROI;
                                        });
                                      },
                                      child: _showROI
                                          ? ROISelection(
                                              imageBytes: selectedImageBytes!,
                                              onROISelected: (croppedImg) {
                                                setState(() {
                                                  croppedImages = croppedImg;
                                                });
                                              },
                                            )
                                          : Container(
                                              constraints: BoxConstraints(
                                                maxWidth: MediaQuery.of(context).size.width,
                                                maxHeight: MediaQuery.of(context).size.height,
                                              ),
                                              child: RotatedBox(
                                                quarterTurns: (_rotationAngle ~/ 90) % 4,
                                                child: PhotoView(
                                                  imageProvider: MemoryImage(selectedImageBytes!),
                                                  minScale: PhotoViewComputedScale.contained,
                                                  maxScale: PhotoViewComputedScale.contained,
                                                ),
                                              ),
                                            ),
                                    ),
                            ),
                            Positioned(
                              bottom: 80,
                              right: 15,
                              child: FloatingActionButton(
                                onPressed: _rotateImage,
                                child: const Icon(Icons.rotate_right),
                              ),
                            ),
                            Positioned(
                              top: 45,
                              right: 8,
                              child: IconButton(
                                onPressed: _clearImage,
                                icon: const Icon(Icons.close),
                              ),
                            ),
                            Positioned(
                              top: 45,
                              left: 8,
                              child: IconButton(
                                onPressed: _previewCroppedImage, // Open cropped image preview
                                icon: const Icon(Icons.image),
                              ),
                            )
=======
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
                                    initialTransformation: _lastTransformation,
                                  )
                                : _buildImageDisplay(),
                            _buildControlButtons(),
>>>>>>> Stashed changes
                          ],
                        ),
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}