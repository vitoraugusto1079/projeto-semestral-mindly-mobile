import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart' show kMobileBreak;
import '../../data/models/achievement.dart';
import '../../data/models/subject_progress.dart';
import '../../data/models/user_stats.dart';
import '../../data/services/progress_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/rewards_panel.dart';

class PerformancePage extends StatefulWidget {
  const PerformancePage({super.key});

  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage> {
  final _service = ProgressService();
  List<Achievement> _achievements = [];
  List<SubjectProgress> _subjects = [];
  UserStats _stats = const UserStats();
  List<String> _newlyUnlocked = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = context.read<AuthProvider>().session?.user.id;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final check = await _service.checkAchievements(uid);
      final unlocked = (check?['unlocked'] as List?) ?? [];
      if (unlocked.isNotEmpty) {
        _newlyUnlocked = unlocked
            .map((a) => (a is Map ? a['title']?.toString() : a.toString()) ?? '')
            .where((t) => t.isNotEmpty)
            .toList();
      }

      final results = await Future.wait([
        _service.listAchievements(uid),
        _service.listSubjectPerformance(uid),
        _service.getStats(uid),
      ]);
      setState(() {
        _achievements = results[0] as List<Achievement>;
        _subjects = results[1] as List<SubjectProgress>;
        _stats = results[2] as UserStats;
      });
    } catch (_) {
      // mantém estado vazio em caso de erro
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_newlyUnlocked.isNotEmpty)
                _UnlockedBanner(
                  titles: _newlyUnlocked,
                  onClose: () => setState(() => _newlyUnlocked = []),
                ),

              // ===== VISÃO GERAL =====
              const _SectionTitle(label: 'Visão Geral'),
              const SizedBox(height: 22),
              _buildStatsGrid(),

              const SizedBox(height: 52),

              // ===== CONQUISTAS =====
              const _SectionTitle(label: 'Conquistas'),
              const SizedBox(height: 22),
              _buildAchievements(),

              const SizedBox(height: 52),

              // ===== DESEMPENHO =====
              const _SectionTitle(label: 'Desempenho'),
              const SizedBox(height: 22),
              _buildPerformanceGrid(),

              const SizedBox(height: 52),

              // ===== RECOMPENSAS =====
              const RewardsPanel(),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Visão Geral ----
  Widget _buildStatsGrid() {
    final cards = <Widget>[
      _StatCard(
          icon: Icons.check_circle,
          value: '${_stats.completedChallenges}',
          label: 'Desafios Concluídos',
          color: const Color(0xFF27AE60)),
      _StatCard(
          icon: Icons.trending_up,
          value: '${_stats.completionRate}%',
          label: 'Taxa de Conclusão',
          color: const Color(0xFF3F7FE3)),
      _StatCard(
          icon: Icons.emoji_events,
          value: '${_stats.unlockedAchievements}',
          label: 'Conquistas',
          color: const Color(0xFFF59A3C)),
      _StatCard(
          icon: Icons.local_fire_department,
          value: '${_stats.streak}',
          label: 'Dias Consecutivos',
          color: const Color(0xFFE74C3C)),
      _StatCard(
          icon: Icons.bolt,
          value: '${_stats.xp}',
          label: 'XP Total',
          color: const Color(0xFF9B59B6)),
      _StatCard(
          icon: Icons.star,
          value: 'Nível ${_stats.level}',
          label: 'Nível Atual',
          color: const Color(0xFFF59A3C)),
      _StatCard(
          icon: Icons.calendar_today,
          value: '${_stats.studyDaysThisWeek}',
          label: 'Dias de Estudo (semana)',
          color: const Color(0xFF1ABC9C)),
      _StatCard(
          icon: Icons.monetization_on,
          value: '${_stats.coins}',
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
        children: cards
            .map((card) => SizedBox(
                width: w, child: _loading ? _skeleton(110) : card))
            .toList(),
      );
    });
  }

  // ---- Conquistas ----
  Widget _buildAchievements() {
    return LayoutBuilder(builder: (_, c) {
      final cols = c.maxWidth < 560 ? 2 : (c.maxWidth < 900 ? 3 : 4);
      const gap = 20.0;
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      final items = _loading
          ? List.generate(4, (_) => _skeleton(170))
          : _achievements.map((a) => _AchievementCard(achievement: a)).toList();
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: items.map((w0) => SizedBox(width: w, child: w0)).toList(),
      );
    });
  }

  // ---- Desempenho (donut + disciplinas) ----
  Widget _buildPerformanceGrid() {
    final cardDecor = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.black.withValues(alpha: 0.04), width: 1.5),
      boxShadow: [
        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
      ],
    );

    final completed = _stats.completionRate.toDouble();
    final inProgress = _stats.totalChallenges > 0
        ? ((_stats.inProgressChallenges / _stats.totalChallenges) * 100).round().toDouble()
        : 0.0;
    final notStarted = math.max(0.0, 100 - completed - inProgress);

    final chartCard = Container(
      padding: const EdgeInsets.all(24),
      decoration: cardDecor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progresso Geral',
              style: GoogleFonts.capriola(fontSize: 15, color: AppColors.navy)),
          const SizedBox(height: 18),
          Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: CustomPaint(
                painter: _DonutPainter(
                  completed: completed,
                  inProgress: inProgress,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${_stats.completionRate}%',
                          style: GoogleFonts.capriola(
                              fontSize: 22, color: AppColors.navy)),
                      const Text('concluído',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.graySoft)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _legend(const Color(0xFF27AE60),
              'Concluídos (${_stats.completedChallenges})'),
          const SizedBox(height: 8),
          _legend(const Color(0xFF3F7FE3),
              'Em andamento (${_stats.inProgressChallenges})'),
          if (notStarted > 0) ...[
            const SizedBox(height: 8),
            _legend(const Color(0xFFE0E6F0), 'Não iniciados'),
          ],
        ],
      ),
    );

    final progressCard = Container(
      padding: const EdgeInsets.all(24),
      decoration: cardDecor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progresso por Disciplina',
              style: GoogleFonts.capriola(fontSize: 15, color: AppColors.navy)),
          const SizedBox(height: 16),
          if (_loading)
            _skeleton(120)
          else if (_subjects.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Estude e conclua desafios para ver seu progresso aqui.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.graySoft, fontSize: 13),
              ),
            )
          else
            ..._subjects.map((s) => _ProgressItem(subject: s)),
          if (!_loading) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 16),
            Row(
              children: [
                _studyStat('${_stats.studyDaysThisWeek}', 'dias esta semana'),
                const SizedBox(width: 16),
                _studyStat('${_stats.studyDaysThisMonth}', 'dias este mês'),
              ],
            ),
          ],
        ],
      ),
    );

    return LayoutBuilder(builder: (_, c) {
      final narrow = c.maxWidth < kMobileBreak;
      return narrow
          ? Column(children: [
              chartCard,
              const SizedBox(height: 24),
              progressCard,
            ])
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 280, child: chartCard),
                const SizedBox(width: 24),
                Expanded(child: progressCard),
              ],
            );
    });
  }

  Widget _legend(Color color, String text) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 13, color: Color(0xFF555555))),
        ),
      ],
    );
  }

  Widget _studyStat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.blue.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.capriola(
                    fontSize: 22, color: AppColors.navy)),
            const SizedBox(height: 3),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.graySoft, height: 1.3)),
          ],
        ),
      ),
    );
  }

  Widget _skeleton(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF5),
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

// ── Banner de conquistas recém desbloqueadas ────────────────────────────────
class _UnlockedBanner extends StatelessWidget {
  final List<String> titles;
  final VoidCallback onClose;
  const _UnlockedBanner({required this.titles, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFFF7ED), Color(0xFFFFF3E0)]),
        border: Border.all(color: AppColors.orange, width: 1.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: AppColors.orange, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Conquistas desbloqueadas!',
                    style: GoogleFonts.capriola(
                        fontSize: 15, color: AppColors.navy)),
                Text(titles.join(', '),
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.graySoft)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Color(0xFFAAAAAA)),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 5,
            height: 24,
            decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 12),
        Text(label,
            style: GoogleFonts.capriola(fontSize: 20, color: AppColors.navy)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatCard(
      {required this.icon,
      required this.value,
      required this.label,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: Colors.black.withValues(alpha: 0.04), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(value,
              textAlign: TextAlign.center,
              style: GoogleFonts.capriola(fontSize: 22, color: AppColors.navy)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.graySoft, height: 1.3)),
        ],
      ),
    );
  }
}

// ── Pintor do gráfico donut ──────────────────────────────────────────────────
class _DonutPainter extends CustomPainter {
  final double completed; // %
  final double inProgress; // %
  _DonutPainter({required this.completed, required this.inProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const stroke = 28.0;
    final rect = Rect.fromCircle(center: center, radius: radius - stroke / 2);
    const start = -math.pi / 2;

    Paint p(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    // Fundo (não iniciados)
    canvas.drawCircle(center, radius - stroke / 2, p(const Color(0xFFE0E6F0)));

    final compSweep = completed / 100 * 2 * math.pi;
    final progSweep = inProgress / 100 * 2 * math.pi;

    if (compSweep > 0) {
      canvas.drawArc(rect, start, compSweep, false, p(const Color(0xFF27AE60)));
    }
    if (progSweep > 0) {
      canvas.drawArc(
          rect, start + compSweep, progSweep, false, p(const Color(0xFF3F7FE3)));
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.completed != completed || old.inProgress != inProgress;
}

// ── Card de conquista ─────────────────────────────────────────────────────────
class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  const _AchievementCard({required this.achievement});

  String? get _formattedDate {
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
    if (a.unlocked) {
      return Container(
        constraints: const BoxConstraints(minHeight: 170),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.orange.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05), blurRadius: 8),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 32, color: AppColors.orange),
            const SizedBox(height: 8),
            Text(a.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.capriola(
                    fontSize: 15, color: AppColors.orangeDark)),
            const SizedBox(height: 4),
            Text(a.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.graySoft, height: 1.4)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF27AE60).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('+${a.rewardCoins} moedas',
                  style: const TextStyle(
                      color: Color(0xFF1A8A3A),
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ),
            if (_formattedDate != null) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today,
                      size: 11, color: Color(0xFFAAAAAA)),
                  const SizedBox(width: 4),
                  Text(_formattedDate!,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFAAAAAA))),
                ],
              ),
            ],
          ],
        ),
      );
    }

    // Bloqueado
    return Container(
      constraints: const BoxConstraints(minHeight: 170),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFF7F7F7), Color(0xFFEFEFEF)]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD0D0D0), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFB4B4B4).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lock, size: 28, color: Color(0xFFBBBBBB)),
          ),
          const SizedBox(height: 8),
          Text(a.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF888888))),
          const SizedBox(height: 4),
          Text(a.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFFAAAAAA), height: 1.4)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: a.progressPct / 100,
              minHeight: 6,
              backgroundColor: const Color(0xFFDDDDDD),
              valueColor: const AlwaysStoppedAnimation(AppColors.blue),
            ),
          ),
          const SizedBox(height: 5),
          Text('${a.currentChallenges}/${a.requiredChallenges} desafios',
              style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA))),
        ],
      ),
    );
  }
}

class _ProgressItem extends StatelessWidget {
  final SubjectProgress subject;
  const _ProgressItem({required this.subject});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subject.subject,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.navy,
                      fontWeight: FontWeight.w500)),
              Text('${subject.percentage}%',
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.blue,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: subject.percentage / 100,
              minHeight: 7,
              backgroundColor: const Color(0xFFE8E8E8),
              valueColor: const AlwaysStoppedAnimation(AppColors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
