import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/achievement.dart';
import '../models/subject_progress.dart';
import '../models/user_stats.dart';

class ProgressService {
  final _client = Supabase.instance.client;

  /// Catálogo de conquistas + progresso do usuário (3 queries paralelas,
  /// equivalente ao progressService.listAchievements do React).
  Future<List<Achievement>> listAchievements(String userId) async {
    final results = await Future.wait([
      _client.from('achievements').select('*').order('id'),
      _client
          .from('user_achievements')
          .select('achievement_id, unlocked_at')
          .eq('user_id', userId),
      _client
          .from('user_challenges')
          .select('id')
          .eq('user_id', userId)
          .gte('progress', 100),
    ]);

    final achList = results[0] as List;
    final uaList = results[1] as List;
    final completedCount = (results[2] as List).length;

    final unlockedMap = {
      for (final u in uaList) u['achievement_id'].toString(): u,
    };

    return achList.map((a) {
      final id = a['id'].toString();
      final userRecord = unlockedMap[id];
      final unlocked = userRecord != null;
      final required = (a['required_challenges'] as num?)?.toInt() ?? 1;
      final progressPct = unlocked
          ? 100
          : (required == 0
              ? 0
              : ((completedCount / required) * 100).round().clamp(0, 99));
      return Achievement.fromMap({
        ...a,
        'unlocked': unlocked,
        'unlocked_at': userRecord?['unlocked_at'],
        'current_challenges':
            completedCount < required ? completedCount : required,
        'progress_pct': progressPct,
      });
    }).toList();
  }

  /// Verifica e desbloqueia conquistas retroativamente (RPC).
  /// Retorna o mapa { unlocked: [...], coins_earned } ou null em erro.
  Future<Map<String, dynamic>?> checkAchievements(String userId) async {
    try {
      final data = await _client
          .rpc('check_and_unlock_achievements', params: {'p_user_id': userId});
      if (data is Map<String, dynamic>) return data;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Estatísticas agregadas do usuário (RPC get_user_stats).
  Future<UserStats> getStats(String userId) async {
    final data =
        await _client.rpc('get_user_stats', params: {'p_user_id': userId});
    if (data is Map<String, dynamic>) return UserStats.fromMap(data);
    return const UserStats();
  }

  Future<List<SubjectProgress>> listSubjectPerformance(String userId) async {
    final data = await _client
        .from('subject_performance')
        .select()
        .eq('user_id', userId)
        .order('percentage', ascending: false);
    return (data as List).map((e) => SubjectProgress.fromMap(e)).toList();
  }

  Future<List<int>> listCompletedSteps(String userId) async {
    final data = await _client
        .from('learning_progress')
        .select('step_id')
        .eq('user_id', userId);
    return (data as List).map((e) => e['step_id'] as int).toList();
  }

  Future<void> completeStep(String userId, int stepId,
      [int xpAmount = 0]) async {
    await _client.from('learning_progress').upsert({
      'user_id': userId,
      'step_id': stepId,
      'completed_at': DateTime.now().toIso8601String(),
    });

    if (xpAmount > 0) {
      try {
        // Incremento atômico de XP via RPC.
        await _client.rpc('add_learning_xp',
            params: {'p_user_id': userId, 'p_xp': xpAmount});
      } catch (_) {
        // Fallback: recalcula XP/nível no cliente.
        final profile = await _client
            .from('profiles')
            .select('xp')
            .eq('id', userId)
            .single();
        final newXp = ((profile['xp'] as num?)?.toInt() ?? 0) + xpAmount;
        final newLevel = (newXp ~/ 100) + 1;
        await _client.from('profiles').update(
            {'xp': newXp, 'level': newLevel < 1 ? 1 : newLevel}).eq('id', userId);
      }
    }
  }
}
