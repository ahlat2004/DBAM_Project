import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/main_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/main_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => MainProvider()),
      ],
      child: const AiDatabaseAnalyzerApp(),
    ),
  );
}

class AiDatabaseAnalyzerApp extends StatelessWidget {
  const AiDatabaseAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Database Analyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2563EB),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const MainScreen(),
      routes: {'/settings': (_) => const SettingsScreen()},
    );
  }
}
