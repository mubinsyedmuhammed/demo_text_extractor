import 'dart:typed_data';
import 'package:demo_text_extractor/screens/roi_selection.dart';
import 'package:flutter/material.dart';
import 'package:demo_text_extractor/Services/api_fast.dart';
import 'package:demo_text_extractor/const.dart';

class CustomForm extends StatefulWidget {
  const CustomForm({super.key});

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

  // final Rect _roiRect = Rect.zero;

  void _onROISelected(String field) {
    if (selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an Image first')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select ROI for $field'),
          content: ROISelection(
            imageBytes: selectedImageBytes!,
            onROISelected: (croppedImage) {
              _extractTextFromImage(field, croppedImage);
              Navigator.of(context).pop();
            },
          ),
        );
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
        }
      });
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to extract text...')),
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
            _buildField("Name", _nameController),
            _buildField("Pincode", _pincodeController),
            _buildField("Phone", _phoneController),
            _buildField("Gender", _genderController),
            _buildField("Date of Birth", _dobController),
            _buildField("Address", _addressController),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String fieldName, TextEditingController controller) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(labelText: fieldName),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $fieldName';
              }
              return null;
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.crop, color: Colors.blueGrey),
          onPressed: () => _onROISelected(fieldName),
        ),
      ],
    );
  }
}
