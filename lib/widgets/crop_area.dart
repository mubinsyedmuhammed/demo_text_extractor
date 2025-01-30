import 'dart:typed_data';

import 'package:demo_text_extractor/Services/api_fast.dart';
import 'package:demo_text_extractor/Services/getx.dart';
import 'package:demo_text_extractor/const.dart';
import 'package:demo_text_extractor/screens/roi_selection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


class CropAreaWidget extends StatefulWidget {
  const CropAreaWidget({super.key});

  @override
  State<CropAreaWidget> createState() => _CropAreaWidgetState();
}

class _CropAreaWidgetState extends State<CropAreaWidget> {
  @override
  Widget build(BuildContext context) {
    return ROISelection(
      imageBytes: selectedImageBytes!,
      onROISelected: (croppedImage) {
        _extractTextFromImage(selectedField!, croppedImage);
        setState(() {
          croppedImages = croppedImage;
          Provider.of<RoiProvider>(context, listen: false).disableROISelection();
          selectedField = null; // Reset selected field
        });
      },
    );
  }

  Future<void> _extractTextFromImage(String field, Uint8List croppedImage) async {
    OCRService apiService = OCRService();
    String? extractedText = await apiService.extractTextFromImage(croppedImage);

    if (extractedText.isNotEmpty) {
      setState(() {
        switch (field) {
          case "Name":
            nameController.text = extractedText;
            break;
          case "Pincode":
            pincodeController.text = extractedText;
            break;
          case "Phone":
            phoneController.text = extractedText;
            break;
          case "Gender":
            genderController.text = extractedText;
            break;
          case "Date of Birth":
            dobController.text = extractedText;
            break;
          case "Address":
            addressController.text = extractedText;
            break;
        }
      });
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to extract text...')),
      );
    }
  }
}