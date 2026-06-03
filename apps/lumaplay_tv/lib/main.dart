import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations(
    const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ],
  );

  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );

  runApp(const LumaPlayApp());
}

class LumaPlayApp extends StatelessWidget {
  const LumaPlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'LumaPlay TV',
      routerConfig: appRouter,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'sans-serif',
        scaffoldBackgroundColor: const Color(0xFF030308),
      ),
    );
  }
}
