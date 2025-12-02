/// Manifest.json oluşturucu
///
/// Bu araç, Firebase Storage'da yüklü dosyalar için manifest.json dosyası oluşturur.
/// Kullanım: dart tools/generate_manifest.dart

import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Kullanım: dart tools/generate_manifest.dart <klasor_yolu>');
    print('Örnek: dart tools/generate_manifest.dart storage/3_Sinif');
    exit(1);
  }

  final folderPath = args[0];
  final folder = Directory(folderPath);

  if (!await folder.exists()) {
    print('Hata: Klasör bulunamadı: $folderPath');
    exit(1);
  }

  print('Manifest oluşturuluyor: $folderPath');

  final manifest = await generateManifest(folder);
  final manifestJson = JsonEncoder.withIndent('  ').convert(manifest);

  final manifestFile = File(path.join(folderPath, 'manifest.json'));
  await manifestFile.writeAsString(manifestJson);

  print('✓ Manifest oluşturuldu: ${manifestFile.path}');
  print('  Toplam dosya: ${manifest['files'].length}');
}

Future<Map<String, dynamic>> generateManifest(Directory folder) async {
  final files = <Map<String, dynamic>>[];
  final folderName = path.basename(folder.path);

  // Tüm dosyaları tara
  await for (var entity in folder.list(recursive: false)) {
    if (entity is File) {
      final fileName = path.basename(entity.path);
      final relativePath = '$folderName/$fileName';

      // Dosya hash'ini hesapla
      final bytes = await entity.readAsBytes();
      final hash = md5.convert(bytes).toString();

      // Dosya tipini belirle
      String fileType;
      if (fileName.endsWith('.tar.bz2')) {
        fileType = 'tar.bz2';
      } else if (fileName.endsWith('.json')) {
        fileType = 'json';
      } else {
        continue; // Diğer dosyaları atla
      }

      files.add({
        'path': relativePath,
        'type': fileType,
        'version': 'v1',
        'hash': hash,
        'addedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  return {
    'version': '1.0.0',
    'updatedAt': DateTime.now().toIso8601String(),
    'files': files,
  };
}
