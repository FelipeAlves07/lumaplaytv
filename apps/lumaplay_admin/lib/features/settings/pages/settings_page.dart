import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_shell.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      selectedIndex: 3,
      title: 'Configurações',
      subtitle: 'Defina preferências do painel e informações do sistema.',
      child: SingleChildScrollView(
        child: Column(
          children: [
            _SettingsCard(
              title: 'API do Backend',
              subtitle: 'Endereço usado pelo painel para falar com o servidor.',
              child: const TextField(
                decoration: InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'http://localhost:4000',
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SettingsCard(
              title: 'Marca',
              subtitle: 'Informações visuais do painel administrativo.',
              child: const Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Nome da plataforma',
                      hintText: 'LumaPlay',
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Descrição',
                      hintText: 'Painel Administrativo',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SettingsCard(
              title: 'Próximas integrações',
              subtitle: 'Itens que serão conectados ao backend nas próximas fases.',
              child: const Column(
                children: [
                  _TodoItem('Login real do admin'),
                  _TodoItem('Criar usuários no PostgreSQL'),
                  _TodoItem('Vincular playlist M3U por usuário'),
                  _TodoItem('Enviar playlist para o app TV após login'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _TodoItem extends StatelessWidget {
  final String text;

  const _TodoItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
