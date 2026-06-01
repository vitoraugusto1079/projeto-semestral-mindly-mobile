import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/utils/responsive.dart';
import '../common/auth_input.dart';

/// Um benefício listado no painel de marca (esquerda).
class AuthBenefit {
  final String emoji;
  final Color bg;
  final String label;
  final String sub;
  const AuthBenefit(this.emoji, this.bg, this.label, this.sub);
}

/// Layout raiz das telas de auth.
///
/// Desktop: painel de marca (gradiente) à esquerda + formulário à direita.
/// Mobile: cabeçalho de marca compacto no topo + formulário abaixo (rolável).
class AuthShell extends StatelessWidget {
  final List<TextSpan> headline; // título com destaque laranja
  final String subtitle;
  final List<AuthBenefit> benefits;
  final Widget form;

  const AuthShell({
    super.key,
    required this.headline,
    required this.subtitle,
    required this.benefits,
    required this.form,
  });

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);

    if (mobile) {
      return Container(
        color: AuthPalette.formBg,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _BrandPanel(
                  headline: headline,
                  subtitle: subtitle,
                  benefits: benefits,
                  compact: true),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                child: form,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: AuthPalette.layoutBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 44,
            child: _BrandPanel(
                headline: headline,
                subtitle: subtitle,
                benefits: benefits,
                compact: false),
          ),
          Expanded(
            flex: 56,
            child: Container(
              color: AuthPalette.formBg,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: form,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  final List<TextSpan> headline;
  final String subtitle;
  final List<AuthBenefit> benefits;
  final bool compact;

  const _BrandPanel({
    required this.headline,
    required this.subtitle,
    required this.benefits,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: compact
          ? const EdgeInsets.fromLTRB(24, 36, 24, 28)
          : const EdgeInsets.symmetric(horizontal: 52, vertical: 60),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E3A5F), Color(0xFF1C2C4C)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            compact ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          // Marca
          Row(
            children: [
              Image.asset('assets/images/mindly-logo.png',
                  width: 40, height: 40),
              const SizedBox(width: 12),
              Text('Mindly',
                  style: GoogleFonts.capriola(
                      fontSize: 22,
                      color: const Color(0xFFF1F5F9),
                      letterSpacing: 0.5)),
            ],
          ),
          SizedBox(height: compact ? 22 : 40),
          // Headline
          RichText(
            text: TextSpan(
              style: GoogleFonts.capriola(
                fontSize: compact ? 22 : 30,
                color: const Color(0xFFF1F5F9),
                height: 1.35,
              ),
              children: headline,
            ),
          ),
          const SizedBox(height: 12),
          Text(subtitle,
              style: GoogleFonts.openSans(
                  fontSize: 14, color: const Color(0xFF94A3B8), height: 1.6)),
          // Benefícios e mascote (somente desktop)
          if (!compact) ...[
            const SizedBox(height: 36),
            ...benefits.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: b.bg,
                            borderRadius: BorderRadius.circular(8)),
                        child:
                            Text(b.emoji, style: const TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.label,
                                style: GoogleFonts.openSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFE2E8F0))),
                            Text(b.sub,
                                style: GoogleFonts.openSans(
                                    fontSize: 11,
                                    color: const Color(0xFF64748B),
                                    height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 24),
            Center(
              child: Image.asset('assets/images/lapismindly.png', width: 160),
            ),
          ],
        ],
      ),
    );
  }
}

/// Título e subtítulo do formulário (lado direito).
class AuthFormHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const AuthFormHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.capriola(fontSize: 26, color: AuthPalette.ink)),
        const SizedBox(height: 6),
        Text(subtitle,
            style: GoogleFonts.openSans(
                fontSize: 14, color: AuthPalette.muted)),
        const SizedBox(height: 28),
      ],
    );
  }
}

/// Caixa de mensagem (erro vermelho / sucesso verde).
class AuthMessageBox extends StatelessWidget {
  final String text;
  final bool isError;
  const AuthMessageBox({super.key, required this.text, required this.isError});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        border: Border.all(
            color: isError ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
              size: 16,
              color: isError
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF16A34A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: GoogleFonts.openSans(
                    fontSize: 13,
                    color: isError
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF16A34A))),
          ),
        ],
      ),
    );
  }
}

/// Botão primário em gradiente azul (full width).
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  const AuthPrimaryButton(
      {super.key, required this.label, this.loading = false, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: const LinearGradient(
            colors: [AuthPalette.blue, AuthPalette.blueDark],
          ),
          boxShadow: [
            BoxShadow(
                color: AuthPalette.blue.withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 4)),
          ],
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading) ...[
                const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white)),
                const SizedBox(width: 8),
              ],
              Text(label,
                  style: GoogleFonts.openSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Divisor "ou continue com".
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AuthPalette.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('ou continue com',
                style: GoogleFonts.openSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AuthPalette.iconGray)),
          ),
          const Expanded(child: Divider(color: AuthPalette.border)),
        ],
      ),
    );
  }
}

/// Botão branco "com Google" (G colorido desenhado).
class AuthGoogleButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const AuthGoogleButton(
      {super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF334155),
          side: const BorderSide(color: AuthPalette.border, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // "G" em azul Google como marca simplificada
            Text('G',
                style: GoogleFonts.openSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4285F4))),
            const SizedBox(width: 10),
            Text(label,
                style: GoogleFonts.openSans(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// Link de alternância no rodapé do formulário ("Ainda não tem conta? ...").
class AuthSwitch extends StatelessWidget {
  final String prefix;
  final String linkLabel;
  final VoidCallback onTap;
  const AuthSwitch(
      {super.key,
      required this.prefix,
      required this.linkLabel,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(prefix,
              style: GoogleFonts.openSans(
                  fontSize: 13, color: AuthPalette.muted)),
          GestureDetector(
            onTap: onTap,
            child: Text(linkLabel,
                style: GoogleFonts.openSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AuthPalette.blue)),
          ),
        ],
      ),
    );
  }
}
