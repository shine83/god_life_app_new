import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import '../design_tokens.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        background: AppColors.background,
        surface: AppColors.surface,
        error: AppColors.error,
      ),

      // 텍스트 테마
      textTheme: TextTheme(
        displayLarge: AppTextStyles.headline1,
        titleLarge: AppTextStyles.headline6,
        bodyMedium: AppTextStyles.bodyText2,
        // 필요 시 subtitle1→titleMedium, caption→bodySmall 등 추가 매핑
      ),

      // 버튼 테마
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          textStyle: AppTextStyles.bodyText2.copyWith(color: Colors.white),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingMedium,
            vertical: DesignTokens.spacingSmall,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: DesignTokens.borderRadiusDefault,
          ),
          elevation: 4,
          shadowColor: Colors.black26,
        ),
      ),

      // 입력 필드 테마
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(DesignTokens.spacingMedium),
        border: OutlineInputBorder(
          borderRadius: DesignTokens.borderRadiusDefault,
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
      ),

      // 카드 테마
      cardTheme: CardThemeData(
        margin: const EdgeInsets.all(DesignTokens.spacingMedium),
        shape: RoundedRectangleBorder(
          borderRadius: DesignTokens.borderRadiusDefault,
        ),
        elevation: 4,
        shadowColor: Colors.black12,
      ),
    );
  }
}
