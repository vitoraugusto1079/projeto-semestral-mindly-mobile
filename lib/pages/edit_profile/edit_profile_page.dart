import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _usernameCtrl;
  late TextEditingController _photoCtrl;
  late TextEditingController _bioCtrl;
  DateTime? _birthDate;
  bool _saving = false;
  bool _success = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _usernameCtrl = TextEditingController(text: user?.username ?? '');
    _photoCtrl = TextEditingController(text: user?.photo ?? '');
    _bioCtrl = TextEditingController(text: user?.bio ?? '');
    if (user?.birth != null && user!.birth!.isNotEmpty) {
      try {
        _birthDate = DateTime.parse(user.birth!);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _photoCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      helpText: 'Data de nascimento',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _handleSave() async {
    setState(() {
      _error = '';
      _success = false;
      _saving = true;
    });
    final router = GoRouter.of(context);
    try {
      await context.read<AuthProvider>().updateProfile({
        'name': _nameCtrl.text,
        'username': _usernameCtrl.text,
        'photo': _photoCtrl.text.isNotEmpty ? _photoCtrl.text : null,
        'bio': _bioCtrl.text,
        'birth': _birthDate != null
            ? '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}'
            : null,
      });
      if (!mounted) return;
      setState(() => _success = true);
      await Future.delayed(const Duration(milliseconds: 1600));
      router.go('/perfil');
    } catch (e) {
      if (mounted) setState(() => _error = 'Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final mobile = isMobile(context);

    return Container(
      color: AppColors.bg,
      padding: EdgeInsets.symmetric(horizontal: mobile ? 20 : 40, vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Botão voltar
              TextButton.icon(
                onPressed: () => context.go('/perfil'),
                icon: const Icon(Icons.arrow_back, size: 15),
                label: const Text('Voltar ao perfil'),
                style: TextButton.styleFrom(foregroundColor: AppColors.blue),
              ),
              const SizedBox(height: 8),
              // Título
              Row(children: [
                Container(
                    width: 5,
                    height: 24,
                    decoration: BoxDecoration(
                        color: AppColors.orange,
                        borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 12),
                Text('Editar Perfil',
                    style: GoogleFonts.capriola(
                        fontSize: mobile ? 24 : 28, color: AppColors.navy)),
              ]),
              const SizedBox(height: 24),

              mobile
                  ? Column(children: [
                      _sidebar(user),
                      const SizedBox(height: 20),
                      _formCard(user, mobile),
                    ])
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 280, child: _sidebar(user)),
                        const SizedBox(width: 24),
                        Expanded(child: _formCard(user, mobile)),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Sidebar (avatar + stats) ----
  Widget _sidebar(user) {
    final photoUrl = _photoCtrl.text;
    final isAdmin = user?.role == 'admin';
    final roleLabel = isAdmin ? 'Administrador' : 'Estudante';

    return Column(
      children: [
        // Avatar card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _cardDecor,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: photoUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: photoUrl,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _avatarFallback(),
                      )
                    : _avatarFallback(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _photoCtrl,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'URL da foto',
                  hintText: 'https://exemplo.com/foto.jpg',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.camera_alt_outlined, size: 18),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cole uma URL pública de imagem para personalizar seu avatar',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.graySoft),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Stats card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _cardDecor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Seus dados',
                  style: GoogleFonts.capriola(
                      fontSize: 14, color: AppColors.navy)),
              const SizedBox(height: 16),
              _statRow(Icons.star, const Color(0xFFF59A3C),
                  'Nível ${user?.level ?? 1}', 'Nível atual'),
              const SizedBox(height: 14),
              _statRow(Icons.bolt, const Color(0xFF9B59B6),
                  '${user?.xp ?? 0} XP', 'Experiência total'),
              const SizedBox(height: 14),
              _statRow(Icons.shield_outlined, const Color(0xFF3F7FE3),
                  roleLabel, 'Permissão'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statRow(IconData icon, Color color, String value, String label) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy)),
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppColors.graySoft)),
          ],
        ),
      ],
    );
  }

  Widget _avatarFallback() {
    return Container(
      width: 90,
      height: 90,
      color: AppColors.blue.withValues(alpha: 0.12),
      child: const Icon(Icons.person, size: 44, color: AppColors.blue),
    );
  }

  // ---- Form card ----
  Widget _formCard(user, bool mobile) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: _cardDecor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_error.isNotEmpty) _alert(_error, isError: true),
          if (_success)
            _alert('Perfil atualizado com sucesso! Redirecionando…',
                isError: false),

          // Seção 1
          Text('Informações Básicas',
              style: GoogleFonts.capriola(fontSize: 16, color: AppColors.navy)),
          const SizedBox(height: 16),
          _Field(label: 'Nome completo', controller: _nameCtrl, hint: 'Seu nome'),
          _Field(
              label: 'Username', controller: _usernameCtrl, hint: '@seuuser'),
          TextField(
            enabled: false,
            decoration: InputDecoration(
              labelText: 'E-mail (somente leitura)',
              border: const OutlineInputBorder(),
              hintText: user?.email ?? '',
              prefixIcon: const Icon(Icons.lock_outline, size: 16),
            ),
          ),
          const SizedBox(height: 24),

          // Seção 2
          Text('Sobre você',
              style: GoogleFonts.capriola(fontSize: 16, color: AppColors.navy)),
          const SizedBox(height: 16),
          _Field(
              label: 'Bio',
              controller: _bioCtrl,
              maxLines: 3,
              hint: 'Fale um pouco sobre você…'),
          _DatePickerField(birthDate: _birthDate, onTap: _pickDate),
          const SizedBox(height: 20),

          // Ações
          Row(
            mainAxisAlignment:
                mobile ? MainAxisAlignment.center : MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: _saving ? null : () => context.go('/perfil'),
                icon: const Icon(Icons.arrow_back, size: 15),
                label: const Text('Cancelar'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: (_saving || _success) ? null : _handleSave,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.blue),
                icon: _saving
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(_success ? Icons.check_circle : Icons.save, size: 15),
                label: Text(_saving
                    ? 'Salvando…'
                    : _success
                        ? 'Salvo!'
                        : 'Salvar alterações'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _alert(String text, {required bool isError}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        border: Border.all(
            color: isError ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle,
              size: 16,
              color:
                  isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13,
                    color: isError
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF16A34A))),
          ),
        ],
      ),
    );
  }

  static final _cardDecor = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10),
    ],
  );
}

class _DatePickerField extends StatelessWidget {
  final DateTime? birthDate;
  final VoidCallback onTap;
  const _DatePickerField({required this.birthDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = birthDate != null
        ? '${birthDate!.day.toString().padLeft(2, '0')}/${birthDate!.month.toString().padLeft(2, '0')}/${birthDate!.year}'
        : 'Selecionar data';
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Data de nascimento',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.calendar_today, size: 18),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: birthDate != null ? Colors.black87 : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  const _Field(
      {required this.label,
      required this.controller,
      this.hint,
      this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
