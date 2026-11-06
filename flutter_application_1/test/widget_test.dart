// test/widget_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/core/storage/favorite_service.dart';
import 'package:flutter_application_1/core/theme/theme_provider.dart';
import 'package:flutter_application_1/features/events/models/event_model.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  test('EventModel.fromJson ve YTÜ / Biletinial kontrol testi', () {
    final Map<String, dynamic> sampleJson = {
      'id': 'evt-001',
      'title': 'Flutter ile İlk Uygulamanı Yayınla',
      'category': 'Workshop',
      'startDate': '2026-10-21T18:00:00+03:00',
      'endDate': '2026-10-21T20:00:00+03:00',
      'location': 'Davutpaşa Kampüsü, B-112',
      'organizer': 'MOBILAB',
      'imageUrl': 'https://picsum.photos/seed/evt001/800/450',
      'capacity': 60,
      'registeredCount': 42,
      'isOnline': false,
      'tags': ['flutter', 'mobil'],
    };

    final EventModel event = EventModel.fromJson(sampleJson);

    expect(event.id, 'evt-001');
    expect(event.title, 'Flutter ile İlk Uygulamanı Yayınla');
    expect(event.isYtuEvent, isTrue);
    expect(event.isFull, isFalse);
  });

  test('FavoriteService ekleme ve cikarma (SharedPreferences) testi', () async {
    SharedPreferences.setMockInitialValues({});
    final FavoriteService favoriteService = FavoriteService();

    final EventModel sampleEvent = EventModel(
      id: 'blt-001',
      title: 'Amadeus',
      category: 'Tiyatro',
      startDate: DateTime.parse('2026-11-03T20:30:00+03:00'),
      endDate: DateTime.parse('2026-11-03T23:00:00+03:00'),
      location: 'Zorlu PSM',
      organizer: 'Biletinial',
      imageUrl: 'https://picsum.photos/seed/bltamadeus/800/450',
      capacity: 1200,
      registeredCount: 1140,
      isOnline: false,
      tags: ['biletinial', 'tiyatro'],
      price: '₺750',
    );

    // 1. Favoriye ekle
    final bool added = await favoriteService.toggleFavorite(sampleEvent);
    expect(added, isTrue);
    expect(await favoriteService.isFavorite('blt-001'), isTrue);

    // 2. Favoriden çıkar
    final bool removed = await favoriteService.toggleFavorite(sampleEvent);
    expect(removed, isFalse);
    expect(await favoriteService.isFavorite('blt-001'), isFalse);
  });

  testWidgets('Uygulama baslangic ekrani (EventListView) yuklenme testi',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MyApp(),
      ),
    );

    // Asenkron zamanlayıcıların (Dio FakeAsync timer) tamamlanmasını bekle
    await tester.pumpAndSettle();

    // Alt menüdeki sekmelerin ekranda yer aldığını doğrula
    expect(find.text('İstanbul Keşfet'), findsOneWidget);
    expect(find.text('YTÜ Kampüs'), findsOneWidget);
    expect(find.text('Favorilerim'), findsOneWidget);
  });
}
