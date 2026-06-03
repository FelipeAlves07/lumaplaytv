import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Arial',
      useMaterial3: false,
    );
  }
}