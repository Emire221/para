import '../../features/mascot/domain/entities/mascot.dart';

/// Maskot oyunlaştırma mantığı
class MascotLogic {
  // Seviye XP eşikleri
  static const Map<int, int> xpThresholds = {
    1: 0,
    2: 500,
    3: 1500,
    4: 3000,
    5: 5000,
    6: 7500,
    7: 10500,
    8: 14000,
    9: 18000,
    10: 22500,
  };

  /// XP'ye göre seviye hesapla
  static int calculateLevel(int xp) {
    int level = 1;
    for (var entry in xpThresholds.entries) {
      if (xp >= entry.value) {
        level = entry.key;
      } else {
        break;
      }
    }
    return level;
  }

  /// Bir sonraki seviyeye kalan XP
  static int xpToNextLevel(int currentXp, int currentLevel) {
    if (currentLevel >= 10) return 0;

    final nextLevelXp = xpThresholds[currentLevel + 1] ?? 0;
    return nextLevelXp - currentXp;
  }

  /// Mevcut seviyenin başlangıç XP'si
  static int currentLevelStartXp(int level) {
    return xpThresholds[level] ?? 0;
  }

  /// Seviye ilerleme yüzdesi (0-1 arası)
  static double getLevelProgress(int currentXp, int currentLevel) {
    if (currentLevel >= 10) return 1.0;

    final currentLevelStart = currentLevelStartXp(currentLevel);
    final nextLevelStart = xpThresholds[currentLevel + 1] ?? currentLevelStart;
    final levelRange = nextLevelStart - currentLevelStart;

    if (levelRange == 0) return 1.0;

    final progress = (currentXp - currentLevelStart) / levelRange;
    return progress.clamp(0.0, 1.0);
  }

  /// XP ekleyip seviye kontrolü yap
  static MascotLevelResult addXp(Mascot mascot, int xpAmount) {
    final newXp = mascot.currentXp + xpAmount;
    final oldLevel = mascot.level;
    final newLevel = calculateLevel(newXp);
    final leveledUp = newLevel > oldLevel;

    final updatedMascot = mascot.copyWith(currentXp: newXp, level: newLevel);

    return MascotLevelResult(
      mascot: updatedMascot,
      leveledUp: leveledUp,
      oldLevel: oldLevel,
      newLevel: newLevel,
    );
  }

  /// Seviyeye göre asset yolu
  static String getMascotAssetPath(String petType, int level) {
    String stage;

    if (level <= 3) {
      stage = 'baby';
    } else if (level <= 6) {
      stage = 'teen';
    } else {
      stage = 'wise';
    }

    return 'assets/mascot/${petType}_$stage.png';
  }

  /// Yumurta asset yolu
  static String getEggAssetPath(String petType) {
    return 'assets/mascot/egg_$petType.png';
  }
}

/// XP ekleme sonucu
class MascotLevelResult {
  final Mascot mascot;
  final bool leveledUp;
  final int oldLevel;
  final int newLevel;

  const MascotLevelResult({
    required this.mascot,
    required this.leveledUp,
    required this.oldLevel,
    required this.newLevel,
  });
}
