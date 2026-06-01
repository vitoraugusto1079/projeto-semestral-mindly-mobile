import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/models/achievement.dart';
import '../../data/models/user_stats.dart';
import '../../data/services/progress_service.dart';
import '../../providers/auth_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _service = ProgressService();
  UserStats _stats = const UserStats();
  List<Achievement> _achievements = [];
  bool _statsLoading = true;
  bool _achLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = context.read<AuthProvider>().session?.user.id;
    if (uid == null) {
      setState(() {
        _statsLoading = false;
        _achLoading = false;
      });
      return;
    }
    try {
      final stats = await _service.getStats(uid);
      if (mounted) setState(() => _stats = stats);
    } catch (_) {}
    if (mounted) setState(() => _statsLoading = false);

    try {
      final ach = await _service.listAchievements(uid);
      if (mounted) setState(() => _achievements = ach);
    } catch (_) {}
    if (mounted) setState(() => _achLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final mobile = isMobile(context);

    final unlocked = _achievements.where((a) => a.unlocked).toList();
    final locked = _achievements.where((a) => !a.unlocked).toList();

    final xpInLevel = (user?.xp ?? 0) % 200;
    final xpPct = (xpInLevel / 200).clamp(0.0, 1.0);

    return Container(
      color: AppColors.bg,
      padding: EdgeInsets.symmetric(horizontal: mobile ? 20 : 40, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== HERO CARD =====
              _heroCard(context, user, xpInLevel, xpPct, mobile),
              const SizedBox(height: 24),

              // ===== STATS GRID =====
              _statsGrid(user),
              const SizedBox(height: 40),

              // ===== CONQUISTAS =====
              Row(
                children: [
                  Container(
                      width: 5,
                      height: 24,
                      decoration: BoxDecoration(
                          color: AppColors.orange,
                          borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 12),
                  Text('Conquistas',
                      style: GoogleFonts.capriola(
                          fontSize: 20, color: AppColors.navy)),
                  const Spacer(),
                  if (!_achLoading && _achievements.isNotEmpty)
                    Text('${unlocked.length} de ${_achievements.length} desbloqueadas',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.graySoft)),
                ],
              ),
              const SizedBox(height: 16),
              _achievementsSection(unlocked, locked),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Hero card ----
  Widget _heroCard(BuildContext context, user, int xpInLevel, double xpPct,
      bool mobile) {
    final displayName = user?.name ?? 'Usuário Mindly';
    final isAdmin = user?.role == 'admin';
    final roleLabel = isAdmin ? 'Administrador' : 'Estudante';

    final avatar = ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: (user?.photo != null && (user!.photo as String).isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: user.photo!,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => _avatarFallback(),
            )
          : _avatarFallback(),
    );

    final info = Column(
      crossAxisAlignment:
          mobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          children: [
            Text(displayName,
                style: GoogleFonts.capriola(
                    fontSize: 22, color: AppColors.navy)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: (isAdmin ? AppColors.orange : AppColors.blue)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(roleLabel,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isAdmin ? AppColors.orangeDark : AppColors.blue)),
            ),
          ],
        ),
        if (user?.username != null && (user!.username as String).isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('@${user.username}',
                style: const TextStyle(fontSize: 13, color: AppColors.graySoft)),
          ),
        if (user?.bio != null && (user!.bio as String).isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(user.bio!,
                textAlign: mobile ? TextAlign.center : TextAlign.start,
                style: const TextStyle(fontSize: 13, color: AppColors.navy)),
          ),
        if (user?.email != null && (user!.email as String).isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(user.email,
                style: const TextStyle(fontSize: 13, color: AppColors.graySoft)),
          ),
        const SizedBox(height: 14),
        // Barra de XP
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nível ${user?.level ?? 1}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy)),
                Text('$xpInLevel / 200 XP para o próximo nível',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.graySoft)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: xpPct,
                minHeight: 8,
                backgroundColor: const Color(0xFFE8E8E8),
                valueColor: const AlwaysStoppedAnimation(AppColors.blue),
              ),
            ),
          ],
        ),
      ],
    );

    final actions = [
      ElevatedButton.icon(
        onPressed: () => context.go('/editar-perfil'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue),
        icon: const Icon(Icons.edit, size: 14),
        label: const Text('Editar perfil'),
      ),
      OutlinedButton.icon(
        onPressed: () async {
          final auth = context.read<AuthProvider>();
          await auth.logout();
          if (context.mounted) context.go('/login');
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: AppColors.danger),
        ),
        icon: const Icon(Icons.logout, size: 14),
        label: const Text('Sair'),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10),
        ],
      ),
      child: mobile
          ? Column(
              children: [
                avatar,
                const SizedBox(height: 16),
                info,
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  actions[0],
                  const SizedBox(width: 12),
                  actions[1],
                ]),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                avatar,
                const SizedBox(width: 24),
                Expanded(child: info),
                const SizedBox(width: 24),
                Column(children: [
                  actions[0],
                  const SizedBox(height: 10),
                  actions[1],
                ]),
              ],
            ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      width: 90,
      height: 90,
      color: AppColors.blue.withValues(alpha: 0.12),
      child: const Icon(Icons.person, size: 44, color: AppColors.blue),
    );
  }

  // ---- Stats grid ----
  Widget _statsGrid(user) {
    final cards = <Widget>[
      _StatCard(
          icon: Icons.bolt,
          value: '${user?.xp ?? 0}',
          label: 'XP Total',
          color: const Color(0xFF9B59B6)),
      _StatCard(
          icon: Icons.star,
          value: 'Nível ${user?.level ?? 1}',
          label: 'Nível Atual',
          color: const Color(0xFFF59A3C)),
      _StatCard(
          icon: Icons.check_circle,
          value: '${_stats.completedChallenges}',
          label: 'Desafios Concluídos',
          color: const Color(0xFF27AE60),
          loading: _statsLoading),
      _StatCard(
          icon: Icons.local_fire_department,
          value: '${user?.streak ?? 0}',
          label: 'Dias Consecutivos',
          color: const Color(0xFFE74C3C)),
      _StatCard(
          icon: Icons.emoji_events,
          value: '${_stats.unlockedAchievements}',
          label: 'Conquistas',
          color: const Color(0xFFF59A3C),
          loading: _statsLoading),
      _StatCard(
          icon: Icons.trending_up,
          value: '${_stats.completionRate}%',
          label: 'Taxa de Conclusão',
          color: const Color(0xFF3F7FE3),
          loading: _statsLoading),
      _StatCard(
          icon: Icons.track_changes,
          value: '${_stats.inProgressChallenges}',
          label: 'Em Andamento',
          color: const Color(0xFF1ABC9C),
          loading: _statsLoading),
      _StatCard(
          icon: Icons.monetization_on,
          value: '${user?.coins ?? 0}',
          label: 'Moedas',
          color: const Color(0xFFE67E22)),
    ];

    return LayoutBuilder(builder: (_, c) {
      final cols = c.maxWidth < 560 ? 2 : (c.maxWidth < 900 ? 3 : 4);
      const gap = 16.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: cards.map((card) => SizedBox(width: w, child: card)).toList(),
      );
    });
  }

  // ---- Achievements ----
  Widget _achievementsSection(
      List<Achievement> unlocked, List<Achievement> locked) {
    if (_achLoading) {
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: List.generate(
            4,
            (_) => SizedBox(
                  width: 240,
                  height: 90,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9EEF5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                )),
      );
    }
    if (_achievements.isEmpty) {
      return const _Empty(text: 'Nenhuma conquista disponível no momento.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (unlocked.isNotEmpty) ...[
          const _SubLabel('Desbloqueadas'),
          _achGrid(unlocked),
        ] else
          const _Empty(
              text:
                  'Nenhuma conquista desbloqueada ainda. Continue estudando!'),
        if (locked.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _SubLabel('Em progresso'),
          _achGrid(locked),
        ],
      ],
    );
  }

  Widget _achGrid(List<Achievement> list) {
    return LayoutBuilder(builder: (_, c) {
      final cols = c.maxWidth < 560 ? 1 : (c.maxWidth < 900 ? 2 : 3);
      const gap = 16.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: list
            .map((a) => SizedBox(width: w, child: _ProfileAchCard(achievement: a)))
            .toList(),
      );
    });
  }
}

class _SubLabel extends StatelessWidget {
  final String text;
  const _SubLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 4),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.graySoft)),
      );
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty({required this.text});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Icon(Icons.emoji_events, size: 34, color: Color(0xFFDDDDDD)),
            const SizedBox(height: 8),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.graySoft, fontSize: 14)),
          ],
        ),
      );
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool loading;
  const _StatCard(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color,
      this.loading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.black.withValues(alpha: 0.04), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                loading
                    ? Container(
                        width: 44,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9EEF5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      )
                    : Text(value,
                        style: GoogleFonts.capriola(
                            fontSize: 18, color: AppColors.navy)),
                const SizedBox(height: 2),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.graySoft, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Card horizontal de conquista usado no perfil.
class _ProfileAchCard extends StatelessWidget {
  final Achievement achievement;
  const _ProfileAchCard({required this.achievement});

  String? get _date {
    final raw = achievement.unlockedAt;
    if (raw == null) return null;
    final d = DateTime.tryParse(raw);
    if (d == null) return null;
    const months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    final unlocked = a.unlocked;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: unlocked
                ? AppColors.orange.withValues(alpha: 0.4)
                : const Color(0xFFE0E0E0)),
        boxShadow: unlocked
            ? [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: unlocked
                  ? AppColors.orange.withValues(alpha: 0.12)
                  : const Color(0xFFEDEDED),
              shape: BoxShape.circle,
            ),
            child: Icon(unlocked ? Icons.emoji_events : Icons.lock,
                size: 18,
                color: unlocked ? AppColors.orange : const Color(0xFFBBBBBB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: unlocked
                            ? AppColors.navy
                            : const Color(0xFF888888))),
                const SizedBox(height: 2),
                Text(a.description,
                    style: TextStyle(
                        fontSize: 12,
                        color: unlocked
                            ? AppColors.graySoft
                            : const Color(0xFFAAAAAA),
                        height: 1.4)),
                const SizedBox(height: 8),
                if (unlocked)
                  Row(
                    children: [
                      Text('+${a.rewardCoins} moedas',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A8A3A))),
                      if (_date != null) ...[
                        const SizedBox(width: 10),
                        const Icon(Icons.calendar_today,
                            size: 10, color: Color(0xFFAAAAAA)),
                        const SizedBox(width: 4),
                        Text(_date!,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFFAAAAAA))),
                      ],
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: a.progressPct / 100,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFDDDDDD),
                            valueColor:
                                const AlwaysStoppedAnimation(AppColors.blue),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${a.currentChallenges}/${a.requiredChallenges}',
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFFAAAAAA))),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
