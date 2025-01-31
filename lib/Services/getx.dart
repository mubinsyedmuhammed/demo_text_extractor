import 'package:flutter/material.dart';

class RoiProvider with ChangeNotifier {
  bool _isROISelectionActive = false;
  BuildContext? contexts;

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
}
