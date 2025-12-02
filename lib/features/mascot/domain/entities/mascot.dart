// Maskot türleri
enum PetType {
  fox,
  cat,
  robot;

  String get displayName {
    switch (this) {
      case PetType.fox:
        return 'Tilki';
      case PetType.cat:
        return 'Kedi';
      case PetType.robot:
        return 'Robot';
    }
  }
}

// Maskot varlığı
class Mascot {
  final int? id;
  final PetType petType;
  final String petName;
  final int currentXp;
  final int level;
  final int mood;
  final DateTime createdAt;

  Mascot({
    this.id,
    required this.petType,
    required this.petName,
    this.currentXp = 0,
    this.level = 1,
    this.mood = 100,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Mascot copyWith({
    int? id,
    PetType? petType,
    String? petName,
    int? currentXp,
    int? level,
    int? mood,
    DateTime? createdAt,
  }) {
    return Mascot(
      id: id ?? this.id,
      petType: petType ?? this.petType,
      petName: petName ?? this.petName,
      currentXp: currentXp ?? this.currentXp,
      level: level ?? this.level,
      mood: mood ?? this.mood,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petType': petType.name,
      'petName': petName,
      'currentXp': currentXp,
      'level': level,
      'mood': mood,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Mascot.fromMap(Map<String, dynamic> map) {
    return Mascot(
      id: map['id'] as int?,
      petType: PetType.values.firstWhere(
        (e) => e.name == map['petType'],
        orElse: () => PetType.fox,
      ),
      petName: map['petName'] as String,
      currentXp: map['currentXp'] as int? ?? 0,
      level: map['level'] as int? ?? 1,
      mood: map['mood'] as int? ?? 100,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
