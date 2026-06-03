import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  void _enter(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topRight,
              radius: 1.1,
              colors: [
                Color(0xFF1E1B4B),
                Color(0xFF07162C),
                Color(0xFF030816),
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: 460,
              padding: const EdgeInsets.all(34),
              decoration: BoxDecoration(
                color: AppColors.card.withOpacity(0.86),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 38,
                    offset: const Offset(0, 24),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LumaPlay',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Painel Administrativo',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const TextField(
                    decoration: InputDecoration(
                      hintText: 'Usuário',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Senha',
                      prefixIcon: Icon(Icons.lock_rounded),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => _enter(context),
                      child: const Text('Entrar no painel'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'Gerencie usuários, playlists e acessos.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
