import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../common/primary_button.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);
    final pad = hPad(context);

    final textBlock = Column(
      crossAxisAlignment:
          mobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          'Organize seus estudos\ncom a Mindly',
          textAlign: mobile ? TextAlign.center : TextAlign.start,
          style: GoogleFonts.capriola(
            fontSize: mobile ? 32 : 44,
            color: AppColors.navy,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Text(
            'Crie planos sob medida, acompanhe seu progresso e ganhe recompensas enquanto aprende.',
            textAlign: mobile ? TextAlign.center : TextAlign.start,
            style: GoogleFonts.openSans(
              fontSize: mobile ? 15 : 18,
              color: AppColors.graySoft,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 30),
        PrimaryButton(
          label: 'Crie uma conta',
          onPressed: () => context.go('/cadastro'),
        ),
      ],
    );

    final imageBlock = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.asset(
        'assets/images/home.jpg',
        width: mobile ? double.infinity : 460,
        fit: BoxFit.cover,
      ),
    );

    return Container(
      color: AppColors.bg,
      padding: EdgeInsets.fromLTRB(pad, 60, pad, 80),
      child: mobile
          ? Column(
              children: [
                textBlock,
                const SizedBox(height: 32),
                imageBlock,
              ],
            )
          : Row(
              children: [
                Expanded(child: textBlock),
                const SizedBox(width: 40),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: imageBlock,
                  ),
                ),
              ],
            ),
    );
  }
}
