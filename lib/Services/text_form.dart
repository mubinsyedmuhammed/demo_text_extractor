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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<RoiProvider>(context, listen: false);
      provider.onTextExtracted = (field, text) {
        if (text.isNotEmpty) {
          setState(() {
            switch (field) {
              case "Name":
                _updateText(nameController, text);
                break;
              case "Pincode":
                _updateText(pincodeController, text);
                break;
              case "Phone":
                _updateText(phoneController, text);
                break;
              case "Gender":
                _updateText(genderController, text);
                break;
              case "Date of Birth":
                _updateText(dobController, text);
                break;
              case "Address":
                _updateText(addressController, text);
                break;
            }
          });
        } else {
          _showError('Failed to extract text...');
        }
      };
    });
  }

  Future<void> onROISelected(String field, RoiProvider provider) async {
    try {
      if (selectedImageBytes == null) {
        throw Exception('Please upload an image first');
      }

      provider.startROISelection(field);
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form Submitted Successfully!')),
      );
    }
  }

  void _updateText(TextEditingController controller, String newText) {
    if (controller.text.isNotEmpty) {
      // If text already exists, append new text with a space
      controller.text = '${controller.text} $newText';
    } else {
      controller.text = newText;
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
        final isActiveField = provider.isROISelectionActive && 
                            provider.currentField == fieldName;
        return Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: fieldName,
                  enabledBorder: isActiveField 
                    ? const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green),
                      )
                    : null,
                  suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => controller.clear()),
                      )
                    : null,
                ),
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
                isActiveField ? Icons.close : Icons.crop,
                color: isActiveField ? Colors.red : Colors.blueGrey,
              ),
              onPressed: isActiveField
                  ? () => provider.cancelROISelection()
                  : () => onROISelected(fieldName, provider),
            ),
          ],
        );
      },
    );
  }
}

