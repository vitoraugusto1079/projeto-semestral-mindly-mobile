import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/constants/content.dart';
import '../../data/services/progress_service.dart';
import '../../providers/auth_provider.dart';

// Mapeia a chave de ícone (igual ao React) para um IconData do Material.
IconData _iconFor(String key) {
  switch (key) {
    case 'brain':
      return Icons.psychology;
    case 'lightning':
      return Icons.bolt;
    case 'star':
      return Icons.star;
    case 'flame':
      return Icons.local_fire_department;
    case 'book':
      return Icons.menu_book;
    case 'math':
      return Icons.calculate;
    case 'award':
      return Icons.workspace_premium;
    case 'lightbulb':
      return Icons.lightbulb_outline;
    case 'trophy':
      return Icons.emoji_events;
    case 'target':
      return Icons.track_changes;
    case 'trending':
      return Icons.trending_up;
    case 'medal':
      return Icons.military_tech;
    default:
      return Icons.menu_book;
  }
}

Color _nivelColor(String nivel) {
  switch (nivel) {
    case 'Fácil':
      return const Color(0xFF27AE60);
    case 'Médio':
      return const Color(0xFFF59A3C);
    case 'Avançado':
      return const Color(0xFFE74C3C);
    default:
      return AppColors.blue;
  }
}

class LearningPathPage extends StatefulWidget {
  const LearningPathPage({super.key});

  @override
  State<LearningPathPage> createState() => _LearningPathPageState();
}

class _LearningPathPageState extends State<LearningPathPage> {
  final _service = ProgressService();
  final _tts = FlutterTts();
  int _etapaAtual = 0;
  List<int> _concluidas = [];
  bool _isSpeaking = false;
  bool _completing = false;
  bool _showSuccess = false;
  String _vista = 'trilha'; // 'trilha' | 'estudo'

  @override
  void initState() {
    super.initState();
    _load();
    _tts.setLanguage('pt-BR');
    _tts.setSpeechRate(0.9);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  String? get _userId => context.read<AuthProvider>().session?.user.id;

  Future<void> _load() async {
    final uid = _userId;
    if (uid == null) return;
    final steps = await _service.listCompletedSteps(uid);
    if (mounted) setState(() => _concluidas = steps);
  }

  Future<void> _ouvir() async {
    if (_isSpeaking) {
      await _tts.stop();
      setState(() => _isSpeaking = false);
      return;
    }
    final etapa = learningPath[_etapaAtual];
    setState(() => _isSpeaking = true);
    await _tts.speak('${etapa.titulo}. ${etapa.conteudo}');
  }

  Future<void> _marcarConcluida() async {
    final etapa = learningPath[_etapaAtual];
    final auth = context.read<AuthProvider>();
    final uid = auth.session?.user.id;
    if (_concluidas.contains(etapa.id) || uid == null || _completing) return;
    setState(() => _completing = true);
    try {
      await _service.completeStep(uid, etapa.id, etapa.xp);
      setState(() {
        _concluidas = [..._concluidas, etapa.id];
        _showSuccess = true;
      });
      await auth.refreshProfile();
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showSuccess = false);
      });
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  void _abrirEstudo(int idx) => setState(() {
        _etapaAtual = idx;
        _vista = 'estudo';
      });

  void _navegar(int delta) {
    final next = _etapaAtual + delta;
    if (next >= 0 && next < learningPath.length) {
      setState(() => _etapaAtual = next);
    }
  }

  int get _xpTotal => learningPath
      .where((s) => _concluidas.contains(s.id))
      .fold(0, (acc, s) => acc + s.xp);

  double get _progresso => (_concluidas.length / learningPath.length) * 100;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bg,
      child: _vista == 'trilha' ? _buildTrilha(context) : _buildEstudo(context),
    );
  }

  // ════════════════ VISTA: TRILHA (overview) ════════════════
  Widget _buildTrilha(BuildContext context) {
    final mobile = isMobile(context);
    final progresso = _progresso.round();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: mobile ? 20 : 40, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Row(
                children: [
                  const Icon(Icons.psychology, size: 32, color: AppColors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Trilha de Aprendizagem',
                            style: GoogleFonts.capriola(
                                fontSize: mobile ? 24 : 30,
                                color: AppColors.navy)),
                        const Text('Neurodiversidade — do básico ao avançado',
                            style: TextStyle(
                                fontSize: 14, color: AppColors.graySoft)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Card de progresso
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _progressStat('${_concluidas.length}', 'concluídos'),
                        _progressStat(
                            '${learningPath.length - _concluidas.length}',
                            'restantes'),
                        _progressStat('$_xpTotal', 'XP ganhos',
                            color: AppColors.orange),
                        _progressStat('$progresso%', 'progresso'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _progresso / 100,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFE8E8E8),
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.blue),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Lista de módulos
              Row(children: [
                Container(
                    width: 5,
                    height: 24,
                    decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 12),
                Text('Módulos do Curso',
                    style: GoogleFonts.capriola(
                        fontSize: 20, color: AppColors.navy)),
              ]),
              const SizedBox(height: 16),
              ...learningPath.asMap().entries.map((e) {
                final idx = e.key;
                final m = e.value;
                final done = _concluidas.contains(m.id);
                return _ModuleRow(
                  step: m,
                  done: done,
                  onTap: () => _abrirEstudo(idx),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressStat(String num, String lbl, {Color? color}) {
    return Column(
      children: [
        Text(num,
            style: GoogleFonts.capriola(
                fontSize: 24, color: color ?? AppColors.navy)),
        const SizedBox(height: 2),
        Text(lbl,
            style: const TextStyle(fontSize: 12, color: AppColors.graySoft)),
      ],
    );
  }

  // ════════════════ VISTA: ESTUDO ════════════════
  Widget _buildEstudo(BuildContext context) {
    final mobile = isMobile(context);
    final etapa = learningPath[_etapaAtual];
    final done = _concluidas.contains(etapa.id);
    final progresso = _progresso.round();

    final main = SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(mobile ? 20 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mobile)
              _backButton(),
            if (_showSuccess) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 16, color: Color(0xFF16A34A)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Módulo concluído! +${etapa.xp} XP ganhos.',
                          style: const TextStyle(
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],

            // Meta chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _nivelBadge(etapa.nivel),
                _metaChip(Icons.schedule, etapa.tempo),
                _metaChip(Icons.bolt, '${etapa.xp} XP',
                    color: AppColors.orange),
                _metaChip(null, 'Módulo ${_etapaAtual + 1} de ${learningPath.length}'),
              ],
            ),
            const SizedBox(height: 16),

            // Título
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_iconFor(etapa.icon),
                      size: 26, color: AppColors.blue),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(etapa.titulo,
                      style: GoogleFonts.capriola(
                          fontSize: mobile ? 22 : 28, color: AppColors.navy)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Cards
            _contentCard(
              label: 'Conteúdo',
              labelColor: AppColors.blue,
              icon: Icons.menu_book,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: etapa.conteudo
                    .split('\n\n')
                    .map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(p,
                              style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.navy,
                                  height: 1.6)),
                        ))
                    .toList(),
              ),
            ),
            if (etapa.curiosidade.isNotEmpty)
              _contentCard(
                label: 'Curiosidade',
                labelColor: AppColors.blue,
                icon: Icons.info_outline,
                bg: const Color(0xFFEFF6FF),
                child: Text(etapa.curiosidade,
                    style: const TextStyle(
                        fontSize: 15, color: AppColors.navy, height: 1.6)),
              ),
            if (etapa.exemploPratico.isNotEmpty)
              _contentCard(
                label: 'Exemplo Prático',
                labelColor: const Color(0xFF27AE60),
                icon: Icons.science_outlined,
                bg: const Color(0xFFF0FDF4),
                child: Text(etapa.exemploPratico,
                    style: const TextStyle(
                        fontSize: 15, color: AppColors.navy, height: 1.6)),
              ),
            _contentCard(
              label: 'Dica',
              labelColor: AppColors.orange,
              icon: Icons.lightbulb_outline,
              bg: const Color(0xFFFFF8ED),
              child: Text(etapa.dica,
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.navy, height: 1.6)),
            ),
            const SizedBox(height: 8),

            // Controles
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: _etapaAtual > 0 ? () => _navegar(-1) : null,
                  icon: const Icon(Icons.chevron_left, size: 18),
                  label: const Text('Anterior'),
                ),
                OutlinedButton.icon(
                  onPressed: _ouvir,
                  icon: Icon(_isSpeaking ? Icons.stop : Icons.volume_up,
                      size: 18),
                  label: Text(_isSpeaking ? 'Parar' : 'Ouvir'),
                ),
                ElevatedButton.icon(
                  onPressed: (done || _completing) ? null : _marcarConcluida,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: done ? AppColors.green : AppColors.blue,
                    disabledBackgroundColor:
                        done ? AppColors.green : const Color(0xFFBBBBBB),
                    disabledForegroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: Text(_completing
                      ? 'Salvando…'
                      : done
                          ? 'Concluído'
                          : 'Concluir · +${etapa.xp} XP'),
                ),
                ElevatedButton.icon(
                  onPressed: _etapaAtual < learningPath.length - 1
                      ? () => _navegar(1)
                      : null,
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppColors.blue),
                  icon: const Icon(Icons.chevron_right, size: 18),
                  label: const Text('Próximo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (mobile) return main;

    // Desktop: sidebar + conteúdo
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 280, child: _buildSidebar(progresso)),
        Expanded(child: main),
      ],
    );
  }

  Widget _backButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextButton.icon(
        onPressed: () => setState(() => _vista = 'trilha'),
        icon: const Icon(Icons.chevron_left, size: 16),
        label: const Text('Todos os módulos'),
        style: TextButton.styleFrom(foregroundColor: AppColors.blue),
      ),
    );
  }

  Widget _buildSidebar(int progresso) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _backButton(),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: _progresso / 100,
                minHeight: 8,
                backgroundColor: const Color(0xFFE8E8E8),
                valueColor: const AlwaysStoppedAnimation(AppColors.blue),
              ),
            ),
            const SizedBox(height: 6),
            Text('$progresso% concluído',
                style: const TextStyle(fontSize: 12, color: AppColors.graySoft)),
            const SizedBox(height: 16),
            ...learningPath.asMap().entries.map((e) {
              final i = e.key;
              final item = e.value;
              final active = i == _etapaAtual;
              final done = _concluidas.contains(item.id);
              return GestureDetector(
                onTap: () => setState(() => _etapaAtual = i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.blue.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: done
                              ? AppColors.green
                              : active
                                  ? AppColors.blue
                                  : const Color(0xFFDDDDDD),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: done
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.white)
                              : Text('${i + 1}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(item.titulo,
                            style: TextStyle(
                                fontSize: 13,
                                color:
                                    active ? AppColors.blue : AppColors.navy,
                                fontWeight: active
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _nivelBadge(String nivel) {
    final c = _nivelColor(nivel);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(nivel,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: c)),
    );
  }

  Widget _metaChip(IconData? icon, String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color ?? AppColors.graySoft),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: TextStyle(
                  fontSize: 12, color: color ?? AppColors.graySoft)),
        ],
      ),
    );
  }

  Widget _contentCard({
    required String label,
    required Color labelColor,
    required IconData icon,
    required Widget child,
    Color bg = Colors.white,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: labelColor),
              const SizedBox(width: 6),
              Text(label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// Linha de módulo na vista de overview.
class _ModuleRow extends StatelessWidget {
  final LearningStep step;
  final bool done;
  final VoidCallback onTap;
  const _ModuleRow(
      {required this.step, required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: done ? const Color(0xFFF6FBF7) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: done
                  ? AppColors.green.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.04)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: done
                    ? AppColors.green.withValues(alpha: 0.15)
                    : AppColors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(done ? Icons.check_circle : _iconFor(step.icon),
                  size: 22, color: done ? AppColors.green : AppColors.blue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(step.titulo,
                            style: GoogleFonts.capriola(
                                fontSize: 15, color: AppColors.navy)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _nivelColor(step.nivel).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(step.nivel,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _nivelColor(step.nivel))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 12, color: AppColors.graySoft),
                      const SizedBox(width: 4),
                      Text(step.tempo,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.graySoft)),
                      const SizedBox(width: 12),
                      const Icon(Icons.bolt, size: 12, color: AppColors.graySoft),
                      const SizedBox(width: 4),
                      Text('${step.xp} XP',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.graySoft)),
                      if (done) ...[
                        const SizedBox(width: 12),
                        const Icon(Icons.check_circle,
                            size: 11, color: AppColors.green),
                        const SizedBox(width: 4),
                        const Text('Concluído',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.green,
                                fontWeight: FontWeight.w600)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.graySoft),
          ],
        ),
      ),
    );
  }
}
