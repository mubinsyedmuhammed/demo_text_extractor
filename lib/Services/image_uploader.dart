import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:demo_text_extractor/Services/api_fast.dart';
import 'package:demo_text_extractor/screens/roi_selection.dart';
import '/const.dart';

class ImageUploader extends StatefulWidget {
  const ImageUploader({super.key});

  @override
  // ignore: library_private_types_in_public_api
  ImageUploaderState createState() => ImageUploaderState();
}

class ImageUploaderState extends State<ImageUploader> {
  final bool _showROI = false;
  String? extractedText;

  // Image picker function
  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        selectedImageBytes = result.files.single.bytes;  // This now sets the global variable
      });
    } 
    else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected or invalid file')),
      );
    }
  }

  void _clearImage() {  
    setState(() {
      selectedImageBytes = null;  // This now clears the global variable
      extractedText = null;
    });
  }

  void extractText(Uint8List selectedImageBytes) async {
    OCRService apiService = OCRService();
    String? extractedText = await apiService.extractTextFromImage(selectedImageBytes);
    setState(() {
      extractedText = extractedText;
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
      body: selectedImageBytes == null
          ? Center(
              child: ElevatedButton(
                onPressed: _pickImage,
                child: const Text("Upload Image"),
              ),
            )
          : Stack(
              children: [
                Center(
                  child: _showROI
                      ? ROISelection(
                          imageBytes: selectedImageBytes!,
                          onROISelected: (croppedImage) {
                            extractText(croppedImage);
                          },
                        )
                      : Image.memory(selectedImageBytes!),
                ),
                Positioned(
                  top: 25,
                  right: 3,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Colors.red),
                    child: IconButton(
                      onPressed: _clearImage,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ),
                if (extractedText != null)
                  Positioned(
                    bottom: 25,
                    left: 15,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            // ignore: deprecated_member_use
                            color: Colors.black.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Text(
                        extractedText!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
