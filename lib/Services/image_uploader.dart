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
  bool _showROI = false;
  String? extractedText;
  double _rotationAngle = 0;

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        selectedImageBytes = result.files.single.bytes;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected or invalid file')),
      );
    }
  }

  void _clearImage() {
    setState(() {
      selectedImageBytes = null;
      extractedText = null;
    });
  }

  void _rotateImage() {
    setState(() {
      _rotationAngle += 90;
    });
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
              : Stack(
                  children: [
                    Center(
                      child: provider.isROISelectionActive
                          ? ROISelection(
                              imageBytes: selectedImageBytes!,
                              onROISelected: (croppedImage) {
                                // Handle extracted text

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
                                      onROISelected: (croppedImage) {},
                                    )
                                  : RotatedBox(
                                      quarterTurns: (_rotationAngle ~/ 90) % 4,
                                      child: PhotoView(
                                        imageProvider:
                                            MemoryImage(selectedImageBytes!),
                                        minScale:
                                            PhotoViewComputedScale.contained,
                                        maxScale:
                                            PhotoViewComputedScale.contained * 1,
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
                  ],
                );
        },
      ),
    );
  }
}
