# 🎟️ İstanbul & YTÜ Etkinlik Keşif Uygulaması (MOBILAB Görev Projesi)

Yıldız Teknik Üniversitesi **SKY LAB Bilgisayar Bilimleri Kulübü - MOBILAB** ekibi görevi kapsamında geliştirilmiş; İstanbul genelindeki kültür-sanat, tiyatro, stand-up, konser, teknoloji zirveleri ile **Yıldız Teknik Üniversitesi (YTÜ)** kampüs ve kulüp etkinliklerini tek bir çatı altında buluşturan modern bir **Flutter** mobil uygulamasıdır.

---

## 🚀 Proje Hakkında ve Özellikler

Bu uygulama, gerçek dünya koşullarını (gecikmeli yanıtlar ve sunucu hataları) simüle eden **[MOBILAB Task API](https://mobilab-task-api.vercel.app/docs)** servisiyle entegre çalışacak şekilde sıfırdan tasarlanmıştır.

### ✨ Temel ve Bonus Özellikler
* **🏙️ 3 Özel Keşif Bölümü (`BottomNavigationBar`):**
  1. **İstanbul Keşfet:** Biletinial tiyatro oyunları, stand-up gösterileri, AKM bale/opera temsilleri, İstanbul Modern sergileri, konserler ve teknoloji zirveleri.
  2. **🎓 YTÜ Kampüs (Özel Bölüm):** Sadece Yıldız Teknik Üniversitesi (Davutpaşa & Yıldız Kampüsü, Sky Lab, MOBILAB ve öğrenci kulüpleri) etkinliklerini süzen özel lacivert-altın temalı kampüs bölümü.
  3. **❤️ Favorilerim:** Cihaz hafızasına kaydedilen ve çevrimdışı (offline) durumda dahi görüntülenebilen favori etkinlikler sekmesi.
* **🔍 Anlık Arama ve Kategori Filtreleme:** Başlık, sahne/konum, düzenleyen kurum veya `#etiket` bazlı milisaniyelik arama (`TextField`) ve yatay kaydırılabilir kategori çubuğu (`ChoiceChip` - *Tiyatro, Stand-Up, Müzik & Konser, Kültür & Sanat, Teknoloji, Workshop, Hackathon, Seminer, Sosyal*).
* **🛡️ Kusursuz UI Durum Yönetimi (Loading / Error / Empty):**
  * **Yükleniyor (`Loading`):** İlk veri çekiminde kullanıcıyı bilgilendiren yükleme animasyonu.
  * **Hata ve Yeniden Deneme (`Error & Retry`):** API'nin simüle ettiği `500/503` sunucu hataları veya zaman aşımı (`Timeout`) durumlarında çökme yaşanmadan Türkçe hata mesajı ve **"Tekrar Dene"** butonu gösterimi.
  * **Boş Durum (`Empty State`):** Veri bulunamadığında veya filtre eşleşmediğinde tek tıkla filtre sıfırlama imkanı sunan bilgilendirici ekran.
* **🔄 Pull-to-Refresh ve Sayfalama (`Pagination / Infinite Scroll`):**
  * Listeyi aşağı çekerek (`RefreshIndicator`) verileri tazeleme.
  * `ScrollController` ile listenin sonuna inildiğinde veya **"Daha Fazla Etkinlik Yükle"** butonuna basıldığında sonraki sayfaları yükleme.
* **🎬 Hero Animasyonu ve Zengin Detay Ekranı:**
  * Liste kartındaki görselden detay sayfasındaki büyük afişe akıcı `Hero` geçişi.
  * Liste uç noktasında (`/events`) yer almayan `description` (açıklama) verisinin detay sayfasında `/events/{id}` uç noktasından asenkron çekilmesi.
  * Salon/kontenjan doluluk oranı çubuğu (`LinearProgressIndicator`) ve **Biletinial Bilet Özeti / Kayıt (`ModalBottomSheet`)** ekranı.
* **🌗 Kalıcı Açık / Koyu Tema (`Light & Dark Mode`):**
  * Üst bardaki (`AppBar`) Güneş/Ay ikonuyla tek tuşla tema değiştirme ve seçimin `SharedPreferences` ile kalıcı olarak saklanması.
* **⚙️ GitHub Actions ile CI/CD:**
  * Her `push` ve `pull_request` işleminde otomatik `flutter pub get`, `flutter analyze` ve `flutter test` kontrolü.

---

## 🛠️ Kurulum ve Çalıştırma Adımları

Projeyi kendi bilgisayarınızda çalıştırmak için aşağıdaki adımları izleyebilirsiniz:

### 1. Gereksinimler
* **Flutter SDK:** `^3.13.7` veya güncel kararlı sürüm
* **Android Studio** (Android Emülatör için) veya **VS Code**

### 2. Projeyi İndirme ve Paketleri Kurma
```bash
# 1. Proje klasörüne gidin
cd flutter_application_1

# 2. Bağımlılıkları (Dio, SharedPreferences, Provider vb.) yükleyin
flutter pub get
```

### 3. Uygulamayı Başlatma
```bash
# Açık olan emülatör veya fiziksel cihazda çalıştırın
flutter run
```

### 4. Kod Analizi ve Testleri Çalıştırma
```bash
flutter analyze
flutter test
```

---

## 🏛️ Klasör Yapısı ve Mimari Kararlar

Projede, ölçeklenebilirliği ve kod okunabilirliğini artırmak amacıyla **Feature-First (Özellik Odaklı - Core & Features)** mimarisi uygulanmıştır:

```text
lib/
├── core/                                # Uygulama genelinde paylaşılan çekirdek katman
│   ├── network/
│   │   └── api_service.dart             # Dio istemcisi, Timeout ayarları ve merkezi hata yönetimi (ApiException)
│   ├── storage/
│   │   └── favorite_service.dart        # SharedPreferences ile kalıcı favori yönetimi
│   └── theme/
│       └── theme_provider.dart          # Provider + SharedPreferences ile Açık/Koyu tema yönetimi
│
├── features/                            # Uygulamanın işlevsel özellikleri
│   └── events/                          # Etkinlik Keşif özelliği
│       ├── data/
│       │   └── istanbul_events_data.dart# İstanbul Kültür-Sanat, Teknoloji ve Biletinial veri seti
│       ├── models/
│       │   └── event_model.dart         # EventModel ve PaginatedEventsResponse veri modelleri
│       ├── screens/
│       │   ├── event_list_view.dart     # Ana liste, arama, filtre, sayfalama ve YTÜ Kampüs sekmesi
│       │   ├── event_detail_view.dart   # Hero animasyonlu detay ve bilet/kayıt ekranı
│       │   └── favorites_view.dart      # Çevrimdışı destekli Favori Etkinlikler ekranı
│       └── widgets/
│           └── event_card.dart          # Yeniden kullanılabilir (Reusable) etkinlik kartı bileşeni
│
└── main.dart                            # Uygulama başlangıç noktası ve Material 3 Tema yapılandırması
```

### Mühendislik Kararları: Neden Bu Yapıları Seçtik?
1. **Neden Feature-First (`core/` ve `features/`) Mimarisi?**
   * Tüm dosyaları tek bir klasöre yığmak yerine ağ katmanı (`network`), yerel depolama (`storage`) ve tema (`theme`) gibi bağımsız araçları `core/` altında; doğrudan etkinlik alanıyla ilgili ekran, model ve bileşenleri `features/events/` altında topladık. Bu sayede yeni bir özellik (örneğin Kullanıcı Profili) eklendiğinde mevcut kodlara dokunmadan `features/profile/` klasörü açılabilir (**Separation of Concerns**).
2. **Neden `http` Yerine `Dio` Paketi?**
   * MOBILAB Task API gerçek dünyayı taklit ederek zaman zaman gecikmeli yanıtlar veya `500` sunucu hataları döndürmektedir. `Dio`, `BaseOptions` üzerinden merkezi `connectTimeout` / `receiveTimeout` (15 saniye) tanımlamayı, `queryParameters` ile temiz URL oluşturmayı ve `DioExceptionType` ile zaman aşımı, sunucu hatası ve internet kopmasını birbirinden net şekilde ayırmayı çok daha güvenli hale getirir.
3. **Neden `SharedPreferences`?**
   * Kullanıcının favoriye eklediği etkinlikler ve seçtiği Açık/Koyu tema tercihi ilişkisel bir veritabanı (SQL) karmaşıklığı gerektirmez. `SharedPreferences`, anahtar-değer (`key-value`) yapısıyla hem favori ID kümesini hem de JSON'a dönüştürülmüş (`jsonEncode`) etkinlik nesnelerini diskte hafif ve hızlı biçimde saklar.
4. **Neden Liste ve Detay İçin Ortak `EventModel` (`String? description`)?**
   * API tasarımında `/events` uç noktası performans için `description` alanını göndermezken, `/events/{id}` uç noktası bu alanı göndermektedir. `description` alanını nullable (`String?`) tanımlayarak iki ayrı model sınıfı yazma tekrarından (DRY prensibi) kaçındık; kullanıcı karta tıkladığında eldeki veriyi `Hero` animasyonuyla anında ekrana basıp arka planda sadece eksik olan açıklamayı tamamladık.

---

## 🤖 AI Kullanım Süreci (Senior-Junior İşbirliği Metodolojisi)

Bu projeyi geliştirirken yapay zeka asistanını (Antigravity / Gemini) **"her şeyi tek seferde yazıp veren bir kod üreteci"** olarak **kullanmadım**. Yazılıma yeni başlayan bir geliştirici olarak, süreci bir **Senior-Junior Pair Programming (Eşli Programlama)** seansı gibi kurguladım.

### İzlediğim Strateji: 5 Adımlı Modüler Promptlama
Körlemesine kopyala-yapıştır yapmak yerine projeyi **5 mantıksal aşamaya** böldüm ve bir adımı tam olarak anlayıp doğrulamadan bir sonraki adıma geçmedim:

1. **Adım 1 – Mimari, Paketler ve Güvenli Ağ Katmanı:** Önce klasör yapısını (Feature-First) ve API'nin hata/gecikme davranışını yönetecek `EventModel` ile `ApiService` sınıflarını oluşturup her satırın mantığını Türkçe açıklamalarla inceledim.
2. **Adım 2 – Etkinlik Listesi ve Zorunlu UI Durumları:** Veri katmanı hazırlandıktan sonra `EventCard` ve `EventListView` bileşenlerini; `Loading`, `Error (Retry butonlu)`, `Empty` durumlarını ve `RefreshIndicator` (Pull-to-Refresh) yapısını kurguladım.
3. **Adım 3 – Detay Ekranı ve Hero Animasyonu:** Sayfalar arası `Navigator.push` geçişini, görsel `Hero` animasyonunu ve `/events/{id}` üzerinden asenkron açıklama yükleme mantığını ekledim.
4. **Adım 4 – Anlık Arama, Kategori Filtreleme, Kalıcı Favoriler ve Ürün Özelleştirmesi:** `TextField` ve `ChoiceChip` ile filtrelemeyi, `SharedPreferences` ile kalıcı favorileri kurdum. Ardından kendi ürün vizyonumu katarak uygulamayı **İstanbul Kültür-Sanat / Teknoloji & Biletinial** etkinlikleriyle zenginleştirdim ve **Sadece YTÜ Kampüs** için ayrı bir bölüm tasarladım.
5. **Adım 5 – Bonus Özellikler, CI/CD ve Dokümantasyon:** Kalıcı Açık/Koyu Tema (`ThemeProvider`), `ScrollController` ile Sayfalama (`Pagination`) ve `.github/workflows/flutter_ci.yml` entegrasyonunu tamamladım.

### Süreçte Kullandığım Örnek Promptlar

> **Örnek Prompt 1 (Mimari ve Hata Yönetimi):**
> *"Merhaba! Flutter ile bir 'Etkinlik Keşif Uygulaması' geliştiriyorum. Yazılıma yeni başladım, bu yüzden yazdığın kodların mantığını, satır satır ne işe yaradığını Türkçe olarak açıklamalı ve yorum satırlarıyla desteklemelisin. Feature-First klasör yapısını açıkla, https://mobilab-task-api.vercel.app/docs API'sine uygun bir Dart Model sınıfı ve Dio kullanan bir ApiService yaz. API'nin yavaş yanıt verebileceğini veya hata dönebileceğini göz önünde bulundurarak try-catch, timeout ve hata durumlarını yönetecek güvenli bir yapı kur."*

> **Örnek Prompt 2 (Zorunlu UI Durumları ve Pull-to-Refresh):**
> *"Şimdi 2. Adım ile devam ediyoruz: Etkinlik Listesi ve UI Durumları. API çağrısı sırasında kullanıcıya Yükleniyor (CircularProgressIndicator), Hata (Hata mesajı ve 'Tekrar Dene' Retry butonu) ve Boş Liste ('Henüz bir etkinlik bulunmuyor') durumlarını kusursuz gösterelim. Kullanıcı sayfayı aşağı kaydırdığında verilerin yenilenmesini sağlayan RefreshIndicator yapısını ekle."*

> **Örnek Prompt 3 (Ürün Geliştirme & Özelleştirme):**
> *"Uygulama güzel ama bence İstanbul'daki tüm etkinlikler olsun (kültür, sanat, teknoloji tarzı), Biletinial sitesindeki popüler etkinlikleri de ekleyelim ve sadece YTÜ ile ilgili de özel bir bölüm olsun."*

> **Örnek Prompt 4 (Bonus Özellikler ve Mühendislik Kalitesi):**
> *"Zorunlu özellikleri tamamladık, şimdi 5. ve Son Adım ile devam ediyoruz: Üst bardan tek tuşla değiştirilebilen ve tercihi SharedPreferences ile hafızada tutan Açık/Koyu tema geçişi ekle, ScrollController ve 'Daha Fazla Yükle' ile sayfalama (Pagination) entegre et ve GitHub Actions (.github/workflows/flutter_ci.yml) kur."*

### AI ile Birlikte Çözülen Gerçek Mühendislik Sorunları
* **API Liste ve Detay Farklılığı:** API'nin `/events` listesinde `description` alanını göndermediğini tespit edip, detay sayfasına geçildiğinde ekranın beklemeden açılmasını (`Hero` animasyonunun takılmamasını) ve açıklamanın arka planda `/events/{id}` üzerinden tamamlanmasını sağladık.
* **Android Emülatör & NDK Yapılandırması:** Derleme sırasında karşılaşılan Android SDK/NDK sürüm uyumsuzluğunu (`ndkVersion`) ve Dio `5.11.1` sürümündeki `DioExceptionType` enum güncellemelerini analiz ederek birlikte çözdük.
