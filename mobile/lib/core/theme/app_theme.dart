import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PremiumAppTheme {
  // Premium Color Palette
  static const Color primary = Color(0xFF1E3A8A); // Deep Navy Blue
  static const Color primaryLight = Color(0xFF3B82F6); // Ocean Blue
  static const Color primaryDark = Color(0xFF1E40AF); // Royal Blue

  // Emergency Colors
  static const Color emergency = Color(0xFFDC2626); // Vibrant Red
  static const Color emergencyLight = Color(0xFFEF4444); // Light Red
  static const Color emergencyDark = Color(0xFFB91C1C); // Dark Red

  // Status Colors
  static const Color success = Color(0xFF16A34A); // Emerald Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color info = Color(0xFF0EA5E9); // Sky Blue
  static const Color neutral = Color(0xFF6B7280); // Gray

  // Background Colors
  static const Color background = Color(0xFFF8FAFC); // Soft White-Blue
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B); // Dark Gray
  static const Color textSecondary = Color(0xFF64748B); // Medium Gray
  static const Color textDisabled = Color(0xFF9CA3AF); // Light Gray

  // Border & Dividers
  static const Color border = Color(0xFFE2E8F0); // Light Gray
  static const Color divider = Color(0xFFF1F5F9); // Very Light Gray

  // Typography System
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    letterSpacing: 0.1,
    height: 1.5,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    letterSpacing: 0.1,
    height: 1.5,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    letterSpacing: 0.2,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    letterSpacing: 0.2,
    height: 1.6,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    letterSpacing: 0.2,
    height: 1.6,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    letterSpacing: 0.2,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textDisabled,
    letterSpacing: 0.2,
    height: 1.4,
  );

  // Premium Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: headlineSmall,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
      ),

      // Bottom Navigation Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textDisabled,
        selectedLabelStyle: labelMedium.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: labelMedium,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style:
            ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              elevation: 2,
              textStyle: labelLarge.copyWith(fontWeight: FontWeight.w600),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              shadowColor: primary.withValues(alpha: 0.2),
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith<Color>((
                Set<WidgetState> states,
              ) {
                if (states.contains(WidgetState.pressed)) {
                  return Colors.white.withValues(alpha: 0.1);
                }
                return Colors.transparent;
              }),
            ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
          textStyle: labelLarge.copyWith(fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: labelLarge.copyWith(fontWeight: FontWeight.w500),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      // Card Theme
      cardTheme: const CardThemeData(
        color: cardBackground,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        margin: EdgeInsets.all(8),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: emergency, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: emergency, width: 2),
        ),
        hintStyle: bodyMedium.copyWith(color: textDisabled),
        labelStyle: bodyMedium.copyWith(color: textSecondary),
        errorStyle: bodySmall.copyWith(color: emergency),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(color: textPrimary, size: 24),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        tileColor: surface,
        iconColor: primary,
        textColor: textPrimary,
        titleTextStyle: titleMedium,
        subtitleTextStyle: bodySmall,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // Dialog Theme
      dialogTheme: const DialogThemeData(
        backgroundColor: surface,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        circularTrackColor: border,
        linearTrackColor: border,
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: bodyMedium.copyWith(color: Colors.white),
        actionTextColor: primaryLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),
    );
  }

  // Emergency Theme Variant
  static ThemeData get emergencyTheme {
    return lightTheme.copyWith(
      primaryColor: emergency,
      colorScheme: ColorScheme.light(
        primary: emergency,
        secondary: emergencyLight,
        error: emergency,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emergency,
          foregroundColor: Colors.white,
          elevation: 4,
          textStyle: labelLarge.copyWith(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: emergency.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  // Helper Methods for Status Colors
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return warning;
      case 'assigned':
        return info;
      case 'in_progress':
        return primary;
      case 'resolved':
        return success;
      case 'closed':
        return neutral;
      default:
        return neutral;
    }
  }

  static Color getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return success;
      case 'medium':
        return warning;
      case 'high':
        return emergency;
      case 'critical':
        return emergencyDark;
      default:
        return neutral;
    }
  }
}

extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));

    return hslDark.toColor();
  }

  Color lighten([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);

    final hsl = HSLColor.fromColor(this);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );

    return hslLight.toColor();
  }
}
