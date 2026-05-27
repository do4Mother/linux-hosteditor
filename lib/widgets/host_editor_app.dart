import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'host_editor_home.dart';

class HostEditorApp extends StatelessWidget {
  const HostEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Host Editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.windowBg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: AppColors.primaryContainer,
          onPrimaryContainer: AppColors.onPrimaryContainer,
          secondary: AppColors.secondary,
          secondaryContainer: AppColors.secondaryContainer,
          onSecondaryContainer: AppColors.onSecondaryContainer,
          tertiary: AppColors.tertiary,
          error: AppColors.error,
          errorContainer: AppColors.errorContainer,
          onErrorContainer: AppColors.onErrorContainer,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          onSurfaceVariant: AppColors.onSurfaceVariant,
          outline: AppColors.outline,
          outlineVariant: AppColors.outlineVariant,
        ),
        fontFamily: 'Roboto',
        dialogTheme: const DialogThemeData(backgroundColor: AppColors.surfaceContainerHigh, surfaceTintColor: Colors.transparent),
        popupMenuTheme: const PopupMenuThemeData(color: AppColors.surfaceContainerHigh, surfaceTintColor: Colors.transparent),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surfaceContainerHighest,
          labelStyle: TextStyle(color: AppColors.onSurfaceVariant),
          floatingLabelStyle: TextStyle(color: AppColors.primary),
          hintStyle: TextStyle(color: AppColors.onSurfaceVariant),
          helperStyle: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
          prefixIconColor: AppColors.onSurfaceVariant,
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.onSurfaceVariant),
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.onSurfaceVariant),
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary, width: 2),
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
          ),
          errorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.error),
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
          ),
          focusedErrorBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.error, width: 2),
            borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
      ),
      home: const HostEditorHome(),
    );
  }
}
