// lib/core/network/api_service.dart

import 'package:dio/dio.dart';
import '../../features/events/data/istanbul_events_data.dart';
import '../../features/events/models/event_model.dart';

/// Kullanıcıya anlaşılır Türkçe hata mesajları göstermek için kendi özel Hata (Exception) sınıfımızı oluşturuyoruz.
class ApiException implements Exception {
  final String message; // Kullanıcıya gösterilecek anlaşılır mesaj
  final int? statusCode; // HTTP durum kodu (Örn: 404, 500, 503)

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// Uygulamanın internet (API) ile olan tüm iletişimini yöneten merkezi servis sınıfı.
class ApiService {
  late final Dio _dio;

  // API'nin ana adresi (Base URL)
  static const String _baseUrl = 'https://mobilab-task-api.vercel.app';

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  /// 1. Etkinlik Listesini Sayfalı (Paginated) Olarak Getir (GET /events)
  /// Sayfalama (page, limit) parametrelerine göre hem API'den veri çeker hem de
  /// 'hasMore' (daha fazla sayfa var mı?) bilgisini hesaplar.
  Future<PaginatedEventsResponse> getEvents({
    String? query,
    String? category,
    bool? isOnline,
    int page = 1,
    int limit = 8,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
      };

      if (query != null && query.trim().isNotEmpty) {
        queryParams['q'] = query.trim();
      }
      if (category != null && category.trim().isNotEmpty) {
        queryParams['category'] = category.trim();
      }
      if (isOnline != null) {
        queryParams['online'] = isOnline;
      }

      // API'ye gerçek sayfalama isteği atıyoruz (/events?page=1&limit=8)
      final Response response = await _dio.get(
        '/events',
        queryParameters: {
          ...queryParams,
          'page': 1,
          'limit': 50,
        },
      );

      final PaginatedEventsResponse apiResponse =
          PaginatedEventsResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      // API'den gelen YTÜ etkinlikleri ile Biletinial / İstanbul etkinliklerini birleştirip tarihe göre sıralıyoruz.
      final List<EventModel> allCombinedEvents = [
        ...IstanbulEventsData.events,
        ...apiResponse.items,
      ];
      allCombinedEvents.sort((a, b) => a.startDate.compareTo(b.startDate));

      // SAYFALAMA (PAGINATION) HESABI:
      // Örneğin limit = 8 ise:
      // Sayfa 1 -> 0..8 arası elemanlar
      // Sayfa 2 -> 8..16 arası elemanlar
      final int totalCount = allCombinedEvents.length;
      final int startIndex = (page - 1) * limit;

      if (startIndex >= totalCount) {
        return PaginatedEventsResponse(
          items: [],
          page: page,
          limit: limit,
          total: totalCount,
          hasMore: false,
        );
      }

      final int endIndex =
          (startIndex + limit) > totalCount ? totalCount : (startIndex + limit);
      final List<EventModel> pagedItems =
          allCombinedEvents.sublist(startIndex, endIndex);
      final bool hasMorePages = endIndex < totalCount;

      return PaginatedEventsResponse(
        items: pagedItems,
        page: page,
        limit: limit,
        total: totalCount,
        hasMore: hasMorePages,
      );
    } on DioException catch (dioError) {
      throw _handleDioError(dioError);
    } catch (error) {
      throw ApiException('Veriler işlenirken beklenmeyen bir hata oluştu: $error');
    }
  }

  /// 2. Tek Bir Etkinliğin Detayını Getir (GET /events/{event_id})
  Future<EventModel> getEventById(String eventId) async {
    for (final EventModel localEvent in IstanbulEventsData.events) {
      if (localEvent.id == eventId) {
        return localEvent;
      }
    }

    try {
      final Response response = await _dio.get('/events/$eventId');

      return EventModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (dioError) {
      throw _handleDioError(dioError);
    } catch (error) {
      throw ApiException('Etkinlik detayı alınırken bir hata oluştu: $error');
    }
  }

  /// 3. Tüm Kategorileri Getir (GET /categories + Biletinial Kategorileri)
  Future<List<String>> getCategories() async {
    try {
      final Response response = await _dio.get('/categories');

      final data = response.data as Map<String, dynamic>;
      final rawItems = data['items'] as List<dynamic>? ?? [];
      final List<String> apiCategories =
          rawItems.map((item) => item.toString()).toList();

      final Set<String> mergedCategories = {
        'Tiyatro',
        'Stand-Up',
        'Müzik & Konser',
        'Kültür & Sanat',
        'Teknoloji',
        ...apiCategories,
      };

      return mergedCategories.toList();
    } on DioException catch (dioError) {
      throw _handleDioError(dioError);
    } catch (error) {
      throw ApiException('Kategoriler yüklenirken bir hata oluştu: $error');
    }
  }

  ApiException _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          'Sunucu yanıt vermekte gecikti (Zaman aşımı). Lütfen tekrar deneyin.',
        );

      case DioExceptionType.badResponse:
        final int? statusCode = error.response?.statusCode;
        final dynamic responseData = error.response?.data;
        String? serverDetail;
        if (responseData is Map<String, dynamic> &&
            responseData['detail'] is String) {
          serverDetail = responseData['detail'] as String;
        }

        if (statusCode == 404) {
          return ApiException(
            serverDetail ?? 'Aradığınız etkinlik bulunamadı (404).',
            statusCode: statusCode,
          );
        } else if (statusCode == 422) {
          return ApiException(
            'Geçersiz arama veya filtre parametresi gönderildi (422).',
            statusCode: statusCode,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return ApiException(
            serverDetail ??
                'Sunucuda geçici bir yoğunluk veya hata oluştu ($statusCode). Lütfen tekrar deneyin.',
            statusCode: statusCode,
          );
        }
        return ApiException(
          serverDetail ?? 'Sunucu hatası oluştu (Kod: $statusCode).',
          statusCode: statusCode,
        );

      case DioExceptionType.connectionError:
        return ApiException(
          'İnternet bağlantısı kurulamadı. Lütfen bağlantınızı kontrol edin.',
        );

      case DioExceptionType.cancel:
        return ApiException('İstek iptal edildi.');

      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
      default:
        return ApiException(
          'Ağ bağlantısında beklenmeyen bir sorun oluştu. Lütfen tekrar deneyin.',
        );
    }
  }
}
