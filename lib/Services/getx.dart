import 'package:flutter/material.dart';

class RoiProvider with ChangeNotifier {
  bool _isROISelectionActive = false;
  BuildContext? contexts;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  bool get isROISelectionActive => _isROISelectionActive;

  void setContext(BuildContext context) {
    contexts = context;
  }

  Future<void> enableROISelection() async {
    _isROISelectionActive = true;
    notifyListeners();
  }

  void disableROISelection() {
    _isROISelectionActive = false;
    notifyListeners();
  }

void updateField(String field, String value) {
  switch (field) {
    case "Name":
      nameController.text = value;
      break;
    case "Pincode":
      pincodeController.text = value;
      break;
    case "Phone":
      phoneController.text = value;
      break;
    case "Gender":
      genderController.text = value;
      break;
    case "Date of Birth":
      dobController.text = value;
      break;
    case "Address":
      addressController.text = value;
      break;
  }
  notifyListeners();
}

}
