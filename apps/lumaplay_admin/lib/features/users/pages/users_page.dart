import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_shell.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _AdminUser {
  final String id;
  final String name;
  final String username;
  final String playlist;
  final String expiresAt;
  final String status;

  const _AdminUser({
    required this.id,
    required this.name,
    required this.username,
    required this.playlist,
    required this.expiresAt,
    required this.status,
  });

  factory _AdminUser.fromJson(Map<String, dynamic> json) {
    final playlists = json['playlists'];

    String playlistName = 'Sem playlist';

    if (playlists is List && playlists.isNotEmpty) {
      final firstPlaylist = playlists.first;

      if (firstPlaylist is Map<String, dynamic>) {
        playlistName = firstPlaylist['name']?.toString() ?? 'Sem playlist';
      }
    }

    return _AdminUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      playlist: playlistName,
      expiresAt: _formatExpiresAt(json['expiresAt']),
      status: _formatStatus(json['status']?.toString() ?? 'ACTIVE'),
    );
  }

  static String _formatStatus(String value) {
    if (value == 'ACTIVE') return 'Ativo';
    if (value == 'BLOCKED') return 'Bloqueado';
    if (value == 'EXPIRED') return 'Vencido';
    return value;
  }

  static String _formatExpiresAt(dynamic value) {
    if (value == null) return 'Sem validade';

    final parsed = DateTime.tryParse(value.toString());

    if (parsed == null) return value.toString();

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();

    return '$day/$month/$year';
  }
}

class _UsersPageState extends State<UsersPage> {
  bool loading = true;
  bool saving = false;
  bool error = false;

  List<_AdminUser> users = [];
  List<_AdminUser> filteredUsers = [];

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUsers();
    searchController.addListener(filterUsers);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadUsers() async {
    try {
      final response = await ApiClient.dio.get('/customers');
      final data = response.data;

      final list = data is List
          ? data
              .whereType<Map<String, dynamic>>()
              .map(_AdminUser.fromJson)
              .toList()
          : <_AdminUser>[];

      if (!mounted) return;

      setState(() {
        users = list;
        filteredUsers = list;
        loading = false;
        error = false;
      });

      filterUsers();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = true;
      });
    }
  }

  void filterUsers() {
    final query = searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        filteredUsers = users;
      });
      return;
    }

    setState(() {
      filteredUsers = users.where((user) {
        return user.name.toLowerCase().contains(query) ||
            user.username.toLowerCase().contains(query) ||
            user.playlist.toLowerCase().contains(query) ||
            user.status.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> createUser({
    required String name,
    required String username,
    required String password,
    required String expiresAt,
  }) async {
    setState(() {
      saving = true;
    });

    try {
      await ApiClient.dio.post(
        '/customers',
        data: {
          'name': name,
          'username': username,
          'password': password,
          'expiresAt': _parseBrazilianDate(expiresAt),
        },
      );

      if (!mounted) return;

      Navigator.pop(context);

      await loadUsers();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário criado com sucesso.')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao criar usuário. Talvez o login já exista.'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        saving = false;
      });
    }
  }

  Future<void> updateStatus(_AdminUser user, String status) async {
    try {
      await ApiClient.dio.patch(
        '/customers/${user.id}/status',
        data: {'status': status},
      );

      await loadUsers();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'ACTIVE'
                ? 'Usuário desbloqueado.'
                : status == 'BLOCKED'
                    ? 'Usuário bloqueado.'
                    : 'Usuário marcado como vencido.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao atualizar status.')),
      );
    }
  }

  Future<void> deleteUser(_AdminUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Excluir usuário',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Text(
            'Tem certeza que deseja excluir "\${user.name}"?\n\nAs playlists vinculadas também serão removidas.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await ApiClient.dio.delete('/customers/${user.id}');

      await loadUsers();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário excluído com sucesso.')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao excluir usuário.')),
      );
    }
  }

  String? _parseBrazilianDate(String value) {
    final clean = value.trim();

    if (clean.isEmpty) return null;

    final parts = clean.split('/');

    if (parts.length != 3) return clean;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) return clean;

    final date = DateTime(year, month, day);

    return date.toIso8601String();
  }

  void _showNewUserDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return _NewUserDialog(
          saving: saving,
          onSave: createUser,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      selectedIndex: 1,
      title: 'Usuários',
      subtitle: 'Crie clientes, defina validade e vincule playlists M3U.',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText:
                        'Buscar usuário por nome, login, playlist ou status...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    fillColor: Colors.white.withOpacity(0.07),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _showNewUserDialog,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Novo usuário'),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: loadUsers,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Atualizar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withOpacity(0.12),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.card.withOpacity(0.86),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
              child: Column(
                children: [
                  const _UsersHeader(),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
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
              'Não foi possível carregar os usuários.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: loadUsers,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (filteredUsers.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum usuário encontrado.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredUsers.length,
      separatorBuilder: (_, __) {
        return Divider(
          height: 1,
          color: Colors.white.withOpacity(0.06),
        );
      },
      itemBuilder: (context, index) {
        return _UserRow(
          user: filteredUsers[index],
          onBlock: () => updateStatus(filteredUsers[index], 'BLOCKED'),
          onUnblock: () => updateStatus(filteredUsers[index], 'ACTIVE'),
          onExpire: () => updateStatus(filteredUsers[index], 'EXPIRED'),
          onDelete: () => deleteUser(filteredUsers[index]),
        );
      },
    );
  }
}

class _UsersHeader extends StatelessWidget {
  const _UsersHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: const Row(
        children: [
          Expanded(flex: 2, child: _HeaderText('Nome')),
          Expanded(child: _HeaderText('Usuário')),
          Expanded(child: _HeaderText('Playlist')),
          Expanded(child: _HeaderText('Validade')),
          Expanded(child: _HeaderText('Status')),
          SizedBox(width: 205, child: _HeaderText('Ações')),
        ],
      ),
    );
  }
}

class _HeaderText extends StatelessWidget {
  final String text;

  const _HeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final _AdminUser user;
  final VoidCallback onBlock;
  final VoidCallback onUnblock;
  final VoidCallback onExpire;
  final VoidCallback onDelete;

  const _UserRow({
    required this.user,
    required this.onBlock,
    required this.onUnblock,
    required this.onExpire,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final active = user.status == 'Ativo';
    final blocked = user.status == 'Bloqueado';

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withOpacity(0.18),
                  child: Text(
                    user.name.isEmpty ? '?' : user.name.substring(0, 1),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              user.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              user.playlist,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              user.expiresAt,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (active
                          ? AppColors.success
                          : blocked
                              ? AppColors.danger
                              : AppColors.warning)
                      .withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  user.status,
                  style: TextStyle(
                    color: active
                        ? AppColors.success
                        : blocked
                            ? AppColors.danger
                            : AppColors.warning,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 205,
            child: Row(
              children: [
                IconButton(
                  tooltip: active ? 'Bloquear' : 'Desbloquear',
                  onPressed: active ? onBlock : onUnblock,
                  icon: Icon(
                    active
                        ? Icons.block_rounded
                        : Icons.check_circle_outline_rounded,
                  ),
                ),
                IconButton(
                  tooltip: 'Marcar como vencido',
                  onPressed: onExpire,
                  icon: const Icon(Icons.timer_off_rounded),
                ),
                IconButton(
                  tooltip: 'Excluir',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewUserDialog extends StatefulWidget {
  final bool saving;
  final Future<void> Function({
    required String name,
    required String username,
    required String password,
    required String expiresAt,
  }) onSave;

  const _NewUserDialog({
    required this.saving,
    required this.onSave,
  });

  @override
  State<_NewUserDialog> createState() => _NewUserDialogState();
}

class _NewUserDialogState extends State<_NewUserDialog> {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final expiresAtController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    expiresAtController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final name = nameController.text.trim();
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();
    final expiresAt = expiresAtController.text.trim();

    if (name.isEmpty || username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome, usuário e senha.')),
      );
      return;
    }

    await widget.onSave(
      name: name,
      username: username,
      password: password,
      expiresAt: expiresAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: const Text(
        'Novo usuário',
        style: TextStyle(fontWeight: FontWeight.w900),
      ),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do cliente',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Usuário',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Senha',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: expiresAtController,
              decoration: const InputDecoration(
                labelText: 'Validade',
                hintText: 'Ex: 30/06/2026',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: widget.saving ? null : save,
          child: widget.saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
