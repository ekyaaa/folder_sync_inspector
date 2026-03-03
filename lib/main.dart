import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/theme.dart';
import 'shared/providers/theme_provider.dart';
import 'home_page.dart';

void main() {
  runApp(const ProviderScope(child: FolderSyncInspectorApp()));
}

class FolderSyncInspectorApp extends ConsumerWidget {
  const FolderSyncInspectorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Folder Sync Inspector',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const HomePage(),
    );
  }
}
