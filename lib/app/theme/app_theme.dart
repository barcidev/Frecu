import 'package:flutter/material.dart';
import 'package:frecu/core/design/tokens/fr_colors.dart';
import 'package:frecu/core/design/tokens/fr_motion.dart';
import 'package:frecu/core/design/tokens/fr_radii.dart';
import 'package:frecu/core/design/tokens/fr_space.dart';
import 'package:frecu/core/design/tokens/fr_type.dart';

/// Temas claro y oscuro de Portadora, construidos desde los mismos tokens.
///
/// Los componentes Material se sobrescriben para que nada genérico se cuele.
/// La señal (#C4E05C) rellena en ambos temas; todo lo que la usa como letra
/// (botón de texto, foco, cursor) usa `signalFg`, que de día es tinta.
abstract final class AppTheme {
  /// Tema de día.
  static ThemeData get light => _build(FrColors.light, Brightness.light);

  /// Tema de noche.
  static ThemeData get dark => _build(FrColors.dark, Brightness.dark);

  static ThemeData _build(FrColors c, Brightness brightness) {
    const type = FrType.standard;
    const radii = FrRadii.standard;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: _scheme(c, brightness),
      scaffoldBackgroundColor: c.bg0,
      canvasColor: c.bg0,
      fontFamily: FrFonts.ui,
      textTheme: _textTheme(c, type),
      splashColor: c.touch,
      highlightColor: Colors.transparent,
      iconTheme: IconThemeData(color: c.tx1),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.signalFg,
        selectionColor: c.signal.withValues(alpha: 0.3),
        selectionHandleColor: c.signalFg,
      ),
      extensions: [c, type, FrSpace.standard, radii, FrMotion.standard],
      appBarTheme: _appBar(c, type),
      filledButtonTheme: _Buttons.filled(c, type, radii),
      elevatedButtonTheme: _Buttons.elevated(c, type, radii),
      outlinedButtonTheme: _Buttons.outlined(c, type, radii),
      textButtonTheme: _Buttons.text(c, type, radii),
      segmentedButtonTheme: _Buttons.segmented(c, type, radii),
      inputDecorationTheme: _input(c, type, radii),
      cardTheme: _Surfaces.card(c, radii),
      listTileTheme: _Surfaces.listTile(c, type),
      dividerTheme: DividerThemeData(color: c.line1, thickness: 1),
      bottomSheetTheme: _Surfaces.bottomSheet(c, radii),
      dialogTheme: _Surfaces.dialog(c, type, radii),
      snackBarTheme: _Surfaces.snackBar(c, type, radii),
      chipTheme: _Surfaces.chip(c, type, radii),
      switchTheme: _Controls.switches(c),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.signalFg,
        linearTrackColor: c.bg3,
        circularTrackColor: Colors.transparent,
      ),
    );
  }

  static ColorScheme _scheme(FrColors c, Brightness brightness) {
    return ColorScheme(
      brightness: brightness,
      primary: c.signal,
      onPrimary: c.signalInk,
      primaryContainer: c.signal,
      onPrimaryContainer: c.signalInk,
      secondary: c.bg3,
      onSecondary: c.tx1,
      secondaryContainer: c.bg3,
      onSecondaryContainer: c.tx1,
      tertiary: c.p1,
      onTertiary: c.bg0,
      error: c.alert,
      onError: c.bg1,
      errorContainer: c.alert.withValues(alpha: 0.12),
      onErrorContainer: c.alertTx,
      surface: c.bg1,
      onSurface: c.tx1,
      onSurfaceVariant: c.tx2,
      surfaceDim: c.bg0,
      surfaceBright: c.bg2,
      surfaceContainerLowest: c.bg0,
      surfaceContainerLow: c.bg1,
      surfaceContainer: c.bg2,
      surfaceContainerHigh: c.bg3,
      surfaceContainerHighest: c.bg4,
      outline: c.line2,
      outlineVariant: c.line1,
      shadow: c.shadow,
      scrim: c.scrim,
      inverseSurface: c.tx1,
      onInverseSurface: c.bg1,
      // Sobre la superficie inversa: tinta de noche (fondo claro) y verde de día.
      inversePrimary: brightness == Brightness.dark ? c.signalInk : c.signal,
      surfaceTint: Colors.transparent,
    );
  }

  static TextTheme _textTheme(FrColors c, FrType type) {
    return TextTheme(
      displayLarge: type.display,
      displayMedium: type.display,
      displaySmall: type.display,
      headlineLarge: type.titleL,
      headlineMedium: type.titleL,
      headlineSmall: type.titleL,
      titleLarge: type.title,
      titleMedium: type.title,
      titleSmall: type.body,
      bodyLarge: type.bodyL,
      bodyMedium: type.body,
      bodySmall: type.bodyS,
      labelLarge: type.button,
      labelMedium: type.label,
      labelSmall: type.labelS,
    ).apply(bodyColor: c.tx1, displayColor: c.tx1);
  }

  static AppBarThemeData _appBar(FrColors c, FrType type) {
    return AppBarThemeData(
      backgroundColor: c.bg0,
      foregroundColor: c.tx1,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: type.title.copyWith(color: c.tx1),
    );
  }

  static InputDecorationThemeData _input(
    FrColors c,
    FrType type,
    FrRadii radii,
  ) {
    OutlineInputBorder border(Color color, [double width = 1]) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(radii.m),
        borderSide: BorderSide(color: color, width: width),
      );
    }

    // De noche el foco es verde; de día, el aro de tinta.
    final focus = c.ledRing ?? c.signal;
    return InputDecorationThemeData(
      filled: true,
      fillColor: c.bg2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      labelStyle: type.body.copyWith(color: c.tx3),
      floatingLabelStyle: type.body.copyWith(color: c.tx2),
      hintStyle: type.body.copyWith(color: c.tx4),
      helperStyle: type.bodyS.copyWith(color: c.tx3),
      errorStyle: type.bodyS.copyWith(color: c.alert),
      prefixIconColor: c.tx3,
      suffixIconColor: c.tx3,
      border: border(c.line1),
      enabledBorder: border(c.line1),
      disabledBorder: border(c.line1),
      focusedBorder: border(focus, 1.25),
      errorBorder: border(c.alert),
      focusedErrorBorder: border(c.alert, 1.25),
    );
  }
}

/// Forma continua (superelipse) de Portadora.
OutlinedBorder _shape(double radius, [BorderSide side = BorderSide.none]) {
  return RoundedSuperellipseBorder(
    borderRadius: BorderRadius.circular(radius),
    side: side,
  );
}

/// Botones: 56 dp de alto mínimo, radio `btn` y texto `button`.
abstract final class _Buttons {
  static const Size _minimum = Size(64, 56);
  static const EdgeInsets _padding = EdgeInsets.symmetric(horizontal: 22);

  static FilledButtonThemeData filled(FrColors c, FrType type, FrRadii r) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.signal,
        foregroundColor: c.signalInk,
        disabledBackgroundColor: c.bg3,
        disabledForegroundColor: c.tx4,
        minimumSize: _minimum,
        padding: _padding,
        textStyle: type.button,
        shape: _shape(r.btn),
      ),
    );
  }

  static ElevatedButtonThemeData elevated(FrColors c, FrType type, FrRadii r) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: c.bg2,
        foregroundColor: c.tx1,
        elevation: 0,
        minimumSize: _minimum,
        padding: _padding,
        textStyle: type.button,
        shape: _shape(r.btn, BorderSide(color: c.line2)),
      ),
    );
  }

  static OutlinedButtonThemeData outlined(FrColors c, FrType type, FrRadii r) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.tx1,
        side: BorderSide(color: c.line2),
        minimumSize: _minimum,
        padding: _padding,
        textStyle: type.button,
        shape: _shape(r.btn),
      ),
    );
  }

  static TextButtonThemeData text(FrColors c, FrType type, FrRadii r) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.signalFg,
        textStyle: type.button,
        shape: _shape(r.btn),
      ),
    );
  }

  static SegmentedButtonThemeData segmented(
    FrColors c,
    FrType type,
    FrRadii r,
  ) {
    return SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: c.bg1,
        foregroundColor: c.tx3,
        selectedBackgroundColor: c.bg3,
        selectedForegroundColor: c.tx1,
        side: BorderSide(color: c.line1),
        shape: _shape(r.m),
        textStyle: type.label,
        minimumSize: const Size(48, 48),
      ),
    );
  }
}

/// Superficies: tarjetas, listas, hojas, diálogos, avisos y chips.
abstract final class _Surfaces {
  static CardThemeData card(FrColors c, FrRadii r) {
    return CardThemeData(
      color: c.bg1,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      shape: _shape(r.l, BorderSide(color: c.line1)),
    );
  }

  static ListTileThemeData listTile(FrColors c, FrType type) {
    return ListTileThemeData(
      iconColor: c.tx2,
      textColor: c.tx1,
      selectedColor: c.signalFg,
      titleTextStyle: type.bodyL.copyWith(color: c.tx1),
      subtitleTextStyle: type.body.copyWith(color: c.tx2),
    );
  }

  static BottomSheetThemeData bottomSheet(FrColors c, FrRadii r) {
    return BottomSheetThemeData(
      backgroundColor: c.sheetA,
      modalBackgroundColor: c.sheetA,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: c.scrim,
      dragHandleColor: c.bg4,
      shape: RoundedSuperellipseBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(r.sheet)),
      ),
    );
  }

  static DialogThemeData dialog(FrColors c, FrType type, FrRadii r) {
    return DialogThemeData(
      backgroundColor: c.sheetA,
      surfaceTintColor: Colors.transparent,
      barrierColor: c.scrim,
      shape: _shape(r.xl),
      titleTextStyle: type.titleL.copyWith(color: c.tx1),
      contentTextStyle: type.body.copyWith(color: c.tx2),
    );
  }

  static SnackBarThemeData snackBar(FrColors c, FrType type, FrRadii r) {
    return SnackBarThemeData(
      backgroundColor: c.bg3,
      contentTextStyle: type.body.copyWith(color: c.tx1),
      actionTextColor: c.signalFg,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: _shape(r.m, BorderSide(color: c.line2)),
    );
  }

  static ChipThemeData chip(FrColors c, FrType type, FrRadii r) {
    return ChipThemeData(
      backgroundColor: c.bg2,
      side: BorderSide(color: c.line1),
      labelStyle: type.label.copyWith(color: c.tx2),
      shape: _shape(r.s, BorderSide(color: c.line1)),
    );
  }
}

/// Controles de selección.
abstract final class _Controls {
  static SwitchThemeData switches(FrColors c) {
    bool on(Set<WidgetState> states) => states.contains(WidgetState.selected);
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => on(states) ? c.signalInk : c.tx3,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => on(states) ? c.signal : c.bg3,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => on(states) ? Colors.transparent : c.line2,
      ),
    );
  }
}
