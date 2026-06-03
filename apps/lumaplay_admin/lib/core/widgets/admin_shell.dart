import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AdminShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final int selectedIndex;
  final Widget child;

  const AdminShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selectedIndex,
    required this.child,
  });

  void _go(BuildContext context, String route) {
    final current = ModalRoute.of(context)?.settings.name;

    if (current == route) return;

    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.05,
            colors: [
              Color(0xFF1E1B4B),
              Color(0xFF07162C),
              Color(0xFF030816),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 270,
              margin: const EdgeInsets.all(18),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.sidebar.withOpacity(0.94),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.24),
                    blurRadius: 28,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'LumaPlay',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Painel Administrativo',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 34),
                  _SidebarItem(
                    selected: selectedIndex == 0,
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    onTap: () => _go(context, '/dashboard'),
                  ),
                  _SidebarItem(
                    selected: selectedIndex == 1,
                    icon: Icons.people_alt_rounded,
                    title: 'Usuários',
                    onTap: () => _go(context, '/users'),
                  ),
                  _SidebarItem(
                    selected: selectedIndex == 2,
                    icon: Icons.playlist_play_rounded,
                    title: 'Playlists',
                    onTap: () => _go(context, '/playlists'),
                  ),
                  _SidebarItem(
                    selected: selectedIndex == 3,
                    icon: Icons.settings_rounded,
                    title: 'Configurações',
                    onTap: () => _go(context, '/settings'),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary,
                          child: Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Felipe Admin',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Administrador',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/');
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sair'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.10),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 28,
                  right: 28,
                  bottom: 28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      title: title,
                      subtitle: subtitle,
                    ),
                    const SizedBox(height: 22),
                    Expanded(child: child),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;

  const _Header({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.cloud_done_rounded,
                color: AppColors.success,
                size: 19,
              ),
              SizedBox(width: 8),
              Text(
                'Sistema online',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.selected,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.secondary,
                      ],
                    )
                  : null,
              color: selected ? null : Colors.white.withOpacity(0.045),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? Colors.white.withOpacity(0.10)
                    : Colors.white.withOpacity(0.04),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 19,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
