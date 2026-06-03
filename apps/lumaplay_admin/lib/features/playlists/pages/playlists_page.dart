import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/admin_shell.dart';
import '../models/playlist_model.dart';

class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({super.key});

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistItem {
  final String id;
  final String name;
  final String user;
  final String customerId;
  final String url;
  final String status;
  final bool active;

  const _PlaylistItem({
    required this.id,
    required this.name,
    required this.user,
    required this.customerId,
    required this.url,
    required this.status,
    required this.active,
  });

  factory _PlaylistItem.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'];

    String username = 'Sem usuário';
    String customerId = '';

    if (customer is Map<String, dynamic>) {
      username = customer['username']?.toString() ?? 'Sem usuário';
      customerId = customer['id']?.toString() ?? '';
    }

    final active = json['active'] != false;

    return _PlaylistItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      user: username,
      customerId: customerId,
      url: json['m3uUrl']?.toString() ?? '',
      status: active ? 'Ativa' : 'Inativa',
      active: active,
    );
  }

  PlaylistModel toModel() {
    return PlaylistModel(
      name: name,
      user: user,
      url: url,
      status: status,
    );
  }
}

class _CustomerOption {
  final String id;
  final String name;
  final String username;

  const _CustomerOption({
    required this.id,
    required this.name,
    required this.username,
  });

  factory _CustomerOption.fromJson(Map<String, dynamic> json) {
    return _CustomerOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
    );
  }

  String get label {
    if (name.isEmpty) return username;
    return '$name ($username)';
  }
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  bool loading = true;
  bool saving = false;
  bool error = false;

  List<_PlaylistItem> playlists = [];
  List<_PlaylistItem> filteredPlaylists = [];
  List<_CustomerOption> customers = [];

  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    loadData();

    searchController.addListener(filterPlaylists);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      final responses = await Future.wait([
        ApiClient.dio.get('/playlists'),
        ApiClient.dio.get('/customers'),
      ]);

      final playlistsData = responses[0].data;
      final customersData = responses[1].data;

      final playlistList = playlistsData is List
          ? playlistsData
              .whereType<Map<String, dynamic>>()
              .map(_PlaylistItem.fromJson)
              .toList()
          : <_PlaylistItem>[];

      final customerList = customersData is List
          ? customersData
              .whereType<Map<String, dynamic>>()
              .map(_CustomerOption.fromJson)
              .toList()
          : <_CustomerOption>[];

      if (!mounted) return;

      setState(() {
        playlists = playlistList;
        filteredPlaylists = playlistList;
        customers = customerList;
        loading = false;
        error = false;
      });

      filterPlaylists();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = true;
      });
    }
  }

  void filterPlaylists() {
    final query = searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        filteredPlaylists = playlists;
      });

      return;
    }

    setState(() {
      filteredPlaylists = playlists.where((playlist) {
        return playlist.name.toLowerCase().contains(query) ||
            playlist.user.toLowerCase().contains(query) ||
            playlist.url.toLowerCase().contains(query) ||
            playlist.status.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> createPlaylist({
    required String name,
    required String m3uUrl,
    required String customerId,
  }) async {
    setState(() {
      saving = true;
    });

    try {
      await ApiClient.dio.post(
        '/playlists',
        data: {
          'name': name,
          'm3uUrl': m3uUrl,
          'customerId': customerId,
        },
      );

      if (!mounted) return;

      Navigator.pop(context);

      await loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Playlist criada com sucesso.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao criar playlist. Verifique os dados.'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        saving = false;
      });
    }
  }

  Future<void> updatePlaylist({
    required String id,
    required String name,
    required String m3uUrl,
    required String customerId,
  }) async {
    setState(() {
      saving = true;
    });

    try {
      await ApiClient.dio.patch(
        '/playlists/$id',
        data: {
          'name': name,
          'm3uUrl': m3uUrl,
          'customerId': customerId,
        },
      );

      if (!mounted) return;

      Navigator.pop(context);

      await loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Playlist atualizada com sucesso.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao atualizar playlist.'),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        saving = false;
      });
    }
  }

  Future<void> togglePlaylist(_PlaylistItem playlist) async {
    try {
      await ApiClient.dio.patch('/playlists/${playlist.id}/toggle');

      await loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            playlist.active ? 'Playlist inativada.' : 'Playlist ativada.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao alterar status da playlist.'),
        ),
      );
    }
  }

  Future<void> deletePlaylist(_PlaylistItem playlist) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Excluir playlist',
            style: TextStyle(
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'Tem certeza que deseja excluir "${playlist.name}"?',
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
      await ApiClient.dio.delete('/playlists/${playlist.id}');

      await loadData();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Playlist excluída com sucesso.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erro ao excluir playlist.'),
        ),
      );
    }
  }

  void _showNewPlaylistDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return _PlaylistDialog(
          customers: customers,
          saving: saving,
          onSave: createPlaylist,
        );
      },
    );
  }

  void _showEditPlaylistDialog(_PlaylistItem playlist) {
    showDialog(
      context: context,
      builder: (_) {
        return _PlaylistDialog(
          customers: customers,
          saving: saving,
          playlist: playlist,
          onSave: ({
            required String name,
            required String m3uUrl,
            required String customerId,
          }) {
            return updatePlaylist(
              id: playlist.id,
              name: name,
              m3uUrl: m3uUrl,
              customerId: customerId,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      selectedIndex: 2,
      title: 'Playlists',
      subtitle: 'Cadastre listas M3U e vincule cada lista a um usuário.',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar playlist por nome, usuário ou URL...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    fillColor: Colors.white.withOpacity(0.07),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _showNewPlaylistDialog,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nova playlist'),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: loadData,
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
                  const _PlaylistsHeader(),
                  Expanded(
                    child: _buildContent(),
                  ),
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
              'Não foi possível carregar as playlists.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: loadData,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (filteredPlaylists.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma playlist encontrada.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredPlaylists.length,
      separatorBuilder: (_, __) {
        return Divider(
          height: 1,
          color: Colors.white.withOpacity(0.06),
        );
      },
      itemBuilder: (context, index) {
        final item = filteredPlaylists[index];

        return _PlaylistRow(
          playlist: item.toModel(),
          onEdit: () => _showEditPlaylistDialog(item),
          onToggle: () => togglePlaylist(item),
          onDelete: () => deletePlaylist(item),
        );
      },
    );
  }
}

class _PlaylistsHeader extends StatelessWidget {
  const _PlaylistsHeader();

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
          Expanded(child: _HeaderText('Nome')),
          Expanded(child: _HeaderText('Usuário')),
          Expanded(flex: 2, child: _HeaderText('URL M3U')),
          Expanded(child: _HeaderText('Status')),
          SizedBox(width: 160, child: _HeaderText('Ações')),
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

class _PlaylistRow extends StatelessWidget {
  final PlaylistModel playlist;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _PlaylistRow({
    required this.playlist,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final active = playlist.status == 'Ativa';

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(
            child: Text(
              playlist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              playlist.user,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              playlist.url,
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
                  color: (active ? AppColors.success : AppColors.danger)
                      .withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  playlist.status,
                  style: TextStyle(
                    color: active ? AppColors.success : AppColors.danger,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 160,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Editar',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded),
                ),
                IconButton(
                  tooltip: active ? 'Inativar' : 'Ativar',
                  onPressed: onToggle,
                  icon: Icon(
                    active
                        ? Icons.toggle_on_rounded
                        : Icons.toggle_off_rounded,
                  ),
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

class _PlaylistDialog extends StatefulWidget {
  final bool saving;
  final List<_CustomerOption> customers;
  final _PlaylistItem? playlist;
  final Future<void> Function({
    required String name,
    required String m3uUrl,
    required String customerId,
  }) onSave;

  const _PlaylistDialog({
    required this.saving,
    required this.customers,
    required this.onSave,
    this.playlist,
  });

  @override
  State<_PlaylistDialog> createState() => _PlaylistDialogState();
}

class _PlaylistDialogState extends State<_PlaylistDialog> {
  final nameController = TextEditingController();
  final m3uUrlController = TextEditingController();

  String? selectedCustomerId;

  @override
  void initState() {
    super.initState();

    final playlist = widget.playlist;

    if (playlist != null) {
      nameController.text = playlist.name;
      m3uUrlController.text = playlist.url;
      selectedCustomerId = playlist.customerId;
    } else if (widget.customers.isNotEmpty) {
      selectedCustomerId = widget.customers.first.id;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    m3uUrlController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final name = nameController.text.trim();
    final m3uUrl = m3uUrlController.text.trim();

    if (name.isEmpty || m3uUrl.isEmpty || selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha nome, URL M3U e usuário.'),
        ),
      );

      return;
    }

    await widget.onSave(
      name: name,
      m3uUrl: m3uUrl,
      customerId: selectedCustomerId!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCustomers = widget.customers.isNotEmpty;
    final editing = widget.playlist != null;

    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: Text(
        editing ? 'Editar playlist' : 'Nova playlist',
        style: const TextStyle(
          fontWeight: FontWeight.w900,
        ),
      ),
      content: SizedBox(
        width: 540,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nome da playlist',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCustomerId,
              items: widget.customers.map((customer) {
                return DropdownMenuItem<String>(
                  value: customer.id,
                  child: Text(customer.label),
                );
              }).toList(),
              onChanged: hasCustomers
                  ? (value) {
                      setState(() {
                        selectedCustomerId = value;
                      });
                    }
                  : null,
              decoration: const InputDecoration(
                labelText: 'Usuário vinculado',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: m3uUrlController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'URL M3U',
              ),
            ),
            if (!hasCustomers) ...[
              const SizedBox(height: 14),
              const Text(
                'Crie um usuário antes de cadastrar uma playlist.',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.saving ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: widget.saving || !hasCustomers ? null : save,
          child: widget.saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(editing ? 'Salvar alterações' : 'Salvar'),
        ),
      ],
    );
  }
}
