import 'package:flutter/material.dart';

class RoiProvider with ChangeNotifier {
  bool _isROISelectionActive = false;
  String? _selectedField;
  Function(String)? onROICompleted;

  bool get isROISelectionActive => _isROISelectionActive;
  String? get selectedField => _selectedField;

  void setContext(BuildContext context, BuildContext contexts) {
    contexts = context;
  }

  void setSelectedField(String field) {
    _selectedField = field;
    notifyListeners();
  }

  void enableROISelection() {
    _isROISelectionActive = true;
    notifyListeners();
  }

  void disableROISelection() {
    _isROISelectionActive = false;
    _selectedField = null;
    onROICompleted = null;
    notifyListeners();
  }

  void cancelROISelection() {
    _isROISelectionActive = false;
    _selectedField = null;
    onROICompleted = null;
    notifyListeners();
  }

  void processExtractedText(String text) {
    if (onROICompleted != null) {
      onROICompleted!(text);
    }
  }
}
