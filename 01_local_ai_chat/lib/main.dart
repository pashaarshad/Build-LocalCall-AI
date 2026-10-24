import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/chat_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/chat_screen.dart';
import 'services/ollama_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service
  final storageService = await StorageService.init();
  final ollamaService = OllamaService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(storageService, ollamaService),
        ),
        ChangeNotifierProxyProvider<SettingsProvider, ChatProvider>(
          create: (ctx) => ChatProvider(
            storageService,
            ctx.read<SettingsProvider>(),
          ),
          update: (ctx, settings, previous) =>
              previous ?? ChatProvider(storageService, settings),
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
    const primarySeed = Color(0xFF1E88E5); // Modern energetic blue

    return MaterialApp(
      title: 'Local AI Chat',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primarySeed,
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
          seedColor: primarySeed,
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
