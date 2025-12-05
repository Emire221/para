# Firebase Storage ID Tabanlı Oyun Sistemi

**Son Güncelleme:** 5 Aralık 2025  
**Versiyon:** v1.4.0

## 📦 Dosya Yapısı

Firebase Storage'a yüklenecek oyun JSON dosyaları artık ID tabanlı çalışıyor:

```
.tar.bz2 arşivi içinde:
├── level_001.json      (levelID: lvl_001)
├── level_002.json      (levelID: lvl_002)
├── guess_001.json      (guessID: guess_001)
├── guess_002.json      (guessID: guess_002)
├── derslistesi.json
├── konulistesi.json
└── [diğer içerikler...]
```

## 🎮 Mevcut Oyunlar (4 Adet)

| Oyun | Tablo | ID Key | Açıklama |
|------|-------|--------|----------|
| Cümle Tamamlama | FillBlanksLevels | levelID | Drag & drop boşluk doldurma |
| 1v1 Düello | - | - | Akıllı bot ile yarış (veritabanından soru çeker) |
| Salla Bakalım | GuessLevels | guessID | Telefonu salla, sayı tahmin et |
| Bul Bakalım | MemoryGameResults | - | 1-10 sıralı hafıza oyunu (statik) |

> **Not:** 1v1 Düello sistemi, Test ve FillBlanksLevels tablolarından rastgele soru çeker. Ayrı bir tablo kullanmaz.

## 🔍 Otomatik Algılama Sistemi

`processLocalArchiveContent` metodu JSON dosyalarını otomatik olarak algılayıp doğru tabloya ekler:

| Dosyada Varsa | Tablo | Örnek |
|---------------|-------|-------|
| `testID` | Testler | test_mat_001.json |
| `kartSetID` | BilgiKartlari | bilgi_fen_001.json |
| `levelID` | FillBlanksLevels | level_001.json |
| `guessID` | GuessLevels | guess_001.json |

## 📝 JSON Örnekleri

### Fill Blanks Level (level_001.json)
```json
{
  "levelID": "lvl_001",
  "title": "Temel Matematik",
  "difficulty": 1,
  "questions": [
    {
      "id": "q1",
      "sentence": "2 + 2 = ___",
      "answer": "4",
      "options": ["3", "4", "5", "6"]
    }
  ]
}
```

### Guess Level (guess_001.json)
```json
{
  "guessID": "guess_001",
  "title": "Kolay Seviye",
  "difficulty": 1,
  "questions": [
    {
      "targetNumber": 15,
      "hint": "1 ile 20 arasında bir sayı"
    },
    {
      "targetNumber": 42,
      "hint": "Hayatın anlamı"
    }
  ]
}
```

## 💾 Veritabanı Tabloları

### FillBlanksLevels (Cümle Tamamlama)
```sql
CREATE TABLE FillBlanksLevels (
  levelID TEXT PRIMARY KEY,
  title TEXT,
  description TEXT,
  difficulty INTEGER,
  category TEXT,
  questions TEXT -- JSON string
);
```

### GuessLevels (Salla Bakalım)
```sql
CREATE TABLE GuessLevels (
  guessID TEXT PRIMARY KEY,
  title TEXT,
  description TEXT,
  difficulty INTEGER,
  category TEXT,
  questions TEXT -- JSON string
);
```

### MemoryGameResults (Bul Bakalım Sonuçları)
```sql
CREATE TABLE MemoryGameResults (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  moves INTEGER,
  timeTaken INTEGER,
  mistakes INTEGER,
  completedAt TEXT
);
```

### GameResults (Genel Oyun Sonuçları)
```sql
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
```

## 🚀 Kullanım

1. JSON dosyalarını `.tar.bz2` arşivine ekle
2. Firebase Storage'dan indir
3. `processLocalArchiveContent` otomatik olarak parse eder
4. İlgili tablolara kaydeder

**Yeni dosya eklemek için:**
- `levelID` veya `guessID` ekle
- Benzersiz ID kullan (örn: `lvl_003`, `guess_003`)
- Arşive dahil et, sistem otomatik algılar!

## 📱 Ekran Akışı

```
Games Tab
├── Cümle Tamamlama → Level Selection → Fill Blanks Game → Result
├── 1v1 Düello → Duel Selection → Matchmaking → Duel Game → Result Dialog
├── Salla Bakalım → Guess Level Selection → Guess Game → Guess Result
└── Bul Bakalım → Memory Game → Memory Result
```

## 🤖 1v1 Düello Sistemi

1v1 Düello sistemi ayrı JSON dosyaları kullanmaz. Bunun yerine:

- **Test Modu:** `Testler` tablosundan rastgele 5 soru çeker
- **Cümle Modu:** `FillBlanksLevels` tablosundan rastgele 5 soru çeker

### Akıllı Bot Algoritması

```dart
bool shouldBotAnswerCorrectly() {
  if (userScore > botScore) return true;    // Kullanıcı öndeyse → Bot doğru
  if (userScore < botScore) return false;   // Kullanıcı gerideyse → Bot yanlış
  return drawCount % 2 == 0;                // Berabere → Dönüşümlü
}
```

---

**Son Güncelleme:** 5 Aralık 2025  
**Versiyon:** v1.4.0
