// lib/core/storage/favorite_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/events/models/event_model.dart';

/// Kullanıcının favori etkinliklerini cihazın kalıcı hafızasında (SharedPreferences)
/// saklayan ve yöneten servis sınıfı.
/// Uygulama tamamen kapatılıp açılsa bile veriler silinmez.
class FavoriteService {
  // Cihaz hafızasında (SharedPreferences) verileri saklarken kullanacağımız anahtar (key) isimleri.
  static const String _favoriteIdsKey = 'favorite_event_ids';
  static const String _favoriteEventsKey = 'favorite_events_data';

  /// 1. Kayıtlı Favori Etkinlik ID'lerini Getir
  /// Hangi etkinliğin kalp ikonunun dolu (kırmızı) olacağını hızlıca kontrol etmek için kullanılır.
  Future<Set<String>> getFavoriteIds() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> savedIds = prefs.getStringList(_favoriteIdsKey) ?? [];
    // Listeyi Set'e çeviriyoruz çünkü Set içinde arama yapmak (contains) çok hızlıdır ve tekrar eden ID barındırmaz.
    return savedIds.toSet();
  }

  /// 2. Kayıtlı Favori Etkinliklerin Tam Listesini Getir (Favoriler Ekranı İçin)
  /// Cihaz hafızasına JSON metni olarak kaydettiğimiz etkinlikleri tekrar EventModel listesine dönüştürür.
  Future<List<EventModel>> getFavoriteEvents() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> savedJsonList =
        prefs.getStringList(_favoriteEventsKey) ?? [];

    final List<EventModel> favoriteEvents = [];
    for (final String jsonString in savedJsonList) {
      try {
        final Map<String, dynamic> decodedMap =
            jsonDecode(jsonString) as Map<String, dynamic>;
        favoriteEvents.add(EventModel.fromJson(decodedMap));
      } catch (_) {
        // Bozuk bir kayıt varsa atla
      }
    }
    return favoriteEvents;
  }

  /// 3. Bir Etkinlik Favorilerde mi Kontrol Et
  Future<bool> isFavorite(String eventId) async {
    final Set<String> favoriteIds = await getFavoriteIds();
    return favoriteIds.contains(eventId);
  }

  /// 4. Favori Durumunu Değiştir (Ekle / Çıkar - Toggle)
  /// Etkinlik zaten favorilerdeyse çıkarır (false döner), değilse ekler (true döner).
  Future<bool> toggleFavorite(EventModel event) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Mevcut ID listesini ve etkinlik JSON listesini hafızadan çekiyoruz.
    final List<String> currentIds =
        List<String>.from(prefs.getStringList(_favoriteIdsKey) ?? []);
    final List<EventModel> currentEvents = await getFavoriteEvents();

    final bool alreadyFavorite = currentIds.contains(event.id);

    if (alreadyFavorite) {
      // Zaten favorideyse: Hem ID listesinden hem de etkinlik listesinden çıkar.
      currentIds.remove(event.id);
      currentEvents.removeWhere((item) => item.id == event.id);
    } else {
      // Favoride değilse: Hem ID listesine hem de etkinlik listesine ekle.
      currentIds.add(event.id);
      currentEvents.add(event);
    }

    // Güncel ID listesini SharedPreferences'a kaydet.
    await prefs.setStringList(_favoriteIdsKey, currentIds);

    // Güncel etkinlik nesnelerini toJson() ve jsonEncode() ile metne çevirip kaydet.
    final List<String> updatedJsonList = currentEvents
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    await prefs.setStringList(_favoriteEventsKey, updatedJsonList);

    // Yeni favori durumunu döndür (Eklendiyse true, çıkarıldıysa false).
    return !alreadyFavorite;
  }
}

