import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/auth_input.dart';
import '../../widgets/auth/auth_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  String _error = '';
  bool _loading = false;

  static const _benefits = [
    AuthBenefit('🎯', Color(0xFFEFF6FF), 'Trilha personalizada',
        'Conteúdo adaptado ao seu ritmo'),
    AuthBenefit('🏆', Color(0xFFFEFCE8), 'Conquistas e XP',
        'Evolua e ganhe recompensas'),
    AuthBenefit('📊', Color(0xFFF0FDF4), 'Progresso em tempo real',
        'Veja sua evolução diária'),
    AuthBenefit('🔥', Color(0xFFFFF7ED), 'Desafios diários',
        'Gamificação para manter o foco'),
  ];

  Future<void> _handleLogin() async {
    setState(() {
      _error = '';
      _loading = true;
    });
    final email = _emailCtrl.text.trim();
    final senha = _senhaCtrl.text;

    if (email.isEmpty || senha.isEmpty) {
      setState(() {
        _error = 'Preencha todos os campos.';
        _loading = false;
      });
      return;
    }

    try {
      await context.read<AuthProvider>().login(email: email, password: senha);
      if (mounted) context.go('/planner');
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
      setState(() => _error = 'Erro ao entrar com Google: $e');
    }
  }

  String _traduzErro(String msg) {
    if (msg.contains('Invalid login')) return 'E-mail ou senha incorretos.';
    if (msg.contains('Email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar.';
    }
    return msg;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: AuthShell(
        headline: const [
          TextSpan(text: 'Aprenda de forma '),
          TextSpan(
              text: 'gamificada', style: TextStyle(color: Color(0xFFF59A3C))),
          TextSpan(text: ' e evolua todos os dias'),
        ],
        subtitle: 'A plataforma que transforma seu aprendizado em conquistas.',
        benefits: _benefits,
        form: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthFormHeader(
              title: 'Bem-vindo de volta!',
              subtitle: 'Entre na sua conta para continuar estudando.',
            ),
            if (_error.isNotEmpty) AuthMessageBox(text: _error, isError: true),
            AuthField(
              label: 'E-mail',
              hint: 'seu@email.com',
              icon: LucideIcons.mail,
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
            ),
            AuthField(
              label: 'Senha',
              hint: 'Digite sua senha',
              icon: LucideIcons.lock,
              controller: _senhaCtrl,
              password: true,
            ),
            const SizedBox(height: 8),
            AuthPrimaryButton(
              label: _loading ? 'Entrando…' : 'Entrar na conta',
              loading: _loading,
              onPressed: _handleLogin,
            ),
            const AuthDivider(),
            AuthGoogleButton(
              label: 'Entrar com Google',
              onPressed: _handleGoogle,
            ),
            Center(
              child: AuthSwitch(
                prefix: 'Ainda não tem conta? ',
                linkLabel: 'Criar conta grátis',
                onTap: () => context.go('/cadastro'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
