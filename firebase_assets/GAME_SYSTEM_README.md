# Firebase Storage ID Tabanlı Oyun Sistemi

## 📦 Dosya Yapısı

Firebase Storage'a yüklenecek oyun JSON dosyaları artık ID tabanlı çalışıyor:

```
.tar.bz2 arşivi içinde:
├── level_001.json      (levelID: lvl_001)
├── level_002.json      (levelID: lvl_002)
├── arena_001.json      (arenaSetID: arena_001)
├── arena_002.json      (arenaSetID: arena_002)
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
| Arena Düello | ArenaSets | arenaSetID | Botlarla yarış modu |
| Salla Bakalım | GuessLevels | guessID | Telefonu salla, sayı tahmin et |
| Bul Bakalım | MemoryGameResults | - | 1-10 sıralı hafıza oyunu (statik) |

## 🔍 Otomatik Algılama Sistemi

`processLocalArchiveContent` metodu JSON dosyalarını otomatik olarak algılayıp doğru tabloya ekler:

| Dosyada Varsa | Tablo | Örnek |
|---------------|-------|-------|
| `testID` | Testler | test_mat_001.json |
| `kartSetID` | BilgiKartlari | bilgi_fen_001.json |
| `levelID` | FillBlanksLevels | level_001.json |
| `arenaSetID` | ArenaSets | arena_001.json |
| `guessID` | GuessLevels | guess_001.json |

## 📝 JSON Örnekleri

### Fill Blanks Level (level_001.json)
```json
{
  "levelID": "lvl_001",
  "title": "Temel Matematik",
  "difficulty": 1,
  "questions": [...]
}
```

### Arena Set (arena_001.json)
```json
{
  "arenaSetID": "arena_001",
  "title": "Genel Kültür - Kolay",
  "difficulty": 1,
  "questions": [...]
}
```

### Guess Level (guess_001.json) - YENİ
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

### FillBlanksLevels
- levelID (PRIMARY KEY)
- title
- description
- difficulty
- category
- questions (JSON string)

### ArenaSets
- arenaSetID (PRIMARY KEY)
- title
- description
- difficulty
- category
- questions (JSON string)

### GuessLevels (YENİ)
- guessID (PRIMARY KEY)
- title
- description
- difficulty
- category
- questions (JSON string)

### MemoryGameResults (YENİ)
- id (PRIMARY KEY AUTOINCREMENT)
- moves (INTEGER)
- timeTaken (INTEGER)
- mistakes (INTEGER)
- completedAt (TEXT)

## 🚀 Kullanım

1. JSON dosyalarını `.tar.bz2` arşivine ekle
2. Firebase Storage'dan indir
3. `processLocalArchiveContent` otomatik olarak parse eder
4. İlgili tablolara kaydeder

**Yeni dosya eklemek için:**
- `levelID`, `arenaSetID` veya `guessID` ekle
- Benzersiz ID kullan (örn: `lvl_003`, `arena_003`, `guess_003`)
- Arşive dahil et, sistem otomatik algılar!

## 📱 Ekran Akışı

```
Games Tab
├── Cümle Tamamlama → Level Selection → Fill Blanks Game → Result
├── Arena Düello → Opponent Search → Arena Game → Result
├── Salla Bakalım → Guess Level Selection → Guess Game → Guess Result
└── Bul Bakalım → Memory Game → Memory Result
```

---

**Son Güncelleme:** 4 Aralık 2025  
**Versiyon:** v1.3.0
