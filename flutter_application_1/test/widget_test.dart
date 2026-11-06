// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/core/theme/theme_provider.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Uygulama baslangic ekrani (EventListView) yuklenme testi',
      (WidgetTester tester) async {
    // Test ortamında SharedPreferences için sahte (mock) başlangıç değerleri tanımlıyoruz
    SharedPreferences.setMockInitialValues({});

    // MyApp bileşenini ThemeProvider ile sarmalayarak başlat
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MyApp(),
      ),
    );

    // Alt menüdeki sekmelerin ekranda yer aldığını doğrula
    expect(find.text('İstanbul Keşfet'), findsOneWidget);
    expect(find.text('YTÜ Kampüs'), findsOneWidget);
    expect(find.text('Favorilerim'), findsOneWidget);
  });
}
