import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/reading_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ReadingService.instance.init();
  runApp(const MemVocabApp());
}

class MemVocabApp extends StatelessWidget {
  const MemVocabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'لعبة الذاكرة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1120),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: const HomeScreen(),
    );
  }
}
