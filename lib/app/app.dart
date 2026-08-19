import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../features/discovery/presentation/device_list_screen.dart';
import '../features/settings/domain/app_settings.dart';
import '../features/settings/presentation/settings_providers.dart';
import '../l10n/app_localizations.dart';

class OpenZapApp extends StatelessWidget {
  const OpenZapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ProviderScope(child: _AppRoot());
  }
}

class _AppRoot extends ConsumerWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull;
    final themeMode = switch (settings?.themeMode ?? AppThemeMode.system) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };
    final languageCode = settings?.languageCode;
    final useDynamicColor = settings?.dynamicColor ?? true;
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final light = useDynamicColor && lightDynamic != null
            ? AppTheme.build(lightDynamic)
            : AppTheme.light;
        final dark = useDynamicColor && darkDynamic != null
            ? AppTheme.build(darkDynamic)
            : AppTheme.dark;
        return MaterialApp(
          title: 'OpenZap',
          theme: light,
          darkTheme: dark,
          themeMode: themeMode,
          locale: languageCode == null ? null : Locale(languageCode),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DeviceListScreen(),
        );
      },
    );
  }
}
