import 'package:flutter/material.dart';

class RoiProvider with ChangeNotifier {
  bool _isROISelectionActive = false;
  bool _isLoading = false;
  String? _currentField;
  Function(String, String)? onTextExtracted; // Callback for text extraction (field, text)

  bool get isROISelectionActive => _isROISelectionActive;
  bool get isLoading => _isLoading;
  String? get currentField => _currentField;

  void startROISelection(String field) {
    _isROISelectionActive = true;
    _currentField = field;
    notifyListeners();
  }

  void processTextExtraction(String text) {
    if (_currentField != null && onTextExtracted != null) {
      onTextExtracted!(_currentField!, text);
    }
    stopROISelection();
  }

  void stopROISelection() {
    _isROISelectionActive = false;
    _currentField = null;
    notifyListeners();
  }

  void cancelROISelection() {
    _isROISelectionActive = false;
    _currentField = null;
    notifyListeners();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
