# BİLGİ AVCISI 🎓

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase)](https://firebase.google.com)
[![Tests](https://img.shields.io/badge/Tests-33%20Passing-success)](./test_report.txt)
[![License](https://img.shields.io/badge/License-Private-red)]()

**BİLGİ AVCISI**, Türk öğrenciler için geliştirilmiş kapsamlı bir mobil eğitim platformudur. Sınıf bazlı içerik, interaktif testler, bilgi kartları ve video derslerle öğrenmeyi kolaylaştırır.

---

## 📋 İçindekiler

- [Özellikler](#-özellikler)
- [Teknoloji Stack](#-teknoloji-stack)
- [Mimari](#-mimari)
- [Kurulum](#-kurulum)
- [Proje Yapısı](#-proje-yapısı)
- [Sync Sistemi](#-sync-sistemi)
- [Testler](#-testler)
- [Katkıda Bulunma](#-katkıda-bulunma)

---

## ✨ Özellikler

### 🎯 Eğitim İçeriği
- **Sınıf Bazlı Organizasyon**: Her sınıf için özel içerik
- **Ders Kategorileri**: Matematik, Fen, Türkçe, Sosyal Bilimler ve daha fazlası
- **İnteraktif Testler**: Zorluk seviyelerine göre sınıflandırılmış testler
- **Bilgi Kartları (Flashcards)**: Konuları pekiştirmek için swipe-tabanlı kartlar
- **Video Dersler**: YouTube entegrasyonu ile video içerik

### 📱 Kullanıcı Deneyimi
- **Profil Yönetimi**: Öğrenci bilgilerini kaydetme ve takip
- **İlerleme Takibi**: Test sonuçları ve öğrenme geçmişi
- **Karanlık Mod**: Göz dostu arayüz
- **Offline Desteği**: İnternetsiz çalışabilme
- **Bildirimler**: Yeni içerik ve hatırlatmalar

### 🎮 Gamification
- **"Bunu Biliyor Musun?"**: Günlük ilginç bilgiler
- **Salla ve Çöz**: Shake gesture ile rastgele soru
- **Cümle Tamamlama**: Drag & drop oyunu
- **Arena Modu**: Fake live duel sistemi

### 🔄 Akıllı Sync Sistemi
- **Manifest Tabanlı**: Sadece yeni içerikleri indirir
- **Haftalık Güncellemeler**: Otomatik içerik güncellemeleri
- **tar.bz2 Formatı**: Optimize edilmiş sıkıştırma
- **İnkremental Sync**: Bandwidth tasarrufu

---

## 🛠️ Teknoloji Stack

### Framework & Dil
- **Flutter** `3.9.2+` - Cross-platform UI framework
- **Dart** `^3.9.2` - Programming language

### Backend & Cloud
- **Firebase Core** `^3.8.0` - Firebase temel servisleri
- **Firebase Auth** `^5.3.3` - Kullanıcı kimlik doğrulama
- **Firebase Storage** `^12.3.7` - Dosya depolama
- **Cloud Firestore** `^5.5.1` - NoSQL veritabanı

### State Management & Architecture
- **Riverpod** `^2.6.1` - State management
- **Freezed** `^2.5.7` - Immutable models ve code generation
- **JSON Serialization** `^4.9.0` - JSON parsing

### Local Storage
- **SQLite** (sqflite `^2.3.0`) - Yerel veritabanı
- **Shared Preferences** `^2.2.2` - Key-value storage
- **Flutter Secure Storage** `^9.2.2` - Güvenli veri saklama

### UI & Media
- **Google Fonts** `^6.2.1` - Özel fontlar
- **Lottie** `^3.1.0` - Animasyonlar
- **Cached Network Image** `^3.4.1` - Resim cache
- **YouTube Player** `^9.1.3` - Video oynatıcı

### Utilities
- **Archive** `^3.3.7` - tar.bz2 sıkıştırma/açma desteği
- **Logger** `^2.5.0` - Logging
- **Timezone** `^0.9.2` - Zaman dilimi yönetimi
- **Shake** `^3.0.0` - Shake gesture detection
- **Intl** `^0.19.0` - Internationalization

### Development
- **Build Runner** `^2.4.13` - Code generation
- **Flutter Lints** `^5.0.0` - Lint kuralları
- **Mockito** `^5.4.6` - Testing mocks
- **Flutter Test** - Unit ve widget testleri

---

## 🏗️ Mimari

Proje **Clean Architecture** prensiplerine göre organize edilmiştir:

```
lib/
├── core/                    # Temel yapılar
│   ├── constants/          # Sabitler
│   ├── theme/              # Tema yapılandırması
│   └── utils/              # Yardımcı fonksiyonlar
│
├── features/               # Özellik modülleri
│   ├── auth/              # Kimlik doğrulama
│   ├── home/              # Ana sayfa
│   ├── profile/           # Profil yönetimi
│   ├── lessons/           # Ders listesi
│   ├── tests/             # Test modülü
│   ├── flashcards/        # Bilgi kartları
│   ├── games/             # Mini oyunlar
│   └── sync/              # Senkronizasyon
│       ├── domain/        # Business logic
│       ├── presentation/  # UI & Controllers
│       └── data/          # Data sources
│
├── models/                # Veri modelleri (Freezed)
│   ├── lesson.dart
│   ├── topic.dart
│   ├── test.dart
│   ├── flashcard_set.dart
│   └── ...
│
├── repositories/          # Veri erişim katmanı
│   ├── test_repository.dart
│   ├── flashcard_repository.dart
│   └── ...
│
├── services/              # Servisler
│   ├── firebase_storage_service.dart
│   ├── database_helper.dart
│   ├── sync_service.dart
│   ├── notification_service.dart
│   └── ...
│
├── screens/               # UI Ekranları
│   ├── home_screen.dart
│   ├── test_screen.dart
│   ├── flashcards_screen.dart
│   └── ...
│
├── widgets/               # Yeniden kullanılabilir widget'lar
│   ├── custom_button.dart
│   ├── question_card.dart
│   └── ...
│
└── main.dart              # Uygulama giriş noktası
```

### Veri Akışı

```
Firebase Storage (tar.bz2)
         ↓
  FirebaseStorageService
         ↓
  Local SQLite Database
         ↓
    Repositories
         ↓
  Riverpod Providers
         ↓
        UI
```

---

## 🚀 Kurulum

### Gereksinimler

- Flutter SDK `^3.9.2`
- Dart SDK `^3.9.2`
- Android Studio / VS Code
- Firebase hesabı ve yapılandırması

### Adımlar

1. **Repository'yi klonlayın**
   ```bash
   git clone https://github.com/Emire221/sonkineson.git
   cd sonkineson
   ```

2. **Bağımlılıkları yükleyin**
   ```bash
   flutter pub get
   ```

3. **Code generation çalıştırın**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Firebase yapılandırması**
   - `lib/firebase_options.dart` dosyasını kendi Firebase projenize göre güncelleyin
   - Android ve iOS için `google-services.json` ve `GoogleService-Info.plist` ekleyin

5. **Uygulamayı çalıştırın**
   ```bash
   flutter run
   ```

### Testleri Çalıştırma

```bash
# Tüm testleri çalıştır
flutter test

# Belirli bir test dosyasını çalıştır
flutter test test/services/firebase_storage_service_test.dart

# Test coverage raporu
flutter test --coverage
```

### Analiz

```bash
# Kod analizi
flutter analyze

# Lint kontrolleri
flutter analyze --no-pub
```

---

## 📁 Proje Yapısı

### Temel Dosyalar

| Dosya | Açıklama |
|-------|----------|
| `pubspec.yaml` | Proje bağımlılıkları ve metadata |
| `analysis_options.yaml` | Lint kuralları |
| `firebase_options.dart` | Firebase yapılandırması |
| `main.dart` | Uygulama giriş noktası |

### Veritabanı Şeması (SQLite)

```sql
-- Dersler
CREATE TABLE Dersler (
  dersID TEXT PRIMARY KEY,
  dersAdi TEXT,
  ikon TEXT,
  renk TEXT
);

-- Konular
CREATE TABLE Konular (
  konuID TEXT PRIMARY KEY,
  dersID TEXT,
  konuAdi TEXT,
  sira INTEGER,
  FOREIGN KEY(dersID) REFERENCES Dersler(dersID)
);

-- Testler
CREATE TABLE Testler (
  testID TEXT PRIMARY KEY,
  konuID TEXT,
  testAdi TEXT,
  zorluk INTEGER,
  cozumVideoURL TEXT,
  sorular TEXT, -- JSON
  FOREIGN KEY(konuID) REFERENCES Konular(konuID)
);

-- Bilgi Kartları
CREATE TABLE BilgiKartlari (
  kartSetID TEXT PRIMARY KEY,
  konuID TEXT,
  kartAdi TEXT,
  kartlar TEXT, -- JSON
  FOREIGN KEY(konuID) REFERENCES Konular(konuID)
);

-- İndirilen Dosyalar (Sync için)
CREATE TABLE DownloadedFiles (
  path TEXT PRIMARY KEY,
  downloadedAt DATETIME
);
```

---

## 🔄 Sync Sistemi

### Manifest Tabanlı Senkronizasyon

Uygulama, Firebase Storage'dan içerikleri akıllı bir şekilde indirir:

#### 1. Manifest Yapısı (`manifest.json`)

```json
{
  "version": "v2.0",
  "updatedAt": "2024-01-15T10:00:00Z",
  "files": [
    {
      "path": "3_Sinif/hafta_1.tar.bz2",
      "type": "tar.bz2",
      "version": "v1",
      "hash": "abc123...",
      "addedAt": "2024-01-15T10:00:00Z"
    },
    {
      "path": "3_Sinif/konulistesi.json",
      "type": "json",
      "version": "v1",
      "hash": "def456...",
      "addedAt": "2024-01-15T10:00:00Z"
    }
  ]
}
```

#### 2. Sync Akışı

```
1. Manifest Download
   ↓
2. Versiyon Karşılaştırma
   ↓
3. Yeni Dosyaları Tespit Et
   ↓
4. tar.bz2 Arşivleri İndir
   ↓
5. BZip2 → Tar Decode
   ↓
6. Dosyaları Çıkart
   ↓
7. SQLite'a Kaydet
   ↓
8. Local Manifest Güncelle
```

#### 3. tar.bz2 Format Desteği

```dart
// BZip2 + Tar codec kullanımı
final decompressed = BZip2Decoder().decodeBytes(data);
final archive = TarDecoder().decodeBytes(decompressed);

// Dosyaları çıkart
for (final file in archive.files) {
  if (file.isFile) {
    await File(outPath).writeAsBytes(file.content);
  }
}
```

### Haftalık Güncellemeler

- **Zamanlama**: Her Pazartesi 00:00
- **Bildirim**: Kullanıcıya push notification
- **Opsiyonel**: Manuel güncelleme veya erteleme

---

## 🧪 Testler

### Test İstatistikleri

- **Toplam Test**: 33
- **Başarı Oranı**: %100
- **Coverage**: Unit, Widget, Integration

### Test Kategorileri

#### 1. Service Tests
```dart
test('processLocalArchiveContent parses and inserts data correctly', () async {
  // Firebase Storage Service testleri
  // tar.bz2 açma, parsing, DB kaydetme
});
```

#### 2. Repository Tests
```dart
test('flashcard repository fetches data correctly', () async {
  // Repository pattern testleri
});
```

#### 3. Widget Tests
```dart
testWidgets('Test screen displays questions', (WidgetTester tester) async {
  // UI widget testleri
});
```

#### 4. Controller Tests
```dart
test('sync controller handles manifest correctly', () async {
  // State management testleri
});
```

---

## 📊 Kod Kalitesi

### Analiz Sonuçları

```
✅ No issues found!
📊 Analyzed in 68.1s
🧪 33/33 tests passing
📈 100% success rate
```

### Lint Kuralları

Proje `flutter_lints ^5.0.0` kullanır:
- Naming conventions
- Type safety
- Best practices
- Code organization

---

## 🎨 Kullanıcı Arayüzü

### Ekranlar

| Ekran | Açıklama |
|-------|----------|
| **Onboarding** | İlk açılış animasyonu (Lottie) |
| **Profile Setup** | Kullanıcı bilgileri girişi |
| **Home** | Ana sayfa - ders kategorileri |
| **Lessons** | Ders listesi |
| **Topics** | Konu listesi |
| **Tests** | Test çözme ekranı |
| **Flashcards** | Bilgi kartları (swipe) |
| **Results** | Test sonuçları |
| **Arena** | Duel oyunu |
| **Settings** | Ayarlar |

### Tema

- **Primary Color**: Özelleştirilebilir
- **Dark Mode**: Desteklenir
- **Google Fonts**: Modern tipografi
- **Animations**: Lottie ve Flutter animasyonları

---

## 🔐 Güvenlik

- **Firebase Auth**: Güvenli kimlik doğrulama
- **Secure Storage**: Hassas verilerin şifrelenmesi
- **Input Validation**: Form doğrulama
- **Error Handling**: Kapsamlı hata yönetimi

---

## 🚀 Deployment

### Android

```bash
flutter build apk --release
# veya
flutter build appbundle --release
```

### iOS

```bash
flutter build ios --release
```

---

## 📝 Değişiklik Geçmişi

### [v1.0.0] - 2024-11-28

#### Added
- ✨ tar.bz2 format desteği (zip'den migration)
- ✨ Manifest tabanlı sync sistemi
- ✨ Haftalık otomatik güncellemeler
- ✨ Gamification özellikleri
- ✨ Comprehensive test suite

#### Changed  
- 🔄 Storage formatı: .zip → .tar.bz2
- 🔄 Decoder: ZipDecoder → BZip2Decoder + TarDecoder
- 🔄 Sync logic: Full download → Incremental sync

#### Fixed
- 🐛 Test compatibility with new archive format
- 🐛 Android local.properties issue

---

## 🤝 Katkıda Bulunma

Bu proje özel bir projedir. Katkı kabul edilmemektedir.

---

## 📄 Lisans

Bu proje özel mülkiyettir. Tüm hakları saklıdır.

---

## 📞 İletişim

- **Repository**: [github.com/Emire221/sonkineson](https://github.com/Emire221/sonkineson)
- **Issues**: GitHub Issues'ı kullanın

---

## 📚 Ek Kaynaklar

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Riverpod Guide](https://riverpod.dev/)
- [Freezed Package](https://pub.dev/packages/freezed)

---

**Geliştirici**: Emire221  
**Son Güncelleme**: 28 Kasım 2024  
**Versiyon**: 1.0.0

---

<p align="center">Made with ❤️ for Turkish Students</p>
