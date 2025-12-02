# Firebase Storage ID Tabanlı Oyun Sistemi

## 📦 Dosya Yapısı

Firebase Storage'a yüklenecek oyun JSON dosyaları artık ID tabanlı çalışıyor:

```
.tar.bz2 arşivi içinde:
├── level_001.json      (levelID: lvl_001)
├── level_002.json      (levelID: lvl_002)
├── arena_001.json      (arenaSetID: arena_001)
├── arena_002.json      (arenaSetID: arena_002)
├── derslistesi.json
├── konulistesi.json
└── [diğer içerikler...]
```

## 🔍 Otomatik Algılama Sistemi

`processLocalArchiveContent` metodu JSON dosyalarını otomatik olarak algılayıp doğru tabloya ekler:

| Dosyada Varsa | Tablo | Örnek |
|---------------|-------|-------|
| `testID` | Testler | test_mat_001.json |
| `kartSetID` | BilgiKartlari | bilgi_fen_001.json |
| `levelID` | FillBlanksLevels | level_001.json |
| `arenaSetID` | ArenaSets | arena_001.json |

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

## 🚀 Kullanım

1. JSON dosyalarını `.tar.bz2` arşivine ekle
2. Firebase Storage'dan indir
3. `processLocalArchiveContent` otomatik olarak parse eder
4. İlgili tablolara kaydeder

**Yeni dosya eklemek için:**
- `levelID` veya `arenaSetID` ekle
- Benzersiz ID kullan (örn: `lvl_003`, `arena_003`)
- Arşive dahil et, sistem otomatik algılar!
