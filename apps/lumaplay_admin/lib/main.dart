import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const LumaPlayAdmin());
}

class LumaPlayAdmin extends StatelessWidget {
  const LumaPlayAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LumaPlay Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      onGenerateRoute: AppRouter.generate,
      initialRoute: '/',
    );
  }
}
