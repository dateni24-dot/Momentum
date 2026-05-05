/// Logro recién desbloqueado devuelto por check_and_grant_achievements
class UnlockedAchievement {
  final int id;
  final String name;
  final int coins;

  const UnlockedAchievement({
    required this.id,
    required this.name,
    required this.coins,
  });

  factory UnlockedAchievement.fromMap(Map<String, dynamic> map) {
    return UnlockedAchievement(
      id:    (map['new_id']    as num).toInt(),
      name:  map['new_name']   as String? ?? '',
      coins: (map['new_coins'] as num?)?.toInt() ?? 0,
    );
  }
}

class AchievementModel {
  final int id;
  final String name;
  final String description;
  final int coins;
  final bool isUnlocked;  // ya reclamado
  final bool isEligible;  // criterio cumplido, pendiente de reclamar

  const AchievementModel({
    required this.id,
    required this.name,
    required this.description,
    required this.coins,
    required this.isUnlocked,
    this.isEligible = false,
  });

  factory AchievementModel.fromMap(
    Map<String, dynamic> map, {
    required bool isUnlocked,
    bool isEligible = false,
  }) {
    return AchievementModel(
      id:          (map['id'] as num).toInt(),
      name:        map['achievement_name'] as String? ?? '',
      description: map['achievement_description'] as String? ?? '',
      coins:       (map['achievement_coins'] as num?)?.toInt() ?? 0,
      isUnlocked:  isUnlocked,
      isEligible:  isEligible,
    );
  }
}
