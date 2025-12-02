/// Bot entity sınıfı
class Bot {
  final String name;
  final String avatar;
  final List<int> speedRange; // [min, max] ms cinsinden cevap süresi
  final String difficulty;

  const Bot({
    required this.name,
    required this.avatar,
    required this.speedRange,
    required this.difficulty,
  });

  static const List<Bot> bots = [
    Bot(
      name: 'Çılgın Profesör',
      avatar: '🧑‍🔬',
      speedRange: [2000, 4000],
      difficulty: 'Kolay',
    ),
    Bot(
      name: 'Hızlı Tavşan',
      avatar: '🐰',
      speedRange: [1000, 2500],
      difficulty: 'Orta',
    ),
    Bot(
      name: 'Bilge Baykuş',
      avatar: '🦉',
      speedRange: [800, 2000],
      difficulty: 'Zor',
    ),
  ];
}
