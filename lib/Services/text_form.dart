import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:demo_text_extractor/screens/roi_selection.dart';  
import 'package:demo_text_extractor/Services/api_fast.dart';  
import 'package:demo_text_extractor/const.dart';

class IconButtonForText extends StatelessWidget {
  const IconButtonForText({
    super.key,
    required this.field,
    required this.onExtract,
  });

  final String field;
  final Function(String) onExtract;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.text_fields, color: Colors.blueGrey),
      onPressed: () => onExtract(field),
    );
  }
}

// ignore: use_key_in_widget_constructors
class CustomForm extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _CustomFormState createState() => _CustomFormState();
}

class _CustomFormState extends State<CustomForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // ignore: unused_element
  void _clearField(TextEditingController controller) {
    controller.clear();
  }

  // Function to handle ROI selection and text extraction
  void _onROISelected(String field) {
    if (selectedImageBytes == null || selectedImageBytes!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an Image first')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ROISelection(
          onROISelected: (croppedImage) {
            _extractTextFromImage(croppedImage, field);
          },
          imageBytes: selectedImageBytes!,
        ),
      ),
    );
  }

  // Extract text from cropped image and update the corresponding field
  Future<void> _extractTextFromImage(Uint8List croppedImage, String field) async {
 OCRService apiService =OCRService();
  String? extractedText = await apiService.extractTextFromImage(croppedImage);

  if (extractedText != null && extractedText.isNotEmpty) {
    setState(() {
      // Update the appropriate field based on the selected field
      switch (field) {
        case "Name":
          _nameController.text = extractedText;
          break;
        case "Pincode":
          _pincodeController.text = extractedText;
          break;
        case "Phone":
          _phoneController.text = extractedText;
          break;
        case "Gender":
          _genderController.text = extractedText;
          break;
        case "Date of Birth":
          _dobController.text = extractedText;
          break;
        case "Address":
          _addressController.text = extractedText;
          break;
        default:
          break;
      }
    });
  } else {
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to extract text.')),
    );
  }
}

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form Submitted Successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Name Field
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter name';
                      }
                      return null;
                    },
                  ),
                ),
                IconButtonForText(
                  field: 'Name',
                  onExtract: _onROISelected,
                ),
              ],
            ),
            // Pincode Field
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _pincodeController,
                    decoration: const InputDecoration(labelText: 'Pincode'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter pincode';
                      }
                      return null;
                    },
                  ),
                ),
                IconButtonForText(
                  field: 'Pincode',
                  onExtract: _onROISelected,
                ),
              ],
            ),
            // Phone Field
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter phone';
                      }
                      return null;
                    },
                  ),
                ),
                IconButtonForText(
                  field: 'Phone',
                  onExtract: _onROISelected,
                ),
              ],
            ),
            // Gender Field
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _genderController,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter gender';
                      }
                      return null;
                    },
                  ),
                ),
                IconButtonForText(
                  field: 'Gender',
                  onExtract: _onROISelected,
                ),
              ],
            ),
            // Date of Birth Field
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _dobController,
                    decoration: const InputDecoration(labelText: 'Date of Birth'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter date of birth';
                      }
                      return null;
                    },
                  ),
                ),
                IconButtonForText(
                  field: 'Date of Birth',
                  onExtract: _onROISelected,
                ),
              ],
            ),
            // Address Field
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter address';
                      }
                      return null;
                    },
                  ),
                ),
                IconButtonForText(
                  field: 'Address',
                  onExtract: _onROISelected,
                ),
              ],
            ),
             SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
