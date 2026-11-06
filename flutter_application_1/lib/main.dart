// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme_provider.dart';
import 'features/events/screens/event_list_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    // ChangeNotifierProvider ile ThemeProvider'ı tüm uygulama ağacının en tepesine yerleştiriyoruz.
    // Böylece istediğimiz her ekrandan tema durumuna erişip tek tuşla değiştirebiliriz.
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

/// Uygulamanın kök (Root) bileşeni. Açık (Light) ve Koyu (Dark) tema ayarlarını burada tanımlıyoruz.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ThemeProvider içindeki değişiklikleri dinliyoruz (watch).
    final ThemeProvider themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Etkinlik Keşif Uygulaması',
      debugShowCheckedModeBanner: false,

      // 1. AÇIK TEMA (LIGHT MODE) AYARLARI
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F9FC),
        cardTheme: const CardThemeData(
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
      ),

      // 2. KOYU TEMA (DARK MODE) AYARLARI
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigoAccent,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF12141C),
        cardTheme: const CardThemeData(
          color: Color(0xFF1E2230),
          surfaceTintColor: Colors.transparent,
        ),
      ),

      // Kullanıcının seçimine göre Açık veya Koyu temayı aktif et:
      themeMode: themeProvider.themeMode,

      // Başlangıç ekranı
      home: const EventListView(),
    );
  }
}
