import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/auth_input.dart';
import '../../widgets/auth/auth_shell.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _error = '';
  String _info = '';
  bool _loading = false;

  static const _benefits = [
    AuthBenefit('🚀', Color(0xFFEFF6FF), 'Comece em minutos',
        'Criação de conta rápida e gratuita'),
    AuthBenefit('📈', Color(0xFFF0FDF4), 'Evolua do básico ao avançado',
        'Trilha adaptada ao seu nível'),
    AuthBenefit('🎮', Color(0xFFFEFCE8), 'Aprendizado gamificado',
        'Pontos, conquistas e rankings'),
    AuthBenefit('🧠', Color(0xFFFDF4FF), 'Retenção garantida',
        'Técnicas validadas de memorização'),
  ];

  static const _strengthLabels = ['', 'Fraca', 'Regular', 'Boa', 'Forte'];
  static const _strengthColors = [
    Color(0xFFE2E8F0),
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFF22C55E),
  ];

  int _calcStrength(String pw) {
    if (pw.isEmpty) return 0;
    int score = 0;
    if (pw.length >= 6) score++;
    if (pw.length >= 10) score++;
    if (RegExp(r'[0-9]').hasMatch(pw)) score++;
    if (RegExp(r'[^a-zA-Z0-9]').hasMatch(pw)) score++;
    return score;
  }

  Future<void> _handleRegister() async {
    setState(() {
      _error = '';
      _info = '';
      _loading = true;
    });
    final email = _emailCtrl.text.trim();
    final senha = _senhaCtrl.text;
    final confirm = _confirmCtrl.text;
    final name = _nameCtrl.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      setState(() {
        _error = 'Preencha e-mail e senha.';
        _loading = false;
      });
      return;
    }
    if (senha.length < 6) {
      setState(() {
        _error = 'A senha deve ter pelo menos 6 caracteres.';
        _loading = false;
      });
      return;
    }
    if (confirm.isNotEmpty && confirm != senha) {
      setState(() {
        _error = 'As senhas não coincidem.';
        _loading = false;
      });
      return;
    }

    try {
      await context
          .read<AuthProvider>()
          .register(email: email, password: senha, name: name);
      if (mounted) {
        setState(() => _info =
            'Conta criada! Verifique seu e-mail para confirmar e depois faça login.');
      }
    } catch (e) {
      setState(() => _error = _traduzErro(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogle() async {
    setState(() => _error = '');
    try {
      await context.read<AuthProvider>().loginWithGoogle();
    } catch (e) {
      setState(() => _error = 'Erro ao cadastrar com Google: $e');
    }
  }

  String _traduzErro(String msg) {
    if (msg.contains('already registered') || msg.contains('already been')) {
      return 'Este e-mail já está cadastrado.';
    }
    if (msg.toLowerCase().contains('password')) {
      return 'Senha inválida (mínimo 6 caracteres).';
    }
    return msg;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final senha = _senhaCtrl.text;
    final confirm = _confirmCtrl.text;
    final strength = _calcStrength(senha);
    final passwordsMatch = confirm.isNotEmpty && confirm == senha;
    final passwordsWrong = confirm.isNotEmpty && confirm != senha;

    return SizedBox.expand(
      child: AuthShell(
        headline: const [
          TextSpan(text: 'Comece sua jornada de '),
          TextSpan(
              text: 'aprendizado', style: TextStyle(color: Color(0xFFF59A3C))),
          TextSpan(text: ' hoje'),
        ],
        subtitle:
            'Junte-se a milhares de estudantes que já transformaram sua forma de aprender.',
        benefits: _benefits,
        form: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthFormHeader(
              title: 'Criar conta gratuita',
              subtitle: 'Preencha os dados abaixo e comece agora mesmo.',
            ),
            if (_error.isNotEmpty) AuthMessageBox(text: _error, isError: true),
            if (_info.isNotEmpty) AuthMessageBox(text: _info, isError: false),
            AuthField(
              label: 'Nome',
              hint: 'Como devemos te chamar?',
              icon: LucideIcons.user,
              controller: _nameCtrl,
            ),
            AuthField(
              label: 'E-mail',
              hint: 'seu@email.com',
              icon: LucideIcons.mail,
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
            ),
            AuthField(
              label: 'Senha',
              hint: 'Mínimo 6 caracteres',
              icon: LucideIcons.lock,
              controller: _senhaCtrl,
              password: true,
              onChanged: (_) => setState(() {}),
            ),
            if (senha.isNotEmpty) _strengthMeter(strength),
            const SizedBox(height: 16),
            AuthField(
              label: 'Confirmar senha',
              hint: 'Repita a senha',
              icon: LucideIcons.lock,
              controller: _confirmCtrl,
              password: true,
              onChanged: (_) => setState(() {}),
              valid: passwordsMatch
                  ? true
                  : (passwordsWrong ? false : null),
            ),
            if (passwordsMatch) _matchHint(true),
            if (passwordsWrong) _matchHint(false),
            const SizedBox(height: 8),
            AuthPrimaryButton(
              label: _loading ? 'Criando conta…' : 'Criar conta grátis',
              loading: _loading,
              onPressed: _handleRegister,
            ),
            const AuthDivider(),
            AuthGoogleButton(
              label: 'Cadastrar com Google',
              onPressed: _handleGoogle,
            ),
            Center(
              child: AuthSwitch(
                prefix: 'Já tem uma conta? ',
                linkLabel: 'Entrar agora',
                onTap: () => context.go('/login'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _strengthMeter(int strength) {
    final color = _strengthColors[strength];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(4, (i) {
              return Expanded(
                child: Container(
                  height: 3,
                  margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: (i + 1) <= strength
                        ? color
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 5),
          Text(_strengthLabels[strength],
              style: GoogleFonts.openSans(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _matchHint(bool ok) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle_outline : Icons.error_outline,
              size: 12,
              color: ok ? AuthPalette.success : AuthPalette.danger),
          const SizedBox(width: 4),
          Text(ok ? 'Senhas coincidem' : 'As senhas não coincidem',
              style: GoogleFonts.openSans(
                  fontSize: 11,
                  color: ok ? AuthPalette.success : AuthPalette.danger)),
        ],
      ),
    );
  }
}
