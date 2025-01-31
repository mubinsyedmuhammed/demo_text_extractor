import 'package:demo_text_extractor/Services/getx.dart';
import 'package:demo_text_extractor/const.dart';
import 'package:demo_text_extractor/screens/cropp.dart';
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
  bool _showROI = false;
  String? extractedText;
  double _rotationAngle = 0;
  TextEditingController textController = TextEditingController();
  bool isLoading = false;

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

  void _previewCroppedImage() {
    if (croppedImages != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CroppedImageShow(image: croppedImages!),
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
