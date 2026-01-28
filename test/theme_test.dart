
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lamp_app/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AppTheme', () {
    test('Primary color is correct', () {
      expect(AppColors.primary, const Color(0xFF6B4EAB));
    });



    test('Light theme has correct brightness', () {
      final theme = AppTheme.lightTheme;
      expect(theme.brightness, Brightness.light);
    });
  });
}
