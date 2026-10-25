import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/chat_screen.dart';
import 'services/database_helper.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service & SQLite database
  final storageService = await StorageService.init();
  final dbHelper = DatabaseHelper();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(storageService),
        ),
        ChangeNotifierProxyProvider<SettingsProvider, ChatProvider>(
          create: (ctx) => ChatProvider(
            storageService,
            ctx.read<SettingsProvider>(),
            dbHelper,
          ),
          update: (ctx, settings, previous) =>
              previous ?? ChatProvider(storageService, settings, dbHelper),
        ),
      ],
      child: const LocalAIChatApp(),
    ),
  );
}

class LocalAIChatApp extends StatelessWidget {
  const LocalAIChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryAccent = Color(0xFF0077B6);

    return MaterialApp(
      title: 'LocalCall AI',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryAccent,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryAccent,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      home: const ChatScreen(),
    );
  }
}
