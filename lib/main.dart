import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

const _brandColor = Color(0xFFA78BFA);

class _SoftScaleFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const _SoftScaleFadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final enterTransition = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    final exitTransition = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeInOutCubic,
    );
    final scale = Tween<double>(begin: 0.985, end: 1).animate(enterTransition);
    final exitScale = Tween<double>(
      begin: 1,
      end: 0.99,
    ).animate(exitTransition);
    final exitOpacity = Tween<double>(
      begin: 1,
      end: 0.92,
    ).animate(exitTransition);

    return FadeTransition(
      opacity: enterTransition,
      child: FadeTransition(
        opacity: exitOpacity,
        child: ScaleTransition(
          scale: exitScale,
          child: ScaleTransition(scale: scale, child: child),
        ),
      ),
    );
  }
}

const _pageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: _SoftScaleFadePageTransitionsBuilder(),
    TargetPlatform.iOS: _SoftScaleFadePageTransitionsBuilder(),
    TargetPlatform.windows: _SoftScaleFadePageTransitionsBuilder(),
    TargetPlatform.macOS: _SoftScaleFadePageTransitionsBuilder(),
    TargetPlatform.linux: _SoftScaleFadePageTransitionsBuilder(),
  },
);

ThemeData _buildTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final warmOffWhite = const Color(0xFFFDFBF7);
  final colorScheme =
      ColorScheme.fromSeed(
        seedColor: _brandColor,
        brightness: brightness,
      ).copyWith(
        primary: _brandColor,
        secondary: const Color(0xFFF472B6),
        surface: isDark ? const Color(0xFF252331) : const Color(0xFFFFFEFC),
      );
  final scaffoldColor = isDark ? const Color(0xFF191821) : warmOffWhite;
  final textTheme = GoogleFonts.nunitoTextTheme(
    ThemeData(brightness: brightness).textTheme,
  );
  final inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: BorderSide(
      color: isDark ? const Color(0xFF494653) : const Color(0xFFEAE5EE),
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    textTheme: textTheme,
    pageTransitionsTheme: _pageTransitions,
    scaffoldBackgroundColor: scaffoldColor,
    appBarTheme: AppBarTheme(
      backgroundColor: scaffoldColor,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surface,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.16 : 0.045),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? const Color(0xFF3A3745) : const Color(0xFFF0EAF2),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        minimumSize: const Size(48, 52),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        minimumSize: const Size(48, 52),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.primary.withValues(alpha: 0.18),
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        );
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
  );
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => ApiService()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<AuthService, ThemeProvider>(
        builder: (context, auth, themeProvider, _) => MaterialApp(
          title: 'Stockwise',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: auth.isLoggedIn && themeProvider.isDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: auth.isLoggedIn ? const HomeScreen() : const LoginScreen(),
        ),
      ),
    );
  }
}
