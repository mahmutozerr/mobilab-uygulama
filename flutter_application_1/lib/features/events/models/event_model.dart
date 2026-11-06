// lib/features/events/models/event_model.dart

/// API'den, Biletinial etkinliklerinden ve yerel İstanbul veri setinden gelen
/// tek bir etkinliğin verilerini temsil eden sınıf (Model).
class EventModel {
  final String id; // Etkinliğin benzersiz kimliği (Örn: "evt-001", "blt-001", "ist-001")
  final String title; // Etkinlik başlığı
  final String? description; // Etkinlik açıklaması
  final String category; // Kategori (Örn: "Tiyatro", "Stand-Up", "Müzik & Konser", "Kültür & Sanat", "Teknoloji")
  final DateTime startDate; // Başlangıç tarihi ve saati
  final DateTime endDate; // Bitiş tarihi ve saati
  final String location; // Etkinlik konumu / sahnesi
  final String organizer; // Düzenleyen topluluk/kurum (Örn: "Biletinial • DasDas", "MOBILAB")
  final String imageUrl; // Etkinlik afiş/kapak görseli linki
  final int capacity; // Maksimum katılımcı / salon kontenjanı
  final int registeredCount; // Şu ana kadar bilet alan / kayıt olan kişi sayısı
  final bool isOnline; // Etkinlik online mı (true) yoksa yüz yüze mi (false)?
  final List<String> tags; // Etkinlik etiketleri
  final String? price; // Bilet fiyatı bilgisi (Örn: "₺450" veya "Ücretsiz")

  const EventModel({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.organizer,
    required this.imageUrl,
    required this.capacity,
    required this.registeredCount,
    required this.isOnline,
    required this.tags,
    this.price,
  });

  /// Factory Metodu (fromJson): JSON (Map) verisini EventModel nesnesine dönüştürür.
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Başlıksız Etkinlik',
      description: json['description'] as String?,
      category: json['category'] as String? ?? 'Genel',
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      location: json['location'] as String? ?? 'Konum Belirtilmedi',
      organizer: json['organizer'] as String? ?? 'Bilinmiyor',
      imageUrl: json['imageUrl'] as String? ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      registeredCount: (json['registeredCount'] as num?)?.toInt() ?? 0,
      isOnline: json['isOnline'] as bool? ?? false,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((tag) => tag.toString())
              .toList() ??
          [],
      price: json['price'] as String?,
    );
  }

  /// toJson Metodu: Dart nesnesini tekrar JSON (Map) formatına çevirir (SharedPreferences için).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'location': location,
      'organizer': organizer,
      'imageUrl': imageUrl,
      'capacity': capacity,
      'registeredCount': registeredCount,
      'isOnline': isOnline,
      'tags': tags,
      'price': price,
    };
  }

  /// Kontenjanın / biletlerin tükenip tükenmediğini kontrol eder.
  bool get isFull => registeredCount >= capacity;

  /// Bu etkinliğin Yıldız Teknik Üniversitesi (YTÜ) ile ilgili olup olmadığını belirler.
  bool get isYtuEvent {
    final String combinedText =
        '${id.toLowerCase()} ${title.toLowerCase()} ${location.toLowerCase()} ${organizer.toLowerCase()} ${tags.join(' ').toLowerCase()}';
    return id.startsWith('evt-') ||
        id.startsWith('ytu-') ||
        combinedText.contains('ytü') ||
        combinedText.contains('yıldız teknik') ||
        combinedText.contains('davutpaşa') ||
        combinedText.contains('sky lab') ||
        combinedText.contains('mobilab');
  }

  /// Bu etkinliğin Biletinial platformuna ait bir etkinlik olup olmadığını belirler.
  bool get isBiletinialEvent {
    final String combinedText =
        '${id.toLowerCase()} ${organizer.toLowerCase()} ${tags.join(' ').toLowerCase()}';
    return id.startsWith('blt-') || combinedText.contains('biletinial');
  }
}

/// '/events' uç noktasından gelen sayfalandırılmış (paginated) yanıtı karşılayan model.
class PaginatedEventsResponse {
  final List<EventModel> items;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;

  const PaginatedEventsResponse({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });

  factory PaginatedEventsResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final eventList = rawItems
        .map((item) => EventModel.fromJson(item as Map<String, dynamic>))
        .toList();

    return PaginatedEventsResponse(
      items: eventList,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
      total: (json['total'] as num?)?.toInt() ?? 0,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}
