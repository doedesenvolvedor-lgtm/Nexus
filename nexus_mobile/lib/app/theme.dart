import 'package:flutter/material.dart';

final ThemeData nexusTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: const Color(0xff050505),
  primaryColor: Colors.red,
  colorScheme: ColorScheme.fromSeed(
    brightness: Brightness.dark,
    seedColor: Colors.red,
  ),
  useMaterial3: true,
);
