import 'dart:developer';

import 'package:demo_text_extractor/Services/api_fast.dart';
import 'package:demo_text_extractor/Services/getx.dart';
import 'package:demo_text_extractor/const.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomForm extends StatefulWidget {
  const CustomForm({super.key});

  @override
  // ignore: library_private_types_in_public_api
  CustomFormState createState() => CustomFormState();
}

class CustomFormState extends State<CustomForm> {
  final _formKey = GlobalKey<FormState>();

  Future<void> onROISelected(String field, RoiProvider provider) async {
    provider.enableROISelection();

    if (selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload an Image first...')),
      );
      return;
    }

    if (croppedImages != null) {
      log('its working');
      OCRService apiService = OCRService();
      String? extractedText =
        await apiService.extractTextFromImageOcr(croppedImages!);

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
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No ROI selected.')),
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
            _buildField("Name", nameController),
            _buildField("Pincode", pincodeController),
            _buildField("Phone", phoneController),
            _buildField("Gender", genderController),
            _buildField("Date of Birth", dobController),
            _buildField("Address", addressController),
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
    return Consumer<RoiProvider>(
      builder: (context, provider, child) {
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
              icon: Icon(
                Icons.crop,
                color: provider.isROISelectionActive
                    ? Colors.green
                    : Colors.blueGrey,
              ),
              onPressed: provider.isROISelectionActive
                  ? null
                  : () => onROISelected(fieldName, provider),
            ),
          ],
        );
      },
    );
  }
}
