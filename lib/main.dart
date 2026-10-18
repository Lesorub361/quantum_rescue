import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ui/theme.dart';
import 'ui/screens/home_flasher_screen.dart';
import 'ui/screens/ai_terminal_screen.dart';
import 'ui/screens/debloater_screen.dart';
import 'ui/screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: QuantumRescueApp(),
    ),
  );
}

class QuantumRescueApp extends StatelessWidget {
  const QuantumRescueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuantumRescue',
      debugShowCheckedModeBanner: false,
      theme: QuantumRescueTheme.darkTheme,
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeFlasherScreen(),
    AiTerminalScreen(),
    DebloaterScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: QuantumRescueTheme.surface,
        indicatorColor: QuantumRescueTheme.primaryCyan.withValues(alpha: 0.18),
        destinations: const [
          NavigationDestination(
            icon: Icon(LucideIcons.zap, size: 20),
            selectedIcon: Icon(LucideIcons.zap, size: 20, color: QuantumRescueTheme.primaryCyan),
            label: 'Прошивка',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.bot, size: 20),
            selectedIcon: Icon(LucideIcons.bot, size: 20, color: QuantumRescueTheme.accentNeon),
            label: 'ИИ-Терминал',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.sparkles, size: 20),
            selectedIcon: Icon(LucideIcons.sparkles, size: 20, color: QuantumRescueTheme.accentNeon),
            label: 'Debloat',
          ),
          NavigationDestination(
            icon: Icon(LucideIcons.settings, size: 20),
            selectedIcon: Icon(LucideIcons.settings, size: 20, color: QuantumRescueTheme.primaryCyan),
            label: 'Настройки',
          ),
        ],
      ),
    );
  }
}
