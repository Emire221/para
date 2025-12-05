import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:archive/archive.dart';
import '../models/models.dart';
import 'database_helper.dart';
import '../features/sync/domain/models/manifest_model.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage;
  final IDatabaseHelper _dbHelper;

  FirebaseStorageService({FirebaseStorage? storage, IDatabaseHelper? dbHelper})
    : _storage = storage ?? FirebaseStorage.instance,
      _dbHelper = dbHelper ?? DatabaseHelper();

  // TÃ¼rkÃ§e karakterleri dÃ¼zgÃ¼n ÅŸekilde normalize et
  String _normalizeCityName(String cityName) {
    return cityName
        .toLowerCase()
        .replaceAll('Ä±', 'i')
        .replaceAll('ÄŸ', 'g')
        .replaceAll('Ã¼', 'u')
        .replaceAll('ÅŸ', 's')
        .replaceAll('Ã¶', 'o')
        .replaceAll('Ã§', 'c')
        .replaceAll('Ä°', 'i')
        .replaceAll('Ä', 'g')
        .replaceAll('Ãœ', 'u')
        .replaceAll('Å', 's')
        .replaceAll('Ã–', 'o')
        .replaceAll('Ã‡', 'c');
  }

  // Okul verilerini indir (okullar/[IL].json)
  Future<List<School>> downloadSchoolData(String cityName) async {
    try {
      final normalizedName = _normalizeCityName(cityName);
      final ref = _storage.ref().child('okullar/$normalizedName.json');
      final data = await ref.getData();
      if (data == null) return [];

      final jsonString = utf8.decode(data);
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((e) => School.fromJson(e)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('Okul verisi indirme hatasÄ±: $e');
      return [];
    }
  }

  // SÄ±nÄ±f iÃ§eriÄŸini indir ve veritabanÄ±na kaydet
  Future<void> downloadClassContent(
    String className,
    Function(String) onProgress,
  ) async {
    try {
      // 1. Temel dosyalarÄ± indir
      onProgress('Ders listesi indiriliyor...');
      final dersListesiStr = await _downloadJsonString(
        className,
        'derslistesi.json',
      );
      final konuListesiStr = await _downloadJsonString(
        className,
        'konulistesi.json',
      );

      if (dersListesiStr == null || konuListesiStr == null) {
        throw Exception('Temel dosyalar bulunamadÄ±');
      }

      // 2. VeritabanÄ±nÄ± temizle
      await _dbHelper.clearAllData();

      // 3. JSON'larÄ± arka planda parse et ve hazÄ±rla
      onProgress('Veriler iÅŸleniyor...');

      // Dersler
      final derslerData = await compute(_parseDersler, dersListesiStr);
      await _dbHelper.batchInsert('Dersler', derslerData);

      // Konular
      final konularData = await compute(_parseKonular, konuListesiStr);
      await _dbHelper.batchInsert('Konular', konularData);

      // 4. Ders klasÃ¶rlerini tara ve iÃ§erikleri indir
      final dersler = derslerData.map((d) => Lesson.fromJson(d)).toList();

      for (var ders in dersler) {
        onProgress('${ders.dersAdi} iÃ§eriÄŸi indiriliyor...');
        String folderName = _getFolderNameForLesson(ders.dersAdi);

        // Testleri indir ve kaydet
        await _processFolderContent(
          '$className/$folderName/testler',
          'Testler',
          _parseTest,
        );

        // Bilgi kartlarÄ±nÄ± indir ve kaydet
        await _processFolderContent(
          '$className/$folderName/bilgi',
          'BilgiKartlari',
          _parseBilgiKart,
        );
      }

      onProgress('TamamlandÄ±');
    } catch (e) {
      if (kDebugMode) debugPrint('Ä°Ã§erik indirme hatasÄ±: $e');
      rethrow;
    }
  }

  Future<String?> _downloadJsonString(String className, String fileName) async {
    try {
      // 1. GÃ¼venli dosya ismi oluÅŸtur (Ã–rn: "3. SÄ±nÄ±f" -> "3_Sinif")
      final safeClassName = className.replaceAll('.', '').replaceAll(' ', '_');
      final localFileName = '${safeClassName}_$fileName';

      // 2. Yerel dizini al
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$localFileName');

      // 3. Dosya var mÄ± kontrol et
      if (await file.exists()) {
        if (kDebugMode) debugPrint('Yerel hafÄ±zadan okunuyor: $localFileName');
        return await file.readAsString();
      }

      // 4. Yoksa Firebase'den indir
      final fullPath = '$className/$fileName';
      if (kDebugMode) debugPrint('Firebase\'den indiriliyor: $fullPath');
      final ref = _storage.ref().child(fullPath);
      final data = await ref.getData();

      if (data == null) return null;

      final jsonString = utf8.decode(data);

      // 5. Yerel hafÄ±zaya kaydet
      await file.writeAsString(jsonString);
      if (kDebugMode) debugPrint('Yerel hafÄ±zaya kaydedildi: $localFileName');

      return jsonString;
    } catch (e) {
      if (kDebugMode) debugPrint('$fileName indirme hatasÄ±: $e');
      return null;
    }
  }

  Future<void> _processFolderContent(
    String path,
    String tableName,
    Map<String, dynamic> Function(String) parser,
  ) async {
    try {
      final result = await _storage.ref().child(path).listAll();
      List<Future<String?>> downloadTasks = [];

      for (var item in result.items) {
        if (item.name.endsWith('.json')) {
          downloadTasks.add(
            item.getData().then((data) {
              return data != null ? utf8.decode(data) : null;
            }),
          );
        }
      }

      final jsonStrings = await Future.wait(downloadTasks);
      final validStrings = jsonStrings.whereType<String>().toList();

      if (validStrings.isNotEmpty) {
        // Toplu parse ve insert
        final dataList = await compute(_parseList, {
          'strings': validStrings,
          'parser': parser,
        });
        await _dbHelper.batchInsert(tableName, dataList);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('$path iÃ§eriÄŸi indirme hatasÄ±: $e');
    }
  }

  String _getFolderNameForLesson(String lessonName) {
    if (lessonName.contains('Fen')) return 'Fen';
    if (lessonName.contains('Matematik')) return 'Matematik';
    if (lessonName.contains('TÃ¼rkÃ§e')) return 'TÃ¼rkce';
    if (lessonName.contains('Ä°nkÄ±lap')) {
      return 'T.C. Ä°nkÄ±lap Tarihi ve AtatÃ¼rkÃ§Ã¼lÃ¼k';
    }
    if (lessonName.contains('Ä°ngilizce')) return 'Ä°ngilizce';
    if (lessonName.contains('Sosyal')) return 'Sosyal';
    if (lessonName.contains('Din')) return 'Din';
    return lessonName.split(' ')[0];
  }

  // ========== YENÄ° SYNC 2.0 METODLARI ==========

  /// Manifest dosyasÄ±nÄ± indir ve parse et
  Future<Manifest> downloadManifest(String className) async {
    try {
      final ref = _storage.ref().child('$className/manifest.json');
      final data = await ref.getData();
      if (data == null) {
        throw Exception('Manifest dosyasÄ± bulunamadÄ±');
      }

      final jsonString = utf8.decode(data);
      final jsonMap = json.decode(jsonString);
      return Manifest.fromJson(jsonMap as Map<String, dynamic>);
    } catch (e) {
      if (kDebugMode) debugPrint('Manifest indirme hatasÄ±: $e');
      rethrow;
    }
  }

  /// tar.bz2 arÅŸiv dosyasÄ±nÄ± indir ve aÃ§
  Future<void> downloadAndExtractArchive(
    String archivePath,
    Function(String) onProgress,
  ) async {
    try {
      onProgress('ArÅŸiv indiriliyor: $archivePath');

      // tar.bz2 dosyasÄ±nÄ± indir
      final ref = _storage.ref().child(archivePath);
      final data = await ref.getData();
      if (data == null) {
        throw Exception('ArÅŸiv dosyasÄ± bulunamadÄ±: $archivePath');
      }

      onProgress('ArÅŸiv aÃ§Ä±lÄ±yor...');

      // BZip2 ile sÄ±kÄ±ÅŸtÄ±rÄ±lmÄ±ÅŸ tar arÅŸivini aÃ§
      // Ã–nce BZip2 decode et, sonra tar decode et
      final decompressed = BZip2Decoder().decodeBytes(data);
      final archive = TarDecoder().decodeBytes(decompressed);

      final directory = await getApplicationDocumentsDirectory();
      for (final file in archive.files) {
        final filename = file.name;
        final outPath = '${directory.path}/$filename';
        if (file.isFile) {
          final outFile = File(outPath);
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(outPath).create(recursive: true);
        }
      }
      if (kDebugMode) {
        debugPrint('ArÅŸiv aÃ§ma iÅŸlemi: $archivePath (${data.length} bytes)');
      }
      onProgress('ArÅŸiv iÅŸlendi: $archivePath');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ArÅŸiv indirme/aÃ§ma hatasÄ± ($archivePath): $e');
      }
      rethrow;
    }
  }

  /// ArÅŸivden Ã§Ä±kan dosyalarÄ± tara ve veritabanÄ±na kaydet
  Future<void> processLocalArchiveContent(
    String rootPath,
    Function(String) onProgress,
  ) async {
    try {
      final dir = Directory(rootPath);
      if (!await dir.exists()) {
        throw Exception('KlasÃ¶r bulunamadÄ±: $rootPath');
      }

      // 1. Ders Listesi
      final dersListesiFile = File('${dir.path}/derslistesi.json');
      if (await dersListesiFile.exists()) {
        onProgress('Ders listesi iÅŸleniyor...');
        final jsonString = await dersListesiFile.readAsString();
        final derslerData = await compute(_parseDersler, jsonString);
        await _dbHelper.batchInsert('Dersler', derslerData);
      }

      // 2. Konu Listesi
      final konuListesiFile = File('${dir.path}/konulistesi.json');
      if (await konuListesiFile.exists()) {
        onProgress('Konu listesi iÅŸleniyor...');
        final jsonString = await konuListesiFile.readAsString();
        final konularData = await compute(_parseKonular, jsonString);
        await _dbHelper.batchInsert('Konular', konularData);
      }

      // 4. KÃ¶k dizindeki tÃ¼m JSON dosyalarÄ±nÄ± tara (testler ve bilgi kartlarÄ±)
      onProgress('Test ve bilgi kartlarÄ± taranÄ±yor...');
      final allFiles = dir.listSync();

      // Temel dosyalarÄ± filtrele
      final excludedFiles = {
        'derslistesi.json',
        'konulistesi.json',
        'konuvideo.json',
        'manifest.json',
      };

      int processedTests = 0;
      int processedFlashcards = 0;
      int processedLevels = 0;
      int processedWeeklyExams = 0;
      int processedGuessLevels = 0;
      int skippedFiles = 0;

      for (var item in allFiles) {
        if (item is File && item.path.endsWith('.json')) {
          final fileName = item.path.split(Platform.pathSeparator).last;

          // Temel dosyalarÄ± atla
          if (excludedFiles.contains(fileName)) {
            continue;
          }

          try {
            final jsonString = await item.readAsString();
            final jsonData = json.decode(jsonString);

            // Test dosyasÄ± mÄ± kontrol et (testID alanÄ± var mÄ±?)
            if (jsonData is Map<String, dynamic> &&
                jsonData.containsKey('testID')) {
              final testData = _parseTest(jsonString);
              await _dbHelper.insertTest(testData);
              processedTests++;
              if (kDebugMode) debugPrint('Test iÅŸlendi: $fileName');
            }
            // Bilgi kartÄ± dosyasÄ± mÄ± kontrol et (kartSetID alanÄ± var mÄ±?)
            else if (jsonData is Map<String, dynamic> &&
                jsonData.containsKey('kartSetID')) {
              final bilgiKartData = _parseBilgiKart(jsonString);
              await _dbHelper.insertFlashcardSet(bilgiKartData);
              processedFlashcards++;
              if (kDebugMode) debugPrint('Bilgi kartÄ± iÅŸlendi: $fileName');
            }
            // Fill Blanks Level dosyasÄ± mÄ± kontrol et (levelID alanÄ± var mÄ±?)
            else if (jsonData is Map<String, dynamic> &&
                jsonData.containsKey('levelID')) {
              // questions field'Ä±nÄ± JSON string olarak kaydet
              final levelData = Map<String, dynamic>.from(jsonData);
              if (levelData.containsKey('questions')) {
                levelData['questions'] = json.encode(levelData['questions']);
              }
              await _dbHelper.insertFillBlanksLevel(levelData);
              processedLevels++;
              if (kDebugMode) {
                debugPrint('Fill Blanks Level iÅŸlendi: $fileName');
              }
            }
            // Haftalık Sınav dosyası mı kontrol et (weeklyExamId alanı var mı?)
            else if (jsonData is Map<String, dynamic> &&
                jsonData.containsKey('weeklyExamId')) {
              // questions field'Ä±nÄ± JSON string olarak kaydet
              final examData = Map<String, dynamic>.from(jsonData);
              if (examData.containsKey('questions')) {
                examData['questions'] = json.encode(examData['questions']);
              }

              // Ã–nce eski sÄ±nav verilerini sil, sonra yenisini ekle
              final newExamId = examData['weeklyExamId'] as String;
              await _dbHelper.clearOldWeeklyExamData(newExamId);
              await _dbHelper.insertWeeklyExam(examData);
              processedWeeklyExams++;
              debugPrint(
                'HaftalÄ±k SÄ±nav iÅŸlendi (eski veriler silindi): $fileName',
              );
            }
            // Salla BakalÄ±m (Guess) dosyasÄ± mÄ± kontrol et (guessID veya sallaID alanÄ± var mÄ±?)
            else if (jsonData is Map<String, dynamic> &&
                (jsonData.containsKey('guessID') ||
                    jsonData.containsKey('sallaID'))) {
              // Sadece DB'de olan kolonlarÄ± iÃ§eren yeni map oluÅŸtur
              final guessData = <String, dynamic>{
                'levelID': jsonData['guessID'] ?? jsonData['sallaID'],
                'title': jsonData['title'],
                'description': jsonData['description'],
                'difficulty': jsonData['difficulty'],
                'questions': jsonData.containsKey('questions')
                    ? json.encode(jsonData['questions'])
                    : '[]',
              };
              await _dbHelper.insertGuessLevel(guessData);
              processedGuessLevels++;
              if (kDebugMode) {
                debugPrint('Salla BakalÄ±m Level iÅŸlendi: $fileName');
              }
            }
            // Ne test ne bilgi kartÄ± ne de oyun dosyasÄ± deÄŸilse
            else {
              skippedFiles++;
              if (kDebugMode) {
                debugPrint('Bilinmeyen dosya formatÄ± atlandÄ±: $fileName');
              }
            }
          } catch (e) {
            skippedFiles++;
            if (kDebugMode) debugPrint('Dosya iÅŸleme hatasÄ± ($fileName): $e');
          }
        }
      }

      debugPrint(
        'İşlem özeti: $processedTests test, $processedFlashcards bilgi kartı, '
        '$processedLevels level, $processedWeeklyExams haftalık sınav, '
        '$processedGuessLevels salla bakalım, $skippedFiles atlanan dosya',
      );
      onProgress(
        'İçerik veritabanına kaydedildi ($processedTests test, $processedFlashcards bilgi kartı, '
        '$processedLevels level, $processedWeeklyExams haftalık sınav, '
        '$processedGuessLevels salla bakalım)',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Yerel iÃ§erik iÅŸleme hatasÄ±: $e');
      rethrow;
    }
  }

  /// JSON dosyasÄ±nÄ± indir ve DB'ye kaydet
  Future<void> downloadAndProcessJson(
    String jsonPath,
    Function(String) onProgress,
  ) async {
    try {
      onProgress('JSON indiriliyor: $jsonPath');

      final ref = _storage.ref().child(jsonPath);
      final data = await ref.getData();
      if (data == null) {
        throw Exception('JSON dosyasÄ± bulunamadÄ±: $jsonPath');
      }

      final jsonString = utf8.decode(data);
      onProgress('JSON iÅŸleniyor: $jsonPath');

      // Dosya tipine gÃ¶re parse et ve DB'ye kaydet
      if (jsonPath.contains('derslistesi')) {
        final derslerData = await compute(_parseDersler, jsonString);
        await _dbHelper.batchInsert('Dersler', derslerData);
      } else if (jsonPath.contains('konulistesi')) {
        final konularData = await compute(_parseKonular, jsonString);
        await _dbHelper.batchInsert('Konular', konularData);
      } else if (jsonPath.contains('testler')) {
        final testData = _parseTest(jsonString);
        await _dbHelper.insertTest(testData);
      } else if (jsonPath.contains('bilgi')) {
        final bilgiKartData = _parseBilgiKart(jsonString);
        await _dbHelper.insertFlashcardSet(bilgiKartData);
      }

      onProgress('JSON kaydedildi: $jsonPath');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('JSON indirme/iÅŸleme hatasÄ± ($jsonPath): $e');
      }
      rethrow;
    }
  }

  /// Oyun iÃ§eriÄŸi JSON dosyalarÄ±nÄ± indir (cache destekli)
  /// Path Ã¶rnekleri: 'games/fill_blanks/levels.json', 'games/arena/questions.json'
  Future<String?> downloadGameContent(String path) async {
    try {
      // 1. GÃ¼venli dosya ismi oluÅŸtur
      final safeFileName = path.replaceAll('/', '_');

      // 2. Yerel dizini al
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$safeFileName');

      // 3. Dosya var mÄ± kontrol et (cache)
      if (await file.exists()) {
        if (kDebugMode) {
          debugPrint('Oyun iÃ§eriÄŸi cache\'ten okunuyor: $safeFileName');
        }
        return await file.readAsString();
      }

      // 4. Yoksa Firebase'den indir
      if (kDebugMode) {
        debugPrint('Firebase\'den oyun iÃ§eriÄŸi indiriliyor: $path');
      }
      final ref = _storage.ref().child(path);
      final data = await ref.getData();

      if (data == null) {
        throw Exception('Oyun iÃ§eriÄŸi bulunamadÄ±: $path');
      }

      final jsonString = utf8.decode(data);

      // 5. Yerel hafÄ±zaya kaydet (cache)
      await file.writeAsString(jsonString);
      if (kDebugMode) {
        debugPrint('Oyun iÃ§eriÄŸi cache\'e kaydedildi: $safeFileName');
      }

      return jsonString;
    } catch (e) {
      if (kDebugMode) debugPrint('Oyun iÃ§eriÄŸi indirme hatasÄ± ($path): $e');
      return null;
    }
  }

  /// Cache'deki oyun iÃ§eriÄŸini temizle
  Future<void> clearGameContentCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final dir = Directory(directory.path);
      await for (var entity in dir.list()) {
        if (entity is File && entity.path.contains('games_')) {
          await entity.delete();
          if (kDebugMode) debugPrint('Cache silindi: ${entity.path}');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Cache temizleme hatasÄ±: $e');
    }
  }
}

// Top-level functions for compute
List<Map<String, dynamic>> _parseDersler(String jsonString) {
  final jsonMap = json.decode(jsonString);
  return (jsonMap['dersler'] as List)
      .map((e) => Lesson.fromJson(e).toMap())
      .toList();
}

List<Map<String, dynamic>> _parseKonular(String jsonString) {
  final jsonMap = json.decode(jsonString);
  return (jsonMap['konular'] as List)
      .map((e) => Topic.fromJson(e).toMap())
      .toList();
}

Map<String, dynamic> _parseTest(String jsonString) {
  return Test.fromJson(json.decode(jsonString)).toMap();
}

Map<String, dynamic> _parseBilgiKart(String jsonString) {
  return FlashcardSet.fromJson(json.decode(jsonString)).toMap();
}

List<Map<String, dynamic>> _parseList(Map<String, dynamic> args) {
  final strings = args['strings'] as List<String>;
  final parser = args['parser'] as Map<String, dynamic> Function(String);
  return strings.map((s) => parser(s)).toList();
}
