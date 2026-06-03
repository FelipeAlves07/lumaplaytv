import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_config.dart';
import '../../../../core/storage/secure_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userController = TextEditingController();
  final passController = TextEditingController();

  final userFocus = FocusNode();
  final passFocus = FocusNode();
  final buttonFocus = FocusNode();

  final storage = SecureStorage();

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
    ),
  );

  bool loading = false;
  String? errorText;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final logged = await storage.isLoggedIn();

      if (logged && mounted) {
        context.go('/home');
        return;
      }

      userFocus.requestFocus();
    });
  }

  Future<void> _login() async {
    if (loading) return;

    setState(() {
      loading = true;
      errorText = null;
    });

    final user = userController.text.trim();
    final pass = passController.text.trim();

    if (user.isEmpty || pass.isEmpty) {
      setState(() {
        loading = false;
        errorText = 'Informe usuário e senha';
      });
      return;
    }

    try {
      final response = await dio.post(
        '/auth/login',
        data: {
          'username': user,
          'password': pass,
        },
      );

      final data = response.data as Map<String, dynamic>;

      final playlists = data['playlists'];

      if (playlists is! List || playlists.isEmpty) {
        setState(() {
          loading = false;
          errorText = 'Usuário sem playlist vinculada';
        });
        return;
      }

      final firstPlaylist = playlists.first as Map<String, dynamic>;

      final m3uUrl = firstPlaylist['m3uUrl']?.toString() ?? '';

      if (m3uUrl.isEmpty) {
        setState(() {
          loading = false;
          errorText = 'Playlist inválida para este usuário';
        });
        return;
      }

      await storage.saveSession(
        token: data['id']?.toString() ?? 'lumaplay_token',
        userId: data['id']?.toString() ?? '',
        name: data['name']?.toString() ?? '',
        username: data['username']?.toString() ?? user,
        m3uUrl: m3uUrl,
      );

      if (!mounted) return;

      context.go('/home');
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;

      setState(() {
        loading = false;

        if (statusCode == 401) {
          errorText = 'Usuário ou senha inválidos';
        } else {
          errorText = 'Não foi possível conectar ao servidor';
        }
      });
    } catch (_) {
      setState(() {
        loading = false;
        errorText = 'Erro inesperado ao fazer login';
      });
    }
  }

  @override
  void dispose() {
    userController.dispose();
    passController.dispose();
    userFocus.dispose();
    passFocus.dispose();
    buttonFocus.dispose();
    super.dispose();
  }

  Widget _buildInput({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required FocusNode focusNode,
    bool obscure = false,
    VoidCallback? onSubmit,
  }) {
    return AnimatedBuilder(
      animation: focusNode,
      builder: (context, _) {
        final focused = focusNode.hasFocus;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.black.withOpacity(0.28),
            border: Border.all(
              color: focused
                  ? const Color(0xFF8B5CFF)
                  : Colors.white.withOpacity(0.08),
              width: focused ? 2 : 1,
            ),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: const Color(0xFF8B5CFF).withOpacity(0.30),
                      blurRadius: 16,
                    ),
                  ]
                : [],
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscure,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
            onSubmitted: (_) => onSubmit?.call(),
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(
                icon,
                color: Colors.white.withOpacity(0.65),
                size: 18,
              ),
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 15,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildButton() {
    return AnimatedBuilder(
      animation: buttonFocus,
      builder: (context, _) {
        final focused = buttonFocus.hasFocus;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF00A8FF),
                Color(0xFF6D38FF),
                Color(0xFFC84EFF),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7B2DFF).withOpacity(0.30),
                blurRadius: 18,
              ),
            ],
            border: Border.all(
              color: focused ? Colors.white : Colors.transparent,
              width: 2,
            ),
          ),
          child: ElevatedButton(
            focusNode: buttonFocus,
            onPressed: loading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ENTRAR',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/branding/login_background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.45),
            ),
          ),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 16,
                  sigmaY: 16,
                ),
                child: Container(
                  width: 360,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withOpacity(0.08),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7B2DFF).withOpacity(0.18),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/branding/lumaplay_logo_horizontal.png',
                        width: 120,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sua central premium de entretenimento',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.68),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildInput(
                        hint: 'Usuário',
                        icon: Icons.person_outline_rounded,
                        controller: userController,
                        focusNode: userFocus,
                        onSubmit: () {
                          FocusScope.of(context).requestFocus(passFocus);
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildInput(
                        hint: 'Senha',
                        icon: Icons.lock_outline_rounded,
                        controller: passController,
                        focusNode: passFocus,
                        obscure: true,
                        onSubmit: () {
                          FocusScope.of(context).requestFocus(buttonFocus);
                        },
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          errorText!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      _buildButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
