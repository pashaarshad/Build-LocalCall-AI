import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/call_assistant_provider.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LocalCallApp());
}

class LocalCallApp extends StatelessWidget {
  const LocalCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CallAssistantProvider()),
      ],
      child: MaterialApp(
        title: 'LocalCall AI Assistant',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0A0F1D),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6366F1),
            secondary: Color(0xFF06B6D4),
            surface: Color(0xFF131B2E),
          ),
          fontFamily: 'Roboto',
          useMaterial3: true,
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}
