import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'data/app_store.dart';
import 'pages/home_router.dart';
import 'pages/opening.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStore.instance.init();
  runApp(const SipahalApp());
}

class SipahalApp extends StatelessWidget {
  const SipahalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AppStore.instance.currentUser;
    return MaterialApp(
      title: 'SIPAHAL',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: user == null ? const OpeningPage() : homeForUser(user),
    );
  }
}
