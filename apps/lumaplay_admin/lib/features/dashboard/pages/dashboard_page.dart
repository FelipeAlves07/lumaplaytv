import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_shell.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardData {
  final int users;
  final int playlists;
  final int activeUsers;
  final int blockedUsers;

  const _DashboardData({
    required this.users,
    required this.playlists,
    required this.activeUsers,
    required this.blockedUsers,
  });

  factory _DashboardData.fromJson(Map<String, dynamic> json) {
    return _DashboardData(
      users: json['users'] ?? 0,
      playlists: json['playlists'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      blockedUsers: json['blockedUsers'] ?? 0,
    );
  }
}

class _DashboardPageState extends State<DashboardPage> {
  bool loading = true;
  bool error = false;

  _DashboardData data = const _DashboardData(
    users: 0,
    playlists: 0,
    activeUsers: 0,
    blockedUsers: 0,
  );

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    try {
      final response = await ApiClient.dio.get('/dashboard');

      setState(() {
        data = _DashboardData.fromJson(response.data);
        loading = false;
        error = false;
      });
    } catch (_) {
      setState(() {
        loading = false;
        error = true;
      });
    }
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentActivity() {
    final items = const [
      ['API conectada', 'Dashboard usando dados reais'],
      ['Banco local ativo', 'SQLite + Prisma'],
      ['Painel Admin online', 'Flutter Web'],
      ['App TV em breve', 'Login real será integrado'],
    ];

    return Container(
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
          const Text(
            'Atividades recentes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          ...items.map(
            (item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item[0],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item[1],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      selectedIndex: 0,
      title: 'Dashboard',
      subtitle: 'Visão geral dos usuários, playlists e acessos do LumaPlay.',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;

          if (loading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (error) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    color: AppColors.danger,
                    size: 54,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Não foi possível carregar o dashboard.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: loadDashboard,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: compact ? 2 : 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: compact ? 2.6 : 2.15,
                  children: [
                    _statCard(
                      title: 'Usuários',
                      value: data.users.toString(),
                      icon: Icons.people_alt_rounded,
                      color: AppColors.primary,
                    ),
                    _statCard(
                      title: 'Playlists',
                      value: data.playlists.toString(),
                      icon: Icons.playlist_play_rounded,
                      color: AppColors.secondary,
                    ),
                    _statCard(
                      title: 'Ativos',
                      value: data.activeUsers.toString(),
                      icon: Icons.verified_rounded,
                      color: AppColors.success,
                    ),
                    _statCard(
                      title: 'Bloqueados',
                      value: data.blockedUsers.toString(),
                      icon: Icons.block_rounded,
                      color: AppColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (compact)
                  Column(
                    children: [
                      const _SystemSummaryCard(),
                      const SizedBox(height: 18),
                      _recentActivity(),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        flex: 2,
                        child: _SystemSummaryCard(),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _recentActivity(),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SystemSummaryCard extends StatelessWidget {
  const _SystemSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 290,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card.withOpacity(0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo do sistema',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Painel conectado à API real do LumaPlay. Os números acima vêm diretamente do backend local.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          Spacer(),
          _DashboardNote(
            icon: Icons.storage_rounded,
            title: 'Backend conectado',
            subtitle: 'Express + Prisma + SQLite rodando em localhost:4000.',
          ),
        ],
      ),
    );
  }
}

class _DashboardNote extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _DashboardNote({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}