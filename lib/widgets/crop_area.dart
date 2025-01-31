// import 'dart:developer';
// import 'dart:typed_data';

// import 'package:demo_text_extractor/Services/api_fast.dart';
// import 'package:demo_text_extractor/const.dart';
// import 'package:demo_text_extractor/screens/roi_selection.dart';
// import 'package:flutter/material.dart';

// class CropAreaWidget extends StatefulWidget {
//   final Uint8List imageBytes;
//   final String field;
  
//   const CropAreaWidget({super.key, required this.imageBytes, required this.field});

//   @override
//   State<CropAreaWidget> createState() => CropAreaWidgetState();
// }

// class CropAreaWidgetState extends State<CropAreaWidget> {
//   @override
//   Widget build(BuildContext context) {
//     return ROISelection(
//       imageBytes: widget.imageBytes,
//       onROISelected: (croppedImage) async {
//         await extractTextFromImage(widget.field, croppedImage);
//       },
//     );
//   }

//   Future<void> extractTextFromImage(String field, Uint8List croppedImage) async {
//     OCRService apiService = OCRService();
//     String? extractedText = await apiService.extractTextFromImageOcr(croppedImage);

//     log(extractedText);

//     if (extractedText.isNotEmpty) {
//       setState(() {
//         switch (field) {
//           case "Name":
//             nameController.text = extractedText;
//             break;
//           case "Pincode":
//             pincodeController.text = extractedText;
//             break;
//           case "Phone":
//             phoneController.text = extractedText;
//             break;
//           case "Gender":
//             genderController.text = extractedText;
//             break;
//           case "Date of Birth":
//             dobController.text = extractedText;
//             break;
//           case "Address":
//             addressController.text = extractedText;
//             break;
//           }
//         }
//       );
//     } else {
//       // ignore: use_build_context_synchronously
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Failed to extract text...')),
//       );
//     }
//   }
// }