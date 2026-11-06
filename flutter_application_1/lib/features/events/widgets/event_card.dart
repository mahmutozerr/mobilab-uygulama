// lib/features/events/widgets/event_card.dart

import 'package:flutter/material.dart';
import '../models/event_model.dart';

/// Listedeki her bir etkinliği şık bir kart olarak gösteren görsel bileşen (Widget).
class EventCard extends StatelessWidget {
  final EventModel event; // Kartın göstereceği etkinlik verisi
  final VoidCallback? onTap; // Karta tıklandığında çalışacak fonksiyon (Detay sayfasına gitmek için)
  final bool isFavorite; // Bu etkinlik favorilere eklenmiş mi?
  final VoidCallback? onFavoriteToggle; // Kalp butonuna basıldığında çalışacak fonksiyon

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  /// DateTime nesnesini "21 Ekim 2026 • 18:00" şeklinde okunaklı Türkçe metne çeviren yardımcı metot.
  String _formatDate(DateTime date) {
    const List<String> months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    final String monthName = months[date.month - 1];
    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');

    return '${date.day} $monthName ${date.year} • $hour:$minute';
  }

  /// Kategoriye göre özel renk döndüren yardımcı metot.
  Color _getCategoryColor(BuildContext context, String category) {
    switch (category) {
      case 'Tiyatro':
        return const Color(0xFFB71C1C); // Tiyatro Perdesi Kırmızısı
      case 'Stand-Up':
        return const Color(0xFFE65100); // Enerjik Turuncu
      case 'Kültür & Sanat':
        return Colors.deepPurple.shade600;
      case 'Teknoloji':
        return Colors.blue.shade700;
      case 'Müzik & Konser':
        return Colors.pink.shade600;
      case 'Hackathon':
        return Colors.teal.shade700;
      case 'Workshop':
        return Colors.indigo.shade600;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayPrice = event.price ?? 'Ücretsiz';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. ÜST KISIM: Etkinlik Görseli (Hero ile), Kategori/Biletinial/YTÜ Etiketleri ve Favori Kalp Butonu
            Stack(
              children: [
                // HERO ANİMASYONU:
                Hero(
                  tag: 'event-image-${event.id}',
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: Image.network(
                      event.imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Sol Üst Köşe: Kategori Rozeti + Biletinial Rozeti veya YTÜ Rozeti
                Positioned(
                  top: 12,
                  left: 12,
                  child: Row(
                    children: [
                      // Kategori Rozeti
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(context, event.category),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Eğer Biletinial etkinliği ise yanına "Biletinial" rozeti ekle!
                      if (event.isBiletinialEvent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB300), // Biletinial Sarı/Altın tonu
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.confirmation_number_rounded,
                                color: Colors.black87,
                                size: 13,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Biletinial',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Eğer YTÜ etkinliği ise yanına "YTÜ" rozeti ekle!
                      if (event.isYtuEvent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A2240), // YTÜ Laciverti
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFD4AF37),
                              width: 1.2,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.school_rounded,
                                color: Color(0xFFD4AF37),
                                size: 13,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'YTÜ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Sol Alt Köşe: Online / Yüz Yüze Bilgilendirme Rozeti
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          event.isOnline ? Icons.videocam : Icons.location_on,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.isOnline ? 'Online' : 'Yüz Yüze',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Sağ Alt Köşe: Bilet Fiyatı Etiketi (Örn: "₺750" veya "Ücretsiz")
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: displayPrice == 'Ücretsiz'
                          ? Colors.green.shade700
                          : Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      displayPrice,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Sağ Üst Köşe: Favorilere Ekle/Çıkar (Kalp) Butonu
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onFavoriteToggle,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey.shade700,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 2. ALT KISIM: Başlık, Tarih, Konum ve Düzenleyen Bilgileri
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Etkinlik Başlığı
                  Text(
                    event.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Etkinlik Tarihi ve Saati
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatDate(event.startDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Etkinlik Konumu
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
