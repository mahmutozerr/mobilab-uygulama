// lib/features/events/screens/event_list_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_service.dart';
import '../../../core/storage/favorite_service.dart';
import '../../../core/theme/theme_provider.dart';
import '../models/event_model.dart';
import '../widgets/event_card.dart';
import 'event_detail_view.dart';
import 'favorites_view.dart';

/// Etkinliklerin listelendiği, Arama/Kategori filtrelemesinin, Sayfalamanın (Pagination)
/// ve Açık/Koyu Tema (Light/Dark Mode) geçişinin yer aldığı ana ekran.
class EventListView extends StatefulWidget {
  const EventListView({super.key});

  @override
  State<EventListView> createState() => _EventListViewState();
}

class _EventListViewState extends State<EventListView> {
  final ApiService _apiService = ApiService();
  final FavoriteService _favoriteService = FavoriteService();
  final TextEditingController _searchController = TextEditingController();

  // SAYFALAMA (PAGINATION) İÇİN KAYDIRMA KONTROLCÜSÜ:
  // Kullanıcının listenin en altına inip inmediğini takip eder.
  final ScrollController _scrollController = ScrollController();

  // --- EKRAN DURUM DEĞİŞKENLERİ (STATE VARIABLES) ---
  List<EventModel> _allEvents = []; // Şu ana kadar yüklenen sayfaların birleşik listesi
  List<EventModel> _filteredEvents = []; // Seçili sekmeye, aramaya ve kategoriye göre filtrelenmiş liste
  List<String> _categories = [
    'Tümü',
    'Tiyatro',
    'Stand-Up',
    'Müzik & Konser',
    'Kültür & Sanat',
    'Teknoloji',
    'Workshop',
    'Hackathon',
    'Seminer',
    'Sosyal',
    'Panel',
    'Yarışma',
  ];

  String _selectedCategory = 'Tümü';
  String _searchQuery = '';

  Set<String> _favoriteIds = {};
  int _currentTabIndex = 0; // 0: İstanbul Keşfet, 1: Sadece YTÜ, 2: Favorilerim

  // --- SAYFALAMA (PAGINATION) DEĞİŞKENLERİ ---
  static const int _pageSize = 8; // Her sayfada kaç etkinlik yükleneceği
  int _currentPage = 1; // Mevcut sayfa numarası
  bool _hasMore = true; // Yüklenecek daha fazla sayfa var mı?
  bool _isLoadingMore = false; // Şu anda yeni sayfa yükleniyor mu?

  bool _isLoading = true; // İlk sayfa yükleniyor mu?
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    // ScrollController Dinleyicisi: Kullanıcı listenin sonuna yaklaştığında
    // otomatik olarak bir sonraki sayfayı yükler (Infinite Scroll).
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Kullanıcı listeyi aşağı kaydırırken en alta 150 piksel kaldığında yeni sayfayı tetikler.
  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 150 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMoreEvents();
    }
  }

  Future<void> _loadInitialData() async {
    await _loadFavoriteIds();
    _fetchCategories();
    await _fetchEvents();
  }

  Future<void> _loadFavoriteIds() async {
    final Set<String> ids = await _favoriteService.getFavoriteIds();
    if (!mounted) return;
    setState(() {
      _favoriteIds = ids;
    });
  }

  Future<void> _fetchCategories() async {
    try {
      final List<String> apiCategories = await _apiService.getCategories();
      if (!mounted || apiCategories.isEmpty) return;
      setState(() {
        _categories = ['Tümü', ...apiCategories];
      });
    } catch (_) {}
  }

  /// İlk sayfayı (page = 1) sıfırdan yükleyen metot (İlk açılış ve Pull-to-Refresh için).
  Future<void> _fetchEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
    });

    try {
      final PaginatedEventsResponse response = await _apiService.getEvents(
        page: 1,
        limit: _pageSize,
      );

      if (!mounted) return;

      setState(() {
        _allEvents = response.items;
        _hasMore = response.hasMore;
        _applyFilters();
        _isLoading = false;
      });
    } on ApiException catch (apiError) {
      if (!mounted) return;

      setState(() {
        _errorMessage = apiError.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Beklenmeyen bir sorun oluştu. Lütfen tekrar deneyin.';
        _isLoading = false;
      });
    }
  }

  /// SAYFALAMA (PAGINATION): Listenin sonuna inildiğinde veya "Daha Fazla Yükle"
  /// butonuna basıldığında bir sonraki sayfayı (`_currentPage + 1`) çeken metot.
  Future<void> _loadMoreEvents() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final int nextPage = _currentPage + 1;
      final PaginatedEventsResponse response = await _apiService.getEvents(
        page: nextPage,
        limit: _pageSize,
      );

      if (!mounted) return;

      setState(() {
        _currentPage = nextPage;
        // Yeni gelen sayfadaki etkinlikleri mevcut listenin sonuna ekliyoruz (addAll)
        _allEvents.addAll(response.items);
        _hasMore = response.hasMore;
        _applyFilters();
        _isLoadingMore = false;
      });
    } on ApiException catch (apiError) {
      if (!mounted) return;

      setState(() {
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Yeni sayfa yüklenemedi: ${apiError.message}'),
          action: SnackBarAction(
            label: 'Tekrar Dene',
            onPressed: _loadMoreEvents,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  /// Seçili sekmeye (0: İstanbul Tüm Etkinlikler, 1: Sadece YTÜ), arama kelimesine ve kategoriye
  /// göre etkinlik listesini ANLIK olarak filtreleyen metot.
  void _applyFilters() {
    final String query = _searchQuery.trim().toLowerCase();
    final bool onlyYtuTab = _currentTabIndex == 1;

    _filteredEvents = _allEvents.where((EventModel event) {
      if (onlyYtuTab && !event.isYtuEvent) {
        return false;
      }

      final bool matchesCategory = _selectedCategory == 'Tümü' ||
          event.category.toLowerCase() == _selectedCategory.toLowerCase();

      final bool matchesQuery = query.isEmpty ||
          event.title.toLowerCase().contains(query) ||
          event.location.toLowerCase().contains(query) ||
          event.organizer.toLowerCase().contains(query) ||
          event.tags.any((tag) => tag.toLowerCase().contains(query));

      return matchesCategory && matchesQuery;
    }).toList();
  }

  Future<void> _toggleFavorite(EventModel event) async {
    final bool isNowFavorite = await _favoriteService.toggleFavorite(event);
    await _loadFavoriteIds();

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isNowFavorite
              ? '${event.title} favorilere eklendi ❤️'
              : '${event.title} favorilerden çıkarıldı',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentTabIndex) {
      case 0:
        return 'İstanbul & Biletinial Keşif';
      case 1:
        return 'YTÜ Kampüs & Kulüpler';
      case 2:
        return 'Favori Etkinliklerim';
      default:
        return 'Etkinlik Keşif';
    }
  }

  @override
  Widget build(BuildContext context) {
    // ThemeProvider üzerinden şu an Koyu Tema (Dark Mode) aktif mi kontrol ediyoruz.
    final ThemeProvider themeProvider = context.watch<ThemeProvider>();
    final bool isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: _currentTabIndex == 1
            ? const Color(0xFF0A2240)
            : null,
        foregroundColor: _currentTabIndex == 1 ? Colors.white : null,
        actions: [
          // AÇIK / KOYU TEMA (LIGHT & DARK MODE) GEÇİŞ BUTONU
          IconButton(
            onPressed: () => themeProvider.toggleTheme(),
            tooltip: isDark ? 'Açık Temaya Geç' : 'Koyu Temaya Geç',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? Colors.amber : null,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _currentTabIndex == 2
          ? FavoritesView(
              onFavoritesChanged: _loadFavoriteIds,
            )
          : Column(
              children: [
                if (_currentTabIndex == 1) _buildYtuBanner(),
                _buildSearchAndFilterHeader(isDark),
                Expanded(
                  child: _buildBody(isDark),
                ),
              ],
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (int index) {
          setState(() {
            _currentTabIndex = index;
            // Eğer YTÜ sekmesine geçildiyse ve henüz tüm sayfalar yüklenmediyse,
            // API'deki YTÜ etkinliklerinin tamamının görünmesi için kalan sayfaları da çekelim:
            if (index == 1 && _hasMore) {
              _loadMoreEvents();
            }
            _applyFilters();
          });
          _loadFavoriteIds();
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.location_city_outlined),
            activeIcon: Icon(Icons.location_city_rounded),
            label: 'İstanbul Keşfet',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school_rounded),
            label: 'YTÜ Kampüs',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: _favoriteIds.isNotEmpty,
              label: Text('${_favoriteIds.length}'),
              child: const Icon(Icons.favorite_outline),
            ),
            activeIcon: Badge(
              isLabelVisible: _favoriteIds.isNotEmpty,
              label: Text('${_favoriteIds.length}'),
              child: const Icon(Icons.favorite),
            ),
            label: 'Favorilerim',
          ),
        ],
      ),
    );
  }

  Widget _buildYtuBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A2240), Color(0xFF1B3B6F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF37)),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFFD4AF37),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yıldız Teknik Üniversitesi Özel Bölümü',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Davutpaşa & Yıldız Kampüsü, Sky Lab, MOBILAB ve kulüp etkinlikleri',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (String value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
            decoration: InputDecoration(
              hintText: _currentTabIndex == 1
                  ? 'YTÜ etkinliklerinde, kulüplerde veya #etiketlerde ara...'
                  : 'Biletinial, tiyatro, stand-up, konser veya sahne ara...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                          _applyFilters();
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF252A3A)
                  : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final String category = _categories[index];
                final bool isSelected = _selectedCategory == category;

                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedCategory = category;
                      _applyFilters();
                    });
                  },
                  selectedColor: _currentTabIndex == 1
                      ? const Color(0xFF0A2240)
                      : Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  showCheckmark: false,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Etkinlikler yükleniyor...',
              style: TextStyle(fontSize: 15, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 72,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'Bir Sorun Oluştu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchEvents,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredEvents.isEmpty) {
      final bool isFiltering =
          _searchQuery.isNotEmpty || _selectedCategory != 'Tümü';

      return RefreshIndicator(
        onRefresh: _fetchEvents,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isFiltering
                          ? Icons.search_off_rounded
                          : Icons.event_busy_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isFiltering
                          ? 'Bu kategoride veya aramada etkinlik bulunamadı'
                          : 'Henüz bir etkinlik bulunmuyor',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isFiltering
                          ? 'Farklı bir kategori seçebilir veya filtreleri temizleyebilirsiniz.'
                          : 'Yeni etkinlikler eklendiğinde burada listelenecektir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    if (isFiltering) ...[
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _selectedCategory = 'Tümü';
                            _applyFilters();
                          });
                        },
                        icon: const Icon(Icons.filter_alt_off_outlined),
                        label: const Text('Filtreleri Temizle'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // BAŞARILI LİSTE + SAYFALAMA (PAGINATION / DAHA FAZLA YÜKLE)
    return RefreshIndicator(
      onRefresh: _fetchEvents,
      child: ListView.builder(
        controller: _scrollController, // Kaydırma hareketini dinleyen kontrolcü
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 12),
        // Eğer daha fazla sayfa varsa (_hasMore), listenin en altına 1 ekstra eleman ("Daha Fazla Yükle" alanı) ekle
        itemCount: _filteredEvents.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Listenin son elemanına geldiysek Sayfalama (Load More) bileşenini göster:
          if (index == _filteredEvents.length) {
            return _buildPaginationFooter();
          }

          final EventModel currentEvent = _filteredEvents[index];
          final bool isFav = _favoriteIds.contains(currentEvent.id);

          return EventCard(
            event: currentEvent,
            isFavorite: isFav,
            onFavoriteToggle: () => _toggleFavorite(currentEvent),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailView(event: currentEvent),
                ),
              );
              _loadFavoriteIds();
            },
          );
        },
      ),
    );
  }

  /// Listenin en altında yer alan Sayfalama (Pagination) Göstergesi ve "Daha Fazla Yükle" Butonu.
  Widget _buildPaginationFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Center(
        child: _isLoadingMore
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  SizedBox(width: 12),
                  Text('Yeni etkinlikler yükleniyor...'),
                ],
              )
            : OutlinedButton.icon(
                onPressed: _loadMoreEvents,
                icon: const Icon(Icons.expand_more_rounded),
                label: const Text('Daha Fazla Etkinlik Yükle'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
      ),
    );
  }
}
