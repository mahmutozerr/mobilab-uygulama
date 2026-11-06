// lib/features/events/screens/event_detail_view.dart

import 'package:flutter/material.dart';
import '../../../core/network/api_service.dart';
import '../../../core/storage/favorite_service.dart';
import '../models/event_model.dart';

/// Kullanıcının listeden seçtiği bir etkinliğin tüm detaylarını gösteren ekran.
/// Alt kısımda Biletinial bilet alma / etkinliğe kayıt olma aksiyon çubuğu bulunur.
class EventDetailView extends StatefulWidget {
  final EventModel event;

  const EventDetailView({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends State<EventDetailView> {
  final ApiService _apiService = ApiService();
  final FavoriteService _favoriteService = FavoriteService();

  late EventModel _currentEvent;
  bool _isLoadingDetail = false;
  String? _detailErrorMessage;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _checkFavoriteStatus();

    if (_currentEvent.description == null) {
      _fetchEventDetail();
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final bool favStatus = await _favoriteService.isFavorite(_currentEvent.id);
    if (!mounted) return;
    setState(() {
      _isFavorite = favStatus;
    });
  }

  Future<void> _toggleFavorite() async {
    final bool newStatus = await _favoriteService.toggleFavorite(_currentEvent);
    if (!mounted) return;

    setState(() {
      _isFavorite = newStatus;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newStatus
              ? 'Etkinlik favorilere eklendi ❤️'
              : 'Etkinlik favorilerden çıkarıldı',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _fetchEventDetail() async {
    setState(() {
      _isLoadingDetail = true;
      _detailErrorMessage = null;
    });

    try {
      final EventModel detailedEvent = await _apiService.getEventById(
        _currentEvent.id,
      );

      if (!mounted) return;

      setState(() {
        _currentEvent = detailedEvent;
        _isLoadingDetail = false;
      });
    } on ApiException catch (apiError) {
      if (!mounted) return;

      setState(() {
        _detailErrorMessage = apiError.message;
        _isLoadingDetail = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _detailErrorMessage = 'Etkinlik açıklaması yüklenemedi.';
        _isLoadingDetail = false;
      });
    }
  }

  String _formatDateRange(DateTime start, DateTime end) {
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
    final String monthName = months[start.month - 1];
    final String startHour = start.hour.toString().padLeft(2, '0');
    final String startMin = start.minute.toString().padLeft(2, '0');
    final String endHour = end.hour.toString().padLeft(2, '0');
    final String endMin = end.minute.toString().padLeft(2, '0');

    return '${start.day} $monthName ${start.year}  •  $startHour:$startMin - $endHour:$endMin';
  }

  /// Alt kısımdaki "Biletinial'da Bilet Al" veya "Etkinliğe Kayıt Ol" butonuna basıldığında açılan pencere.
  void _showTicketDialog() {
    final bool isBiletinial = _currentEvent.isBiletinialEvent;
    final String priceText = _currentEvent.price ?? 'Ücretsiz';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isBiletinial
                        ? Icons.confirmation_number_rounded
                        : Icons.event_available_rounded,
                    color: isBiletinial
                        ? const Color(0xFFFFB300)
                        : Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isBiletinial
                          ? 'Biletinial Bilet Özeti'
                          : 'Etkinlik Kayıt Özeti',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(
                _currentEvent.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _currentEvent.location,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                'Bilet / Katılım Ücreti: $priceText',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isBiletinial
                              ? 'Biletinial (biletinial.com) koltuk seçimi ekranına yönlendiriliyorsunuz...'
                              : '${_currentEvent.title} için kaydınız alındı!',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isBiletinial
                        ? const Color(0xFFFFB300)
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor:
                        isBiletinial ? Colors.black87 : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: Icon(
                    isBiletinial
                        ? Icons.open_in_new_rounded
                        : Icons.check_circle_outline,
                  ),
                  label: Text(
                    isBiletinial
                        ? 'biletinial.com Üzerinden Devam Et'
                        : 'Kaydı Tamamla',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double capacityRatio = _currentEvent.capacity > 0
        ? (_currentEvent.registeredCount / _currentEvent.capacity).clamp(0.0, 1.0)
        : 0.0;
    final String displayPrice = _currentEvent.price ?? 'Ücretsiz';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Etkinlik Detayı'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _toggleFavorite,
            tooltip: _isFavorite ? 'Favorilerden Çıkar' : 'Favorilere Ekle',
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. BÜYÜK ETKİNLİK GÖRSELİ VE HERO ANİMASYONU
            Hero(
              tag: 'event-image-${_currentEvent.id}',
              child: SizedBox(
                height: 250,
                width: double.infinity,
                child: Image.network(
                  _currentEvent.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.shade300,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 2. TÜM DETAY BİLGİLERİNİN YER ALDIĞI İÇERİK ALANI
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kategori, Biletinial/YTÜ ve Online/Yüz Yüze Rozetleri
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _currentEvent.category,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (_currentEvent.isBiletinialEvent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB300),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.confirmation_number_rounded,
                                size: 15,
                                color: Colors.black87,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Biletinial Resmi Etkinliği',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _currentEvent.isOnline
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _currentEvent.isOnline
                                ? Colors.green.shade300
                                : Colors.orange.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _currentEvent.isOnline
                                  ? Icons.videocam_outlined
                                  : Icons.groups_outlined,
                              size: 16,
                              color: _currentEvent.isOnline
                                  ? Colors.green.shade800
                                  : Colors.orange.shade800,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _currentEvent.isOnline ? 'Online Etkinlik' : 'Yüz Yüze',
                              style: TextStyle(
                                color: _currentEvent.isOnline
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Etkinliğin Tam Başlığı
                  Text(
                    _currentEvent.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bilgi Satırı 1: Tarih ve Saat Aralığı
                  _buildInfoRow(
                    context: context,
                    icon: Icons.calendar_month_rounded,
                    title: 'Tarih ve Saat',
                    subtitle: _formatDateRange(
                      _currentEvent.startDate,
                      _currentEvent.endDate,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Bilgi Satırı 2: Konum / Sahne
                  _buildInfoRow(
                    context: context,
                    icon: Icons.location_on_rounded,
                    title: 'Mekan / Sahne',
                    subtitle: _currentEvent.location,
                  ),
                  const SizedBox(height: 14),

                  // Bilgi Satırı 3: Düzenleyen
                  _buildInfoRow(
                    context: context,
                    icon: Icons.verified_user_rounded,
                    title: 'Düzenleyen / Platform',
                    subtitle: _currentEvent.organizer,
                  ),
                  const SizedBox(height: 20),

                  // Kontenjan ve Salon Doluluk Durumu Kartı
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _currentEvent.isBiletinialEvent
                                  ? 'Salon Koltuk Doluluğu'
                                  : 'Katılımcı Kontenjanı',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${_currentEvent.registeredCount} / ${_currentEvent.capacity} Kişi',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _currentEvent.isFull
                                    ? Colors.red.shade700
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: capacityRatio,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade300,
                            color: _currentEvent.isFull
                                ? Colors.red.shade400
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Etkinlik Açıklaması Başlığı
                  const Text(
                    'Etkinlik Hakkında',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildDescriptionSection(),

                  if (_currentEvent.tags.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Etiketler',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _currentEvent.tags.map((tag) {
                        return Chip(
                          label: Text('#$tag'),
                          backgroundColor: Colors.grey.shade100,
                          side: BorderSide(color: Colors.grey.shade300),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      // ALT SABİT BİLET / KAYIT ÇUBUĞU
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentEvent.isBiletinialEvent
                          ? 'Biletinial Fiyatı'
                          : 'Katılım Ücreti',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      displayPrice,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _currentEvent.isFull ? null : _showTicketDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentEvent.isBiletinialEvent
                      ? const Color(0xFFFFB300)
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: _currentEvent.isBiletinialEvent
                      ? Colors.black87
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(
                  _currentEvent.isFull
                      ? Icons.block
                      : (_currentEvent.isBiletinialEvent
                          ? Icons.confirmation_number_rounded
                          : Icons.how_to_reg_rounded),
                ),
                label: Text(
                  _currentEvent.isFull
                      ? 'Tükendi'
                      : (_currentEvent.isBiletinialEvent
                          ? 'Biletinial\'dan Al'
                          : 'Hemen Kayıt Ol'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    if (_isLoadingDetail) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 12),
            Text(
              'Etkinlik açıklaması yükleniyor...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_detailErrorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _detailErrorMessage!,
                style: TextStyle(color: Colors.red.shade900, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: _fetchEventDetail,
              child: const Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }

    return Text(
      _currentEvent.description ?? 'Bu etkinlik için açıklama girilmemiş.',
      style: TextStyle(
        fontSize: 15,
        height: 1.5,
        color: Colors.grey.shade800,
      ),
    );
  }
}
