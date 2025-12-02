import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_helper.dart';
import '../repositories/test_repository.dart';
import '../repositories/test_repository_impl.dart';
import '../repositories/flashcard_repository.dart';
import '../repositories/flashcard_repository_impl.dart';

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

final testRepositoryProvider = Provider<TestRepository>((ref) {
  final dbHelper = ref.read(databaseHelperProvider);
  return TestRepositoryImpl(dbHelper);
});

final flashcardRepositoryProvider = Provider<FlashcardRepository>((ref) {
  final dbHelper = ref.read(databaseHelperProvider);
  return FlashcardRepositoryImpl(dbHelper);
});
