# BİLGİ AVCISI 🎓

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase)](https://firebase.google.com)
[![Tests](https://img.shields.io/badge/Tests-33%20Passing-success)](./test_report.txt)
[![Quality](https://img.shields.io/badge/Analysis-No%20Issues-success)](./analyze_output.txt)
[![License](https://img.shields.io/badge/License-Private-red)]()

**BİLGİ AVCISI**, Türk öğrenciler için geliştirilmiş kapsamlı bir mobil eğitim platformudur. Sınıf bazlı içerik, interaktif testler, bilgi kartları ve gamification özellikleriyle öğrenmeyi kolaylaştırır.

---

## 📋 İçindekiler

- [Özellikler](#-özellikler)
- [Teknoloji Stack](#-teknoloji-stack)
- [Mimari](#-mimari)
- [Kurulum](#-kurulum)
- [Proje Yapısı](#-proje-yapısı)
- [Sync Sistemi](#-sync-sistemi)
- [Testler](#-testler)
- [Son Güncellemeler](#-son-güncellemeler)

---

## ✨ Özellikler

### 🎯 Eğitim İçeriği
- **Sınıf Bazlı Organizasyon**: Her sınıf için özel içerik
- **Ders Kategorileri**: Matematik, Fen, Türkçe, Sosyal Bilimler ve daha fazlası
- ** İnteraktif Testler**: Zorluk seviyelerine göre sınıflandırılmış testler
- **Bilgi Kartları (Flashcards)**: Konuları pekiştirmek için swipe-tabanlı kartlar
- **Sonuç Ekranları**: Detaylı puan ve istatistik gösterimi

### 📱 Kullanıcı Deneyimi
- **Profil Yönetimi**: Öğrenci bilgilerini kaydetme ve takip
- **İlerleme Takibi**: Test sonuçları ve öğrenme geçmişi
- **Karanlık Mod**: Optimize edilmiş göz dostu arayüz
- **Offline Desteği**: İnternetsiz çalışabilme
- **Bildirimler**: Yeni içerik ve hatırlatmalar
- **Türkçe Localization**: Tam Türkçe tarih ve zaman desteği

### 🎮 Gamification
- **"Bunu Biliyor Musun?"**: Günlük ilginç bilgiler
- **Salla ve Çöz**: Shake gesture ile rastgele soru
- **Cümle Tamamlama**: Drag & drop oyunu (veritabanı entegreli)
- **Arena Modu**: Fake live duel sistemi (veritabanı entegreli)
- **Maskot Sistemi**: Öğrenme sürecinde eşlik eden sanal arkadaş

### 📝 Türkiye Geneli Deneme Sınavı
- **Haftalık Sınav**: Her hafta yeni sınav yayınlanır
- **Zaman Duyarlı**: Pazartesi 00:00 - Çarşamba 23:59 arası aktif
- **Tek Giriş Hakkı**: Kullanıcı sınava sadece 1 kez girebilir
- **Sonuç Beklemesi**: Pazar 12:00'da sonuçlar açıklanır
- **Türkiye Sıralaması**: Tüm katılımcılar arasında sıralama
- **Otomatik Temizlik**: Yeni sınav geldiğinde eski veriler silinir

### 🔄 Akıllı Sync Sistemi
- **Manifest Tabanlı**: Sadece yeni içerikleri indirir
- **Haftalık Güncellemeler**: Otomatik içerik güncellemeleri
- **tar.bz2 Formatı**: Optimize edilmiş sıkıştırma
- **İnkremental Sync**: Bandwidth tasarrufu
- **Veritabanı İlk Depolama**: Tüm oyun içerikleri lokal SQLite'ta

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

### Utilities
- **Archive** `^3.3.7` - tar.bz2 sıkıştırma/açma desteği
- **Logger** `^2.5.0` - Logging
- **Timezone** `^0.9.2` - Zaman dilimi yönetimi
- **Shake** `^3.0.0` - Shake gesture detection
- **Intl** `^0.19.0` - Internationalization (Türkçe desteği)

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
│   ├── providers/          # Global provider'lar
│   ├── theme/              # Tema yapılandırması
│   └── utils/              # Yardımcı fonksiyonlar
│
├── features/               # Özellik modülleri
│   ├── auth/              # Kimlik doğrulama
│   ├── mascot/            # Maskot sistemi
│   │   ├── domain/        # Entities & Repository interfaces
│   │   ├── data/          # Repository implementations
│   │   └── presentation/  # UI & Controllers
│   ├── test/              # Test modülü
│   │   ├── domain/
│   │   ├── controller/
│   │   └── presentation/
│   ├── games/             # Mini oyunlar
│   │   ├── fill_blanks/  # Cümle tamamlama
│   │   └── arena/        # Arena düello
│   └── sync/              # Senkronizasyon
│
├── models/                # Veri modelleri (Freezed)
│   ├── lesson.dart
│   ├── topic.dart
│   ├── test.dart
│   ├── flashcard_model.dart
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
│   ├── data_service.dart
│   ├── notification_service.dart
│   └── ...
│
├── screens/               # UI Ekranları
│   ├── main_screen.dart
│   ├── test_screen.dart
│   ├── flashcards_screen.dart
│   ├── result_screen.dart
│   └── ...
│
├── widgets/               # Yeniden kullanılabilir widget'lar
│   ├── glass_container.dart
│   ├── custom_button.dart
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
   git clone https://github.com/Emire221/para.git
   cd para
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
flutter analyze --no-fatal-warnings
```

**Güncel Durum:** ✅ No issues found!

---

## 📁 Proje Yapısı

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

-- Fill Blanks Levels
CREATE TABLE FillBlanksLevels (
  levelID TEXT PRIMARY KEY,
  title TEXT,
  description TEXT,
  difficulty INTEGER,
  category TEXT,
  questions TEXT -- JSON
);

-- Arena Sets
CREATE TABLE ArenaSets (
  arenaSetID TEXT PRIMARY KEY,
  title TEXT,
  description TEXT,
  difficulty INTEGER,
  category TEXT,
  questions TEXT -- JSON
);

-- Game Results
CREATE TABLE GameResults (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  gameType TEXT NOT NULL,
  score INTEGER,
  correctCount INTEGER,
  wrongCount INTEGER,
  totalQuestions INTEGER,
  completedAt TEXT,
  details TEXT
);

-- User Pets (Maskot)
CREATE TABLE UserPets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  petType TEXT NOT NULL,
  petName TEXT NOT NULL,
  currentXp INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  mood INTEGER DEFAULT 100,
  createdAt TEXT DEFAULT (datetime('now'))
);

-- Haftalık Sınavlar (İndirilen sınav verileri)
CREATE TABLE WeeklyExams (
  weeklyExamId TEXT PRIMARY KEY,
  title TEXT,
  weekStart TEXT,
  duration INTEGER,
  description TEXT,
  questions TEXT -- JSON
);

-- Haftalık Sınav Sonuçları
CREATE TABLE WeeklyExamResults (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  examId TEXT NOT NULL,
  odaId TEXT NOT NULL,
  odaIsmi TEXT,
  odaBaslangic TEXT,
  odaBitis TEXT,
  sonucTarihi TEXT,
  odaDurumu TEXT,
  odaKatilimciId TEXT NOT NULL,
  cevaplar TEXT, -- JSON
  dogru INTEGER,
  yanlis INTEGER,
  bos INTEGER,
  puan INTEGER,
  siralama INTEGER,
  toplamKatilimci INTEGER,
  completedAt TEXT
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
  "updatedAt": "2024-12-03T10:00:00Z",
  "files": [
    {
      "path": "3_Sinif/hafta_1.tar.bz2",
      "type": "tar.bz2",
      "version": "v1",
      "hash": "abc123...",
      "addedAt": "2024-12-03T10:00:00Z"
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
7. SQLite'a Kaydet (Oyun verileri de dahil)
   ↓
8. Local Manifest Güncelle
```

---

## 🧪 Testler

### Test İstatistikleri

- **Toplam Test**: 33
- **Başarı Oranı**: %100
- **Coverage**: Unit, Widget, Integration

---

## 📊 Kod Kalitesi

### Analiz Sonuçları

```
✅ No issues found!
📊 Analyzed in 3.1s
🧪 33/33 tests passing
📈 100% success rate
```

---

## 📝 Son Güncellemeler

### [v1.2.0] - 2025-12-04

#### Added ✨
- **Haftalık Sınav Sistemi**: Türkiye geneli deneme sınavı özelliği
  - Pazartesi 00:00 - Çarşamba 23:59 arası sınav aktif
  - Pazar 12:00'da sonuçlar açıklanıyor
  - Her kullanıcı sadece 1 kez sınava girebilir
  - Sınav kartı her zaman görünür (sınav yoksa bilgi mesajı)
- **WeeklyExamCard**: Dersler ekranında her zaman görünen sınav kartı
- **WeeklyExamScreen**: Sınav çözme ekranı
- **WeeklyExamResultScreen**: Sınav sonuçları ekranı
- **clearOldWeeklyExamData()**: Yeni sınav geldiğinde eski verileri temizleme

#### Fixed 🐛
- **Sınav Kartı Görünürlük**: Kart artık hafta kontrolü yapmadan her zaman gösteriliyor
- **Sınav Tekrar Girişi**: Kullanıcı aynı sınava tekrar giremez

#### Changed 🔄
- **Sonuç Açıklama Saati**: 20:00'dan 12:00'a değiştirildi
- **Motivasyon Mesajları**: Tüm mesajlar Pazar 12:00 olarak güncellendi
- **Sync Sistemi**: Yeni sınav geldiğinde eski sınav ve sonuçları otomatik siliniyor

### İstatistikler
- 📝 5 dosya güncellendi
- ➕ 286 satır eklendi
- ➖ 31 satır silindi
- ✅ 0 lint hatası

---

### [v1.1.0] - 2024-12-03

#### Added ✨
- **Maskot Sistemi**: Öğrencilere eşlik eden sanal arkadaş
- **ResultScreen Entegrasyonu**: Flashcards için detaylı sonuç ekranı
- **Türkçe Localization**: İntl paketi ile tam Türkçe tarih desteği
- **Oyun Veritabanı Entegrasyonu**: Fill Blanks ve Arena artık lokal veritabanından veri okuyor

#### Fixed 🐛
- **Navigasyon İyileştirmesi**: Profil kurulumu sonrası geri butonu kaldırıldı (pushAndRemoveUntil)
- **Karanlık Mod**: AppBar metinlerinin kontrast sorunu düzeltildi
- **Test Puanlama**: Race condition çözüldü, son soru artık doğru puanlanıyor
- **Localization Crash**: Başarılarım ekranındaki LocaleDataException hatası giderildi
- **Async Gap Handling**: BuildContext kullanımında mounted kontrolü eklendi

#### Removed 🗑️
- **Video Özelliği**: Kullanılmayan "Gizli İpuçları İzle" özelliği tamamen kaldırıldı
  - video_player_screen.dart silindi
  - Videolar tablosu kaldırıldı
  - 304 satır kod temizlendi

#### Changed 🔄
- **Firebase Storage Service**: levelID → id dönüşümü kaldırıldı, veriler olduğu gibi kaydediliyor
- **Oyun Ekranları**: Firebase'den Firebase Storage yerine DatabaseHelper kullanıyor

### İstatistikler
- 📝 13 dosya güncellendi
- 🗑️ 1 dosya silindi
- ➕ 61 satır eklendi
- ➖ 304 satır silindi
- ✅ 0 lint hatası

---

## 🤝 Katkıda Bulunma

Bu proje özel bir projedir. Katkı kabul edilmemektedir.

---

## 📄 Lisans

Bu proje özel mülkiyettir. Tüm hakları saklıdır.

---

## 📞 İletişim

- **Repository**: [github.com/Emire221/para](https://github.com/Emire221/para)
- **Issues**: GitHub Issues'ı kullanın

---

## 📚 Ek Kaynaklar

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Riverpod Guide](https://riverpod.dev/)
- [Freezed Package](https://pub.dev/packages/freezed)

---

**Geliştirici**: Emire221  
**Son Güncelleme**: 4 Aralık 2025  
**Versiyon**: 1.2.0

---

<p align="center">Made with ❤️ for Turkish Students</p>
