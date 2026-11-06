// lib/features/events/screens/favorites_view.dart

import 'package:flutter/material.dart';
import '../../../core/storage/favorite_service.dart';
import '../models/event_model.dart';
import '../widgets/event_card.dart';
import 'event_detail_view.dart';

/// Kullanıcının favorilere eklediği etkinlikleri listelediği ayrı ekran/sekme.
/// Verileri doğrudan cihaz hafızasından (SharedPreferences) okur; internet olmasa bile çalışır!
class FavoritesView extends StatefulWidget {
  final VoidCallback? onFavoritesChanged; // Favori silindiğinde ana listeyi de haberdar etmek için

  const FavoritesView({
    super.key,
    this.onFavoritesChanged,
  });

  @override
  State<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<FavoritesView> {
  final FavoriteService _favoriteService = FavoriteService();

  List<EventModel> _favoriteEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  /// Cihaz hafızasındaki favori etkinlikleri yükleyen metot.
  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    final List<EventModel> savedEvents =
        await _favoriteService.getFavoriteEvents();

    if (!mounted) return;

    setState(() {
      _favoriteEvents = savedEvents;
      _isLoading = false;
    });
  }

  /// Kart üzerindeki kalp butonuna basıldığında etkinliği favorilerden çıkaran metot.
  Future<void> _removeFavorite(EventModel event) async {
    await _favoriteService.toggleFavorite(event);
    await _loadFavorites();
    // Ana ekrandaki kalp ikonlarının da güncellenmesi için haber veriyoruz.
    widget.onFavoritesChanged?.call();

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${event.title} favorilerden çıkarıldı'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Eğer henüz hiç favori etkinlik eklenmemişse gösterilecek Boş Durum (Empty State)
    if (_favoriteEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border_rounded,
                size: 80,
                color: Colors.red.shade200,
              ),
              const SizedBox(height: 16),
              const Text(
                'Henüz favori etkinliğiniz yok',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Beğendiğiniz etkinliklerin sağ üst köşesindeki kalp ikonuna dokunarak buraya ekleyebilirsiniz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Favori etkinliklerin listesi
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: _favoriteEvents.length,
      itemBuilder: (context, index) {
        final EventModel event = _favoriteEvents[index];
        return EventCard(
          event: event,
          isFavorite: true, // Bu listedeki her etkinlik zaten favoridir
          onFavoriteToggle: () => _removeFavorite(event),
          onTap: () async {
            // Detay sayfasına git ve kullanıcı geri döndüğünde (await) favori listesini yenile
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailView(event: event),
              ),
            );
            _loadFavorites();
            widget.onFavoritesChanged?.call();
          },
        );
      },
    );
  }
}

