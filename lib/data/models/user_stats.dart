/// Estatísticas agregadas do usuário (RPC get_user_stats).
/// Espelha o objeto consumido por Performance.jsx no React.
class UserStats {
  final int completedChallenges;
  final int inProgressChallenges;
  final int totalChallenges;
  final int completionRate; // %
  final int unlockedAchievements;
  final int streak;
  final int xp;
  final int level;
  final int coins;
  final int studyDaysThisWeek;
  final int studyDaysThisMonth;

  const UserStats({
    this.completedChallenges = 0,
    this.inProgressChallenges = 0,
    this.totalChallenges = 0,
    this.completionRate = 0,
    this.unlockedAchievements = 0,
    this.streak = 0,
    this.xp = 0,
    this.level = 1,
    this.coins = 0,
    this.studyDaysThisWeek = 0,
    this.studyDaysThisMonth = 0,
  });

  static int _i(dynamic v) => (v as num?)?.toInt() ?? 0;

  factory UserStats.fromMap(Map<String, dynamic> m) {
    return UserStats(
      completedChallenges: _i(m['completed_challenges']),
      inProgressChallenges: _i(m['in_progress_challenges']),
      totalChallenges: _i(m['total_challenges']),
      completionRate: _i(m['completion_rate']),
      unlockedAchievements: _i(m['unlocked_achievements']),
      streak: _i(m['streak']),
      xp: _i(m['xp']),
      level: m['level'] == null ? 1 : _i(m['level']),
      coins: _i(m['coins']),
      studyDaysThisWeek: _i(m['study_days_this_week']),
      studyDaysThisMonth: _i(m['study_days_this_month']),
    );
  }
}
