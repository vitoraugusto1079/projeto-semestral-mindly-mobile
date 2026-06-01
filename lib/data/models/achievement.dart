class Achievement {
  final String id;
  final String title;
  final String description;
  final int rewardCoins;
  final bool unlocked;
  final int requiredChallenges;
  final int currentChallenges;
  final int progressPct; // 0–100
  final String? unlockedAt; // ISO date ou null

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardCoins,
    required this.unlocked,
    this.requiredChallenges = 1,
    this.currentChallenges = 0,
    this.progressPct = 0,
    this.unlockedAt,
  });

  factory Achievement.fromMap(Map<String, dynamic> map) {
    return Achievement(
      id: map['id'].toString(),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      rewardCoins: (map['reward_coins'] as num?)?.toInt() ?? 0,
      unlocked: map['unlocked'] as bool? ?? false,
      requiredChallenges: (map['required_challenges'] as num?)?.toInt() ?? 1,
      currentChallenges: (map['current_challenges'] as num?)?.toInt() ?? 0,
      progressPct: (map['progress_pct'] as num?)?.toInt() ?? 0,
      unlockedAt: map['unlocked_at'] as String?,
    );
  }
}
