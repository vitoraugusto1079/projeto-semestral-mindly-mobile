import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta "slate" usada nas telas de auth (espelha auth.css do React).
class AuthPalette {
  static const layoutBg = Color(0xFFF1F5F9);
  static const formBg = Color(0xFFF8FAFC);
  static const ink = Color(0xFF0F172A);
  static const label = Color(0xFF475569);
  static const muted = Color(0xFF64748B);
  static const placeholder = Color(0xFFCBD5E1);
  static const border = Color(0xFFE2E8F0);
  static const blue = Color(0xFF3F7FE3);
  static const blueDark = Color(0xFF2E5FA8);
  static const orange = Color(0xFFF59A3C);
  static const danger = Color(0xFFEF4444);
  static const success = Color(0xFF22C55E);
  static const iconGray = Color(0xFF94A3B8);
}

/// Campo de formulário moderno: rótulo em maiúsculas, ícone à esquerda,
/// botão de mostrar/ocultar senha e estados de validação (erro/válido).
class AuthField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool password;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  /// null = neutro · true = válido (verde) · false = erro (vermelho)
  final bool? valid;

  const AuthField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.password = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.valid,
  });

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  late bool _obscure = widget.password;

  @override
  Widget build(BuildContext context) {
    Color borderColor = AuthPalette.border;
    if (widget.valid == true) borderColor = AuthPalette.success;
    if (widget.valid == false) borderColor = AuthPalette.danger;

    OutlineInputBorder b(Color c, double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: c, width: w),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label.toUpperCase(),
            style: GoogleFonts.openSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AuthPalette.label,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: widget.controller,
            obscureText: _obscure,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            style: GoogleFonts.openSans(
                fontSize: 14, color: AuthPalette.ink),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.openSans(
                  fontSize: 14, color: AuthPalette.placeholder),
              filled: true,
              fillColor: Colors.white,
              prefixIcon:
                  Icon(widget.icon, size: 18, color: AuthPalette.iconGray),
              suffixIcon: widget.password
                  ? IconButton(
                      splashRadius: 18,
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: AuthPalette.iconGray,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              enabledBorder: b(borderColor, 1.5),
              border: b(borderColor, 1.5),
              focusedBorder: b(
                  widget.valid == false
                      ? AuthPalette.danger
                      : AuthPalette.blue,
                  1.5),
            ),
          ),
        ],
      ),
    );
  }
}
