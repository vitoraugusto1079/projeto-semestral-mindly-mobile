import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  static const _items = [
    {
      'title': 'Nossa Missão',
      'desc':
          'Revolucionar a educação através da tecnologia, tornando o aprendizado mais acessível e eficaz.',
    },
    {
      'title': 'Nossa Visão',
      'desc':
          'Ser a principal ferramenta para estudantes em todo o mundo alcançarem seus objetivos acadêmicos.',
    },
    {
      'title': 'Nossos Valores',
      'desc':
          'Inovação, acessibilidade, eficiência e respeito ao ritmo individual de cada estudante.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);
    return Container(
      color: const Color(0xFFF9F9F9),
      padding: EdgeInsets.symmetric(horizontal: hPad(context), vertical: 60),
      child: Column(
        children: [
          Text('Sobre o Mindly',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.capriola(fontSize: 32, color: AppColors.navy)),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              'Mindly é uma plataforma inovadora projetada para ajudar estudantes a organizarem seus estudos de forma eficiente e motivadora. Com ferramentas inteligentes, acompanhamos seu progresso e adaptamos ao seu ritmo pessoal.',
              style: GoogleFonts.openSans(
                  fontSize: mobile ? 16 : 18, color: AppColors.grayText),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 30,
            runSpacing: 30,
            alignment: WrapAlignment.center,
            children: _items
                .map((item) => Container(
                      width: 300,
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
                          Text(item['title']!,
                              style: GoogleFonts.capriola(
                                  fontSize: 18, color: AppColors.navy)),
                          const SizedBox(height: 10),
                          Text(item['desc']!,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.grayText,
                                  height: 1.5)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
