import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const primary = Color(0xFF0056B3); // read from colors.css placeholder (e.g. #0056B3)
  static const primaryLight = Color(0xFFE6F0FA);
  static const secondary = Color(0xFF6C757D);
  
  // Semantic
  static const success = Color(0xFF28A745);
  static const warning = Color(0xFFFFC107);
  static const danger = Color(0xFFDC3545);
  
  // Neutral
  static const background = Color(0xFFF8F9FA);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF212529);
  static const textSecondary = Color(0xFF6C757D);
}
