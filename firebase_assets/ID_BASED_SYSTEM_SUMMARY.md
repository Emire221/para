# ID Tabanlı Oyun Sistemi - Özet

**Son Güncelleme:** 5 Aralık 2025  
**Versiyon:** v1.4.0

## 🎯 Sistem Özeti

Bilgi Avcısı uygulaması, Firebase Storage'dan indirilen içerikleri ID tabanlı olarak yerel SQLite veritabanına kaydeder. Bu sistem sayesinde:

- ✅ İçerikler offline çalışır
- ✅ Yeni içerikler otomatik algılanır
- ✅ Duplicate kayıtlar önlenir (ID bazlı)
- ✅ Bandwidth tasarrufu sağlanır

---

## 🎮 Mevcut Oyunlar

### 1. Cümle Tamamlama
- **Tablo:** FillBlanksLevels
- **ID Key:** levelID
- **Örnek:** `lvl_001`, `lvl_002`
- **Özellik:** Seviye seçimli, drag & drop

### 2. 1v1 Düello (YENİ - v1.4.0)
- **Tablo:** Testler + FillBlanksLevels (mevcut tablolar)
- **Özellik:** Akıllı bot rakip, 100 Türkçe isim
- **Modlar:** Test soruları veya Cümle Tamamlama

### 3. Salla Bakalım
- **Tablo:** GuessLevels
- **ID Key:** guessID
- **Örnek:** `guess_001`, `guess_002`
- **Özellik:** Telefon sallama, sayı tahmin

### 4. Bul Bakalım
- **Tablo:** MemoryGameResults (sadece sonuçlar)
- **Özellik:** 1-10 sıralı hafıza kartları (statik içerik)

---

## 📊 Veritabanı Şeması

```sql
-- Cümle Tamamlama
CREATE TABLE FillBlanksLevels (
  levelID TEXT PRIMARY KEY,
  title TEXT,
  description TEXT,
  difficulty INTEGER,
  category TEXT,
  questions TEXT
);

-- Salla Bakalım
CREATE TABLE GuessLevels (
  guessID TEXT PRIMARY KEY,
  title TEXT,
  description TEXT,
  difficulty INTEGER,
  category TEXT,
  questions TEXT
);

-- Oyun Sonuçları
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

-- Bul Bakalım Sonuçları
CREATE TABLE MemoryGameResults (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  moves INTEGER,
  timeTaken INTEGER,
  mistakes INTEGER,
  completedAt TEXT
);
```

---

## 🔄 v1.4.0 Değişiklikleri

### Kaldırılanlar
- ❌ ArenaSets tablosu
- ❌ Arena Düello sistemi
- ❌ `lib/features/games/arena/` klasörü

### Eklenenler
- ✅ 1v1 Düello sistemi (`lib/features/duel/`)
- ✅ Akıllı bot algoritması
- ✅ 100 Türkçe bot ismi (50 erkek, 50 kadın)
- ✅ İnternet bağlantısı kontrolü
- ✅ Matchmaking animasyonu

---

## 📱 Uygulama Akışı

```
Ana Menü
    │
    ├── 📚 Dersler Tab
    │   ├── Haftalık Sınav
    │   ├── Bilgi Kartları
    │   └── Testler
    │
    └── 🎮 Oyunlar Tab
        ├── Cümle Tamamlama → Seviye Seç → Oyna
        ├── 1v1 Düello → Mod Seç → Matchmaking → Oyna
        ├── Salla Bakalım → Seviye Seç → Oyna
        └── Bul Bakalım → Oyna
```

---

## 🚀 Yeni İçerik Ekleme

### Cümle Tamamlama Level
```json
{
  "levelID": "lvl_NEW",
  "title": "Yeni Seviye",
  "difficulty": 1,
  "questions": [...]
}
```

### Salla Bakalım Level
```json
{
  "guessID": "guess_NEW",
  "title": "Yeni Seviye",
  "difficulty": 1,
  "questions": [...]
}
```

> **Not:** 1v1 Düello için ayrı içerik gerekmez - mevcut Test ve FillBlanks içeriklerini kullanır.

---

**Versiyon:** v1.4.0  
**Tarih:** 5 Aralık 2025
