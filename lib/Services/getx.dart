import 'package:flutter/material.dart';

class RoiProvider with ChangeNotifier {
  bool _isROISelectionActive = false;

  bool get isROISelectionActive => _isROISelectionActive;

  void enableROISelection() {
    _isROISelectionActive = true;
    notifyListeners();
  }

  void disableROISelection() {
    _isROISelectionActive = false;
    notifyListeners();
  }
}
