import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class OpenZapApp extends StatelessWidget {
  const OpenZapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenZap',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
    );
  }
}
