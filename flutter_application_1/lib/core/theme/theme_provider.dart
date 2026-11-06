// lib/core/theme/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulamanın Açık (Light) ve Koyu (Dark) tema durumunu yöneten ve
/// kullanıcının tercihini SharedPreferences ile kalıcı hafızada saklayan sınıf.
/// ChangeNotifier sınıfından miras alır; böylece tema değiştiğinde notifyListeners()
/// ile tüm ekranlara "Yeniden çizil!" haberi gönderir.
class ThemeProvider extends ChangeNotifier {
  static const String _themePrefKey = 'is_dark_mode';

  // Varsayılan olarak açık tema (false) ile başlar, hafızadan okununca güncellenir.
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  /// Uygulama açıldığında cihaz hafızasından (SharedPreferences) kayıtlı tema tercihini okur.
  Future<void> _loadThemeFromPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themePrefKey) ?? false;
    notifyListeners(); // Tema yüklendiğinde arayüzü haberdar et
  }

  /// Üst bardaki (AppBar) Güneş/Ay butonuna basıldığında temayı değiştirir ve hafızaya kaydeder.
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners(); // Ekranı anında yeni temaya geçir

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themePrefKey, _isDarkMode);
  }
}

