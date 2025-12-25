import 'package:flutter/material.dart';

class AccessibilitySettings extends ChangeNotifier {
  double _textScale = 1.0; // 100%
  bool _highContrast = false;
  double _lineHeight = 1.0;
  double _letterSpacing = 0.0; // u logical px
  bool _boldText = false;
  bool _largeControls = false;

  double get textScale => _textScale;
  bool get highContrast => _highContrast;
  double get lineHeight => _lineHeight;
  double get letterSpacing => _letterSpacing;
  bool get boldText => _boldText;
  bool get largeControls => _largeControls;
  
  void setTextScale(double value) {
    _textScale = value.clamp(1.0, 2.0);
    notifyListeners();
  }

  void toggleHighContrast(bool value) {
    _highContrast = value;
    notifyListeners();
  }

  void setLineHeight(double value) {
    _lineHeight = value.clamp(1.0, 1.8);
    notifyListeners();
  }

  void setLetterSpacing(double value) {
    _letterSpacing = value.clamp(0.0, 1.5);
    notifyListeners();
  }

  void setBoldText(bool value) {
    _boldText = value;
    notifyListeners();
  }

  void setLargeControls(bool value) {
    _largeControls = value;
    notifyListeners();
  }
}
