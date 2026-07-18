import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFFE94E34); // Vermilion
  static const Color primaryLight = Color(0xFFFF7256);
  static const Color primaryDark = Color(0xFFD03920);
  
  // Static references for quick access (typically light theme values)
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF9F9F9);
  static const Color surfaceElevated = Color(0xFFF0F0F0);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF737373);
  static const Color textHint = Color(0xFFA3A3A3);
  static const Color success = Color(0xFF28A745);
  static const Color error = Color(0xFFDC3545);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF17A2B8);
  static const Color timerActive = Color(0xFFE94E34);
  static const Color timerPaused = Color(0xFF737373);
  static const Color timerCompleted = Color(0xFF28A745);
  static const Color divider = Color(0xFFE5E5E5);
}

class AppTextStyles {
  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.1,
        letterSpacing: -1.0,
      );

  static TextStyle get displayMedium => GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle get headlineLarge => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  static TextStyle get headlineMedium => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get headlineSmall => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.6,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: 0.3,
      );

  static TextStyle get labelMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.2,
      );

  static TextStyle get timerDisplay => GoogleFonts.plusJakartaSans(
        fontSize: 64,
        fontWeight: FontWeight.w800,
        color: AppColors.primary,
        letterSpacing: -2,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}


class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color success;
  final Color error;
  final Color warning;
  final Color info;
  final Color timerActive;
  final Color timerPaused;
  final Color timerCompleted;
  final Color divider;

  const AppColorsExtension({
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.success,
    required this.error,
    required this.warning,
    required this.info,
    required this.timerActive,
    required this.timerPaused,
    required this.timerCompleted,
    required this.divider,
  });

  @override
  ThemeExtension<AppColorsExtension> copyWith({
    Color? primary,
    Color? primaryLight,
    Color? primaryDark,
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? card,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? success,
    Color? error,
    Color? warning,
    Color? info,
    Color? timerActive,
    Color? timerPaused,
    Color? timerCompleted,
    Color? divider,
  }) {
    return AppColorsExtension(
      primary: primary ?? this.primary,
      primaryLight: primaryLight ?? this.primaryLight,
      primaryDark: primaryDark ?? this.primaryDark,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      card: card ?? this.card,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      success: success ?? this.success,
      error: error ?? this.error,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      timerActive: timerActive ?? this.timerActive,
      timerPaused: timerPaused ?? this.timerPaused,
      timerCompleted: timerCompleted ?? this.timerCompleted,
      divider: divider ?? this.divider,
    );
  }

  @override
  ThemeExtension<AppColorsExtension> lerp(
      ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      card: Color.lerp(card, other.card, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      success: Color.lerp(success, other.success, t)!,
      error: Color.lerp(error, other.error, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      timerActive: Color.lerp(timerActive, other.timerActive, t)!,
      timerPaused: Color.lerp(timerPaused, other.timerPaused, t)!,
      timerCompleted: Color.lerp(timerCompleted, other.timerCompleted, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
    );
  }
}

extension ThemeContextExtension on BuildContext {
  AppColorsExtension get colors => Theme.of(this).extension<AppColorsExtension>()!;
  TextTheme get textTheme => Theme.of(this).textTheme;
}

class AppTextStylesDynamic {
  static TextStyle displayLarge(Color color) => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.1,
        letterSpacing: -1.0,
      );

  static TextStyle displayMedium(Color color) => GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.2,
        letterSpacing: -0.5,
      );

  static TextStyle headlineLarge(Color color) => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.5,
      );

  static TextStyle headlineMedium(Color color) => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.3,
      );

  static TextStyle headlineSmall(Color color) => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle bodyLarge(Color color) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.6,
      );

  static TextStyle bodyMedium(Color color) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle bodySmall(Color color) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );

  static TextStyle labelLarge(Color color) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 0.3,
      );

  static TextStyle labelMedium(Color color) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 0.2,
      );

  static TextStyle timerDisplay(Color color) => GoogleFonts.plusJakartaSans(
        fontSize: 64,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: -2,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

class AppTheme {
  static const Color _primary = Color(0xFFE94E34);
  static const Color _primaryLight = Color(0xFFFF7256);
  static const Color _primaryDark = Color(0xFFD03920);

  static final AppColorsExtension _darkColors = AppColorsExtension(
    primary: _primary,
    primaryLight: _primaryLight,
    primaryDark: _primaryDark,
    background: const Color(0xFF050505),
    surface: const Color(0xFF141414),
    surfaceElevated: const Color(0xFF1F1F1F),
    card: const Color(0xFF141414),
    textPrimary: const Color(0xFFF5F5F5),
    textSecondary: const Color(0xFFA3A3A3),
    textHint: const Color(0xFF525252),
    success: const Color(0xFF4CAF50),
    error: const Color(0xFFE94E34),
    warning: const Color(0xFFFFC107),
    info: const Color(0xFF64B5F6),
    timerActive: _primary,
    timerPaused: const Color(0xFF525252),
    timerCompleted: const Color(0xFF4CAF50),
    divider: const Color(0xFF262626),
  );

  static final AppColorsExtension _lightColors = AppColorsExtension(
    primary: _primary,
    primaryLight: _primaryLight,
    primaryDark: _primaryDark,
    background: const Color(0xFFFFFFFF),
    surface: const Color(0xFFF9F9F9),
    surfaceElevated: const Color(0xFFF0F0F0),
    card: const Color(0xFFFFFFFF),
    textPrimary: const Color(0xFF111111),
    textSecondary: const Color(0xFF737373),
    textHint: const Color(0xFFA3A3A3),
    success: const Color(0xFF28A745),
    error: const Color(0xFFE94E34),
    warning: const Color(0xFFFFC107),
    info: const Color(0xFF17A2B8),
    timerActive: _primary,
    timerPaused: const Color(0xFF737373),
    timerCompleted: const Color(0xFF28A745),
    divider: const Color(0xFFE5E5E5),
  );

  static ThemeData get darkTheme => _buildTheme(Brightness.dark, _darkColors);
  static ThemeData get lightTheme => _buildTheme(Brightness.light, _lightColors);

  static ThemeData _buildTheme(Brightness brightness, AppColorsExtension colors) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      extensions: [colors],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.primary,
        onPrimary: Colors.white,
        secondary: colors.primaryLight,
        onSecondary: Colors.white,
        surface: colors.surface,
        onSurface: colors.textPrimary,
        error: colors.error,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStylesDynamic.displayLarge(colors.textPrimary),
        displayMedium: AppTextStylesDynamic.displayMedium(colors.textPrimary),
        headlineLarge: AppTextStylesDynamic.headlineLarge(colors.textPrimary),
        headlineMedium: AppTextStylesDynamic.headlineMedium(colors.textPrimary),
        headlineSmall: AppTextStylesDynamic.headlineSmall(colors.textPrimary),
        bodyLarge: AppTextStylesDynamic.bodyLarge(colors.textPrimary),
        bodyMedium: AppTextStylesDynamic.bodyMedium(colors.textPrimary),
        bodySmall: AppTextStylesDynamic.bodySmall(colors.textSecondary),
        labelLarge: AppTextStylesDynamic.labelLarge(colors.textPrimary),
        labelMedium: AppTextStylesDynamic.labelMedium(colors.textSecondary),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        elevation: 0,
        scrolledUnderElevation: 0, // No weird tint on scroll
        centerTitle: false,
        titleTextStyle: AppTextStylesDynamic.headlineLarge(colors.textPrimary),
        iconTheme: IconThemeData(color: colors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colors.divider.withOpacity(0.5), width: 1), // Subtle border
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999), // Pill shape
          ),
          textStyle: AppTextStylesDynamic.labelLarge(colors.textPrimary).copyWith(fontWeight: FontWeight.w700),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999), // Pill shape
          ),
          textStyle: AppTextStylesDynamic.labelLarge(colors.textPrimary).copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: AppTextStylesDynamic.labelLarge(colors.textPrimary).copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: AppTextStylesDynamic.bodyMedium(colors.textHint),
        labelStyle: AppTextStylesDynamic.bodyMedium(colors.textSecondary),
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceElevated,
        contentTextStyle: AppTextStylesDynamic.bodyMedium(colors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colors.surfaceElevated,
        selectedColor: colors.primary.withOpacity(0.2),
        labelStyle: AppTextStylesDynamic.labelMedium(colors.textPrimary),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)), // Pill shape
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected)
              ? Colors.white
              : colors.textSecondary,
        ),
        trackColor: MaterialStateProperty.resolveWith(
          (states) => states.contains(MaterialState.selected)
              ? colors.primary
              : colors.surfaceElevated,
        ),
        trackOutlineColor: const MaterialStatePropertyAll(Colors.transparent),
      ),
      iconTheme: IconThemeData(color: colors.textSecondary),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
        circularTrackColor: colors.surfaceElevated,
        linearTrackColor: colors.surfaceElevated,
      ),
    );
  }
}
