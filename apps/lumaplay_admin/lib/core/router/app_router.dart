import 'package:flutter/material.dart';

import '../../features/auth/pages/login_page.dart';
import '../../features/dashboard/pages/dashboard_page.dart';
import '../../features/playlists/pages/playlists_page.dart';
import '../../features/settings/pages/settings_page.dart';
import '../../features/users/pages/users_page.dart';

class AppRouter {
  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      case '/dashboard':
        return MaterialPageRoute(
          builder: (_) => const DashboardPage(),
        );

      case '/users':
        return MaterialPageRoute(
          builder: (_) => const UsersPage(),
        );

      case '/playlists':
        return MaterialPageRoute(
          builder: (_) => const PlaylistsPage(),
        );

      case '/settings':
        return MaterialPageRoute(
          builder: (_) => const SettingsPage(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
        );
    }
  }
}
