import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../data/services/contact_service.dart';
import '../../providers/auth_provider.dart';
import '../common/primary_button.dart';

class ContactSection extends StatefulWidget {
  const ContactSection({super.key});

  @override
  State<ContactSection> createState() => _ContactSectionState();
}

class _ContactSectionState extends State<ContactSection> {
  final _service = ContactService();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _feedback = '';
  bool _sending = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_nameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _msgCtrl.text.isEmpty) {
      setState(() => _feedback = 'Preencha todos os campos.');
      return;
    }
    setState(() => _sending = true);
    final uid = context.read<AuthProvider>().session?.user.id;
    try {
      await _service.sendMessage(
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        subject: 'Contato pelo site',
        message: _msgCtrl.text,
        userId: uid,
      );
      _nameCtrl.clear();
      _emailCtrl.clear();
      _msgCtrl.clear();
      setState(() => _feedback = '✅ Mensagem enviada com sucesso!');
    } catch (e) {
      setState(() => _feedback = 'Erro ao enviar: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);
    return Container(
      color: const Color(0xFFF9F9F9),
      padding: EdgeInsets.symmetric(horizontal: hPad(context), vertical: 60),
      child: Column(
        children: [
          Text('Entre em Contato',
              textAlign: TextAlign.center,
              style:
                  GoogleFonts.capriola(fontSize: 32, color: AppColors.navy)),
          const SizedBox(height: 20),
          Text(
            'Tem dúvidas ou sugestões? Estamos aqui para ajudar!',
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(
                fontSize: mobile ? 16 : 18, color: AppColors.grayText),
          ),
          const SizedBox(height: 40),
          mobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _info(),
                    const SizedBox(height: 28),
                    _form(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _info()),
                    const SizedBox(width: 50),
                    Expanded(child: _form()),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _info() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Informações de Contato',
            style: GoogleFonts.capriola(fontSize: 18, color: AppColors.navy)),
        const SizedBox(height: 15),
        _infoLine('Email:', ' contato@mindly.com'),
        const SizedBox(height: 10),
        _infoLine('Telefone:', ' (11) 9999-9999'),
        const SizedBox(height: 10),
        _infoLine('Endereço:', ' São Paulo, SP'),
      ],
    );
  }

  Widget _infoLine(String label, String value) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16, color: AppColors.navy),
        children: [
          TextSpan(
              text: label,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          TextSpan(text: value),
        ],
      ),
    );
  }

  Widget _form() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ContactInput(controller: _nameCtrl, hint: 'Nome'),
        _ContactInput(
            controller: _emailCtrl,
            hint: 'Email',
            type: TextInputType.emailAddress),
        TextField(
          controller: _msgCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Mensagem',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 15),
        PrimaryButton(
          label: _sending ? 'Enviando…' : 'Enviar Mensagem',
          onPressed: _sending ? null : _send,
        ),
        if (_feedback.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(_feedback,
              style: const TextStyle(
                  color: AppColors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ],
      ],
    );
  }
}

class _ContactInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType type;
  const _ContactInput(
      {required this.controller,
      required this.hint,
      this.type = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
