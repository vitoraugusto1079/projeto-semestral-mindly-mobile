import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../common/primary_button.dart';

class ToolsSection extends StatefulWidget {
  const ToolsSection({super.key});

  @override
  State<ToolsSection> createState() => _ToolsSectionState();
}

class _ToolsSectionState extends State<ToolsSection> {
  static const _tools = [
    {
      'icon': 'assets/images/iconeplanner.png',
      'title': 'Planner inteligente',
      'desc':
          'Monte horários personalizados com blocos de tempo, pausas automáticas e prioridades visuais.',
      'cta': 'Criar plano',
      'route': '/planner',
    },
    {
      'icon': 'assets/images/iconegrafico.png',
      'title': 'Desempenho',
      'desc':
          'Gráficos detalhados de horas estudadas, metas cumpridas e evolução por disciplina.',
      'cta': 'Ver painel',
      'route': '/desempenho',
    },
    {
      'icon': 'assets/images/iconetrofeu.png',
      'title': 'Desafios',
      'desc':
          'Missões curtas para manter a motivação: recompensas em XP e conquistas.',
      'cta': 'Explorar',
      'route': '/desafios',
    },
  ];

  int _active = 0;

  void _prev() =>
      setState(() => _active = (_active - 1 + _tools.length) % _tools.length);
  void _next() => setState(() => _active = (_active + 1) % _tools.length);

  @override
  Widget build(BuildContext context) {
    final pad = hPad(context);
    final mobile = isMobile(context);

    return Container(
      color: AppColors.bg,
      padding: EdgeInsets.fromLTRB(pad, 40, pad, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
                width: 6,
                height: 32,
                decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 15),
            Expanded(
              child: Text('Ferramentas que se adaptam ao seu ritmo',
                  style: GoogleFonts.capriola(
                      fontSize: mobile ? 24 : 30, color: AppColors.navy)),
            ),
          ]),
          const SizedBox(height: 40),
          mobile ? _buildCarousel() : _buildGrid(),
        ],
      ),
    );
  }

  // Desktop / tablet: grade que quebra em colunas.
  Widget _buildGrid() {
    return Wrap(
      spacing: 30,
      runSpacing: 30,
      children: _tools.map((t) => _ToolCard(tool: t)).toList(),
    );
  }

  // Mobile: carrossel com setas e indicadores (como no React).
  Widget _buildCarousel() {
    return Column(
      children: [
        Row(
          children: [
            _CarouselArrow(icon: Icons.chevron_left, onTap: _prev),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0.15, 0), end: Offset.zero)
                        .animate(anim),
                    child: child,
                  ),
                ),
                child: _ToolCard(
                  key: ValueKey(_active),
                  tool: _tools[_active],
                  fullWidth: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _CarouselArrow(icon: Icons.chevron_right, onTap: _next),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_tools.length, (i) {
            final active = i == _active;
            return GestureDetector(
              onTap: () => setState(() => _active = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 13 : 10,
                height: active ? 13 : 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? AppColors.blue
                      : AppColors.blue.withValues(alpha: 0.25),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CarouselArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blue,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final Map<String, String> tool;
  final bool fullWidth;
  const _ToolCard({super.key, required this.tool, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? null : 300,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Image.asset(tool['icon']!, width: 42, height: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Text(tool['title']!,
                  style: GoogleFonts.capriola(
                      fontSize: 18, color: AppColors.navy)),
            ),
          ]),
          const SizedBox(height: 16),
          Text(tool['desc']!,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.graySoft, height: 1.6)),
          const SizedBox(height: 24),
          PrimaryButton(
            label: tool['cta']!,
            variant: ButtonVariant.outline,
            onPressed: () => context.go(tool['route']!),
          ),
        ],
      ),
    );
  }
}
