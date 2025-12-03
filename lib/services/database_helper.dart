import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

abstract class IDatabaseHelper {
  Future<void> batchInsert(String table, List<Map<String, dynamic>> rows);
  Future<void> insertTest(Map<String, dynamic> row);
  Future<void> insertFlashcardSet(Map<String, dynamic> row);
  Future<void> insertFillBlanksLevel(Map<String, dynamic> row);
  Future<void> insertArenaSet(Map<String, dynamic> row);
  Future<void> clearAllData();
  Future<void> addDownloadedFile(String path);
  Future<void> insertDers(Map<String, dynamic> row);
  Future<void> insertKonu(Map<String, dynamic> row);
}

class DatabaseHelper implements IDatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'bilgi_avcisi.db');
    return await openDatabase(
      path,
      version: 7,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Dersler Tablosu
    await db.execute('''
      CREATE TABLE Dersler(
        dersID TEXT PRIMARY KEY,
        dersAdi TEXT,
        ikon TEXT,
        renk TEXT
      )
    ''');

    // Konular Tablosu
    await db.execute('''
      CREATE TABLE Konular(
        konuID TEXT PRIMARY KEY,
        dersID TEXT,
        konuAdi TEXT,
        sira INTEGER,
        FOREIGN KEY(dersID) REFERENCES Dersler(dersID)
      )
    ''');

    // Testler Tablosu
    await db.execute('''
      CREATE TABLE Testler(
        testID TEXT PRIMARY KEY,
        konuID TEXT,
        testAdi TEXT,
        zorluk INTEGER,
        cozumVideoURL TEXT,
        sorular TEXT, -- JSON String olarak saklanacak
        FOREIGN KEY(konuID) REFERENCES Konular(konuID)
      )
    ''');

    // Bilgi Kartları Tablosu
    await db.execute('''
      CREATE TABLE BilgiKartlari(
        kartSetID TEXT PRIMARY KEY,
        konuID TEXT,
        kartAdi TEXT,
        kartlar TEXT, -- JSON String olarak saklanacak
        FOREIGN KEY(konuID) REFERENCES Konular(konuID)
      )
    ''');

    // Bildirimler Tablosu
    await db.execute('''
      CREATE TABLE Notifications(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        body TEXT,
        date TEXT,
        isRead INTEGER
      )
    ''');

    // Deneme Sınavları Tablosu
    await db.execute('''
      CREATE TABLE TrialExams(
        id TEXT PRIMARY KEY,
        title TEXT,
        startDate TEXT,
        endDate TEXT,
        duration INTEGER,
        contentJson TEXT
      )
    ''');

    // Deneme Sonuçları Tablosu (Ham Cevaplar)
    await db.execute('''
      CREATE TABLE TrialResults(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        examId TEXT,
        userId TEXT,
        rawAnswers TEXT,
        score INTEGER,
        completedAt TEXT,
        FOREIGN KEY(examId) REFERENCES TrialExams(id)
      )
    ''');

    // Kullanıcı Maskotları Tablosu
    await db.execute('''
      CREATE TABLE UserPets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        petType TEXT NOT NULL,
        petName TEXT NOT NULL,
        currentXp INTEGER DEFAULT 0,
        level INTEGER DEFAULT 1,
        mood INTEGER DEFAULT 100,
        createdAt TEXT DEFAULT (datetime('now'))
      )
    ''');

    // İndirilen Dosyalar Tablosu
    await db.execute('''
      CREATE TABLE DownloadedFiles(
        path TEXT PRIMARY KEY,
        date TEXT
      )
    ''');

    // Test Sonuçları Tablosu
    await db.execute('''
      CREATE TABLE TestResults(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        testId TEXT,
        score INTEGER,
        correct INTEGER,
        wrong INTEGER,
        date TEXT
      )
    ''');

    // Fill Blanks Levels Tablosu
    await db.execute('''
      CREATE TABLE FillBlanksLevels(
        levelID TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        difficulty INTEGER,
        category TEXT,
        questions TEXT
      )
    ''');

    // Arena Sets Tablosu
    await db.execute('''
      CREATE TABLE ArenaSets(
        arenaSetID TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        difficulty INTEGER,
        category TEXT,
        questions TEXT
      )
    ''');

    // Game Results Tablosu (Tüm oyun sonuçları için)
    await db.execute('''
      CREATE TABLE GameResults(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        gameType TEXT NOT NULL,
        score INTEGER,
        correctCount INTEGER,
        wrongCount INTEGER,
        totalQuestions INTEGER,
        completedAt TEXT,
        details TEXT
      )
    ''');

    // Haftalık Sınav Sonuçları Tablosu
    await db.execute('''
      CREATE TABLE WeeklyExamResults(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        examId TEXT NOT NULL,
        odaId TEXT NOT NULL,
        odaIsmi TEXT,
        odaBaslangic TEXT,
        odaBitis TEXT,
        sonucTarihi TEXT,
        odaDurumu TEXT,
        odaKatilimciId TEXT NOT NULL,
        cevaplar TEXT,
        dogru INTEGER,
        yanlis INTEGER,
        bos INTEGER,
        puan INTEGER,
        siralama INTEGER,
        toplamKatilimci INTEGER,
        completedAt TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS Notifications(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          body TEXT,
          date TEXT,
          isRead INTEGER
        )
      ''');
    }

    if (oldVersion < 3) {
      // Deneme Sınavları Tablosu
      await db.execute('''
        CREATE TABLE IF NOT EXISTS TrialExams(
          id TEXT PRIMARY KEY,
          title TEXT,
          startDate TEXT,
          endDate TEXT,
          duration INTEGER,
          contentJson TEXT
        )
      ''');

      // Deneme Sonuçları Tablosu
      await db.execute('''
        CREATE TABLE IF NOT EXISTS TrialResults(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          examId TEXT,
          userId TEXT,
          rawAnswers TEXT,
          score INTEGER,
          completedAt TEXT,
          FOREIGN KEY(examId) REFERENCES TrialExams(id)
        )
      ''');
    }

    if (oldVersion < 4) {
      // Kullanıcı Maskotları Tablosu
      await db.execute('''
        CREATE TABLE IF NOT EXISTS UserPets(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          petType TEXT NOT NULL,
          petName TEXT NOT NULL,
          currentXp INTEGER DEFAULT 0,
          level INTEGER DEFAULT 1,
          mood INTEGER DEFAULT 100,
          createdAt TEXT DEFAULT (datetime('now'))
        )
      ''');
    }

    if (oldVersion < 5) {
      // İndirilen Dosyalar Tablosu
      await db.execute('''
        CREATE TABLE IF NOT EXISTS DownloadedFiles(
          path TEXT PRIMARY KEY,
          date TEXT
        )
      ''');

      // Test Sonuçları Tablosu
      await db.execute('''
        CREATE TABLE IF NOT EXISTS TestResults(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          testId TEXT,
          score INTEGER,
          correct INTEGER,
          wrong INTEGER,
          date TEXT
        )
      ''');

      // Fill Blanks Levels Tablosu
      await db.execute('''
        CREATE TABLE IF NOT EXISTS FillBlanksLevels(
          levelID TEXT PRIMARY KEY,
          title TEXT,
          description TEXT,
          difficulty INTEGER,
          category TEXT,
          questions TEXT
        )
      ''');

      // Arena Sets Tablosu
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ArenaSets(
          arenaSetID TEXT PRIMARY KEY,
          title TEXT,
          description TEXT,
          difficulty INTEGER,
          category TEXT,
          questions TEXT
        )
      ''');
    }

    if (oldVersion < 6) {
      // Game Results Tablosu
      await db.execute('''
        CREATE TABLE IF NOT EXISTS GameResults(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          gameType TEXT NOT NULL,
          score INTEGER,
          correctCount INTEGER,
          wrongCount INTEGER,
          totalQuestions INTEGER,
          completedAt TEXT,
          details TEXT
        )
      ''');
    }

    if (oldVersion < 7) {
      // Haftalık Sınav Sonuçları Tablosu
      await db.execute('''
        CREATE TABLE IF NOT EXISTS WeeklyExamResults(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          examId TEXT NOT NULL,
          odaId TEXT NOT NULL,
          odaIsmi TEXT,
          odaBaslangic TEXT,
          odaBitis TEXT,
          sonucTarihi TEXT,
          odaDurumu TEXT,
          odaKatilimciId TEXT NOT NULL,
          cevaplar TEXT,
          dogru INTEGER,
          yanlis INTEGER,
          bos INTEGER,
          puan INTEGER,
          siralama INTEGER,
          toplamKatilimci INTEGER,
          completedAt TEXT
        )
      ''');
    }
  }

  // Ekleme Metotları
  @override
  Future<void> insertDers(Map<String, dynamic> row) async {
    Database db = await database;
    await db.insert(
      'Dersler',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> insertKonu(Map<String, dynamic> row) async {
    Database db = await database;
    await db.insert(
      'Konular',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> insertTest(Map<String, dynamic> row) async {
    Database db = await database;
    await db.insert(
      'Testler',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertBilgiKart(Map<String, dynamic> row) async {
    Database db = await database;
    await db.insert(
      'BilgiKartlari',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Test için alias metod
  Future<int> insertFlashcard(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert(
      'BilgiKartlari',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // FlashcardSet için alias metod
  @override
  Future<void> insertFlashcardSet(Map<String, dynamic> row) async {
    await insertBilgiKart(row);
  }

  // Bildirimler için CRUD Metotları
  Future<int> insertNotification(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert(
      'Notifications',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    Database db = await database;
    return await db.query('Notifications', orderBy: 'date DESC');
  }

  Future<int> deleteNotification(int id) async {
    Database db = await database;
    return await db.delete('Notifications', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> markNotificationAsRead(int id) async {
    Database db = await database;
    await db.update(
      'Notifications',
      {'isRead': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Temizleme Metodu (Yeni sınıf indirildiğinde eskileri silmek için)
  @override
  Future<void> clearAllData() async {
    Database db = await database;
    await db.transaction((txn) async {
      await txn.delete('Dersler');
      await txn.delete('Konular');
      await txn.delete('Testler');
      await txn.delete('BilgiKartlari');
    });
  }

  // Toplu Ekleme Metodu (Batch Insert)
  @override
  Future<void> batchInsert(
    String table,
    List<Map<String, dynamic>> rows,
  ) async {
    if (rows.isEmpty) return;
    Database db = await database;
    Batch batch = db.batch();

    for (var row in rows) {
      batch.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  // İndirilen Dosyalar Metotları
  Future<List<String>> getDownloadedFiles() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('DownloadedFiles');
    return List.generate(maps.length, (i) {
      return maps[i]['path'] as String;
    });
  }

  @override
  Future<void> addDownloadedFile(String path) async {
    Database db = await database;
    await db.insert('DownloadedFiles', {
      'path': path,
      'date': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Test Sonuçları Metotları
  Future<void> saveTestResult(
    String testId,
    int score,
    int correct,
    int wrong,
  ) async {
    Database db = await database;
    await db.insert('TestResults', {
      'testId': testId,
      'score': score,
      'correct': correct,
      'wrong': wrong,
      'date': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Fill Blanks Levels  Metotları
  @override
  Future<void> insertFillBlanksLevel(Map<String, dynamic> row) async {
    Database db = await database;
    await db.insert(
      'FillBlanksLevels',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getFillBlanksLevels() async {
    Database db = await database;
    return await db.query('FillBlanksLevels', orderBy: 'difficulty ASC');
  }

  // Arena Sets Metotları
  @override
  Future<void> insertArenaSet(Map<String, dynamic> row) async {
    Database db = await database;
    await db.insert(
      'ArenaSets',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getArenaSets() async {
    Database db = await database;
    return await db.query('ArenaSets', orderBy: 'difficulty ASC');
  }

  // Game Results Metotları
  Future<void> saveGameResult({
    required String gameType,
    required int score,
    required int correctCount,
    required int wrongCount,
    required int totalQuestions,
    String? details,
  }) async {
    Database db = await database;

    // Önce yeni sonucu kaydet
    await db.insert('GameResults', {
      'gameType': gameType,
      'score': score,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'totalQuestions': totalQuestions,
      'completedAt': DateTime.now().toIso8601String(),
      'details': details,
    });

    // Sonra eski kayıtları temizle (son 50'yi koru)
    await _cleanOldGameResults(db);
  }

  Future<void> _cleanOldGameResults(Database db) async {
    // Toplam kayıt sayısını al
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM GameResults',
    );
    final count = Sqflite.firstIntValue(countResult) ?? 0;

    // Eğer 50'den fazla kayıt varsa, en eskileri sil
    if (count > 50) {
      final deleteCount = count - 50;
      await db.rawDelete(
        '''
        DELETE FROM GameResults 
        WHERE id IN (
          SELECT id FROM GameResults 
          ORDER BY completedAt ASC 
          LIMIT ?
        )
      ''',
        [deleteCount],
      );
    }
  }

  Future<List<Map<String, dynamic>>> getGameResults(String gameType) async {
    Database db = await database;
    return await db.query(
      'GameResults',
      where: 'gameType = ?',
      whereArgs: [gameType],
      orderBy: 'completedAt DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllGameResults() async {
    Database db = await database;
    return await db.query('GameResults', orderBy: 'completedAt DESC');
  }

  // ============================================================
  // Performans Optimizasyonu - SQL RANDOM() Metodları
  // ============================================================

  /// Rastgele Fill Blanks level çeker
  /// Tüm veriyi belleğe almak yerine SQL RANDOM() kullanır
  Future<Map<String, dynamic>?> getRandomFillBlanksLevel() async {
    Database db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      'SELECT * FROM FillBlanksLevels ORDER BY RANDOM() LIMIT 1',
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Rastgele Arena set çeker
  /// Tüm veriyi belleğe almak yerine SQL RANDOM() kullanır
  Future<Map<String, dynamic>?> getRandomArenaSet() async {
    Database db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      'SELECT * FROM ArenaSets ORDER BY RANDOM() LIMIT 1',
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Belirlenen zorluk seviyesinden rastgele Fill Blanks level çeker
  /// @param difficulty: 1-3 arası zorluk seviyesi
  Future<Map<String, dynamic>?> getRandomFillBlanksByDifficulty(
    int difficulty,
  ) async {
    Database db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      'SELECT * FROM FillBlanksLevels WHERE difficulty = ? ORDER BY RANDOM() LIMIT 1',
      [difficulty],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Belirlenen zorluk seviyesinden rastgele Arena set çeker
  /// @param difficulty: 1-3 arası zorluk seviyesi
  Future<Map<String, dynamic>?> getRandomArenaByDifficulty(
    int difficulty,
  ) async {
    Database db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      'SELECT * FROM ArenaSets WHERE difficulty = ? ORDER BY RANDOM() LIMIT 1',
      [difficulty],
    );
    return results.isNotEmpty ? results.first : null;
  }
}
