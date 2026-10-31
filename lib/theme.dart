import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'state.dart';

// Цвета и шрифты как на сайте УМНО:
// заголовки и кнопки — Unbounded, текст — Manrope,
// в детском режиме всё — Nunito.
const Color kInk = Color(0xFF111111);
const Color kGrey = Color(0xFF6B6B6B);
const Color kSoft = Color(0xFFF0EFEE);
const Color kCream = Color(0xFFFBF7F3);
const Color kKidBlue = Color(0xFF4F8EF7);
const Color kKidInk = Color(0xFF1F2A44);

/// Стиль заголовка. Размер пересчитывается: Unbounded шире обычных шрифтов.
TextStyle hd(double size, {Color? color}) {
  if (app.kidMode) {
    return GoogleFonts.nunito(
        fontSize: size, fontWeight: FontWeight.w900, color: color);
  }
  return GoogleFonts.unbounded(
      fontSize: size * 0.8,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      height: 1.2,
      color: color);
}

/// Подпись кнопки.
TextStyle btnText(bool kid, [double? size]) => kid
    ? GoogleFonts.nunito(fontSize: size ?? 17, fontWeight: FontWeight.w900)
    : GoogleFonts.unbounded(fontSize: size ?? 13.5, fontWeight: FontWeight.w500);

final Map<String, ThemeData> _cache = {};

/// Темы создаются один раз для каждого цвета и режима, потом берутся из кэша.
ThemeData themeFor(Color seed, {required bool kid}) {
  final key = '${seed.value}|$kid';
  return _cache.putIfAbsent(key, () => _build(seed, kid));
}

ThemeData _build(Color seed, bool kid) {
  final ink = kid ? kKidInk : kInk;
  final accent = kid ? kKidBlue : seed;
  final scheme = ColorScheme.fromSeed(seedColor: seed).copyWith(
    primary: seed,
    onSurface: ink,
    surface: Colors.white,
    surfaceContainerHigh: Colors.white,
    surfaceTint: Colors.transparent,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme).textTheme;
  final body = (kid
          ? GoogleFonts.nunitoTextTheme(base)
          : GoogleFonts.manropeTextTheme(base))
      .apply(bodyColor: ink, displayColor: ink);
  TextStyle? head(TextStyle? s) => kid
      ? GoogleFonts.nunito(textStyle: s, fontWeight: FontWeight.w900)
      : GoogleFonts.unbounded(
          textStyle: s, fontWeight: FontWeight.w700, letterSpacing: -0.3);
  TextStyle? bold(TextStyle? s) =>
      kid ? s?.copyWith(fontWeight: FontWeight.w700) : s;
  final text = body.copyWith(
    displayLarge: head(body.displayLarge),
    displayMedium: head(body.displayMedium),
    displaySmall: head(body.displaySmall),
    headlineLarge: head(body.headlineLarge),
    headlineMedium: head(body.headlineMedium),
    headlineSmall: head(body.headlineSmall),
    titleLarge: head(body.titleLarge),
    bodyLarge: bold(body.bodyLarge),
    bodyMedium: bold(body.bodyMedium?.copyWith(fontSize: kid ? 16 : null)),
    bodySmall: bold(body.bodySmall),
  );

  OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(kid ? 22 : 28),
        borderSide: BorderSide(color: c, width: w),
      );
  final pad = EdgeInsets.symmetric(horizontal: kid ? 26 : 28, vertical: 15);
  final shape = kid
      ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
      : const StadiumBorder();

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    textTheme: text,
    scaffoldBackgroundColor: kCream,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: ink,
      titleTextStyle: head(text.titleLarge?.copyWith(fontSize: kid ? 20 : 15)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSoft,
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
      hintStyle: const TextStyle(color: kGrey, fontWeight: FontWeight.w500),
      border: border(Colors.transparent, 2),
      enabledBorder: border(Colors.transparent, 2),
      focusedBorder: border(accent, 2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: accent.withOpacity(0.45),
        disabledForegroundColor: Colors.white,
        shape: shape,
        padding: pad,
        minimumSize: Size(64, kid ? 54 : 50),
        textStyle: btnText(kid),
        elevation: kid ? 4 : 0,
        shadowColor: kid ? const Color(0x40000000) : Colors.transparent,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        shape: shape,
        side: BorderSide(color: kid ? accent : kInk, width: 2),
        padding: pad,
        minimumSize: Size(64, kid ? 54 : 50),
        textStyle: btnText(kid),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Color.lerp(accent, Colors.black, 0.2),
        textStyle: kid
            ? GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w900)
            : GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: ink),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: const StadiumBorder(),
      backgroundColor: kInk,
      contentTextStyle: GoogleFonts.manrope(
          color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
            (st) => st.contains(WidgetState.selected) ? ink : kSoft),
        foregroundColor: WidgetStateProperty.resolveWith(
            (st) => st.contains(WidgetState.selected) ? Colors.white : kGrey),
        side: const WidgetStatePropertyAll(BorderSide.none),
        shape: const WidgetStatePropertyAll(StadiumBorder()),
        textStyle: WidgetStatePropertyAll(
            GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w700)),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
  );
}
