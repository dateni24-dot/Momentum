class AchievementModel {
  final int id;
  final String name;
  final String description;
  final int coins;
  final DateTime? unlockedAt;

  const AchievementModel({
    required this.id,
    required this.name,
    required this.description,
    required this.coins,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  factory AchievementModel.fromMap(
    Map<String, dynamic> map, {
    DateTime? unlockedAt,
  }) {
    return AchievementModel(
      id:          (map['id'] as num).toInt(),
      name:        map['achievement_name'] as String? ?? '',
      description: map['achievement_description'] as String? ?? '',
      coins:       (map['achievement_coins'] as num?)?.toInt() ?? 0,
      unlockedAt:  unlockedAt,
    );
  }
}
