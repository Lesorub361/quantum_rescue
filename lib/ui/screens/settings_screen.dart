import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/terminal_agent_service.dart';
import '../theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _fastbootPathController = TextEditingController();
  final TextEditingController _adbPathController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKeyController.text = prefs.getString('ai_api_key') ?? '';
      _fastbootPathController.text = prefs.getString('fastboot_path') ?? 'fastboot';
      _adbPathController.text = prefs.getString('adb_path') ?? 'adb';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_api_key', _apiKeyController.text.trim());
    await prefs.setString('fastboot_path', _fastbootPathController.text.trim());
    await prefs.setString('adb_path', _adbPathController.text.trim());

    ref.read(terminalAgentProvider.notifier).setApiKey(_apiKeyController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Настройки сохранены!'),
          backgroundColor: QuantumRescueTheme.successGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Настройки & Справка', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── AI Agent Settings ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: QuantumRescueTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: QuantumRescueTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.bot, color: QuantumRescueTheme.accentNeon, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Настройки ИИ-Агента',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Агент умеет работать офлайн по встроенным правилам. Если указать ключ Gemini API, агент сможет самостоятельно решать сложные и нестандартные ошибки прошивки.',
                  style: TextStyle(fontSize: 11, color: Colors.white60, height: 1.4),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _apiKeyController,
                  obscureText: true,
                  style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Gemini API Key (Опционально)',
                    labelStyle: const TextStyle(fontSize: 11, color: Colors.white54),
                    filled: true,
                    fillColor: QuantumRescueTheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Fastboot & ADB Binaries ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: QuantumRescueTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: QuantumRescueTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.terminal, color: QuantumRescueTheme.primaryCyan, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Пути к утилитам Fastboot и ADB',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _fastbootPathController,
                  style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Fastboot Binary Path',
                    labelStyle: const TextStyle(fontSize: 11, color: Colors.white54),
                    filled: true,
                    fillColor: QuantumRescueTheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _adbPathController,
                  style: GoogleFonts.jetBrainsMono(fontSize: 12, color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'ADB Binary Path',
                    labelStyle: const TextStyle(fontSize: 11, color: Colors.white54),
                    filled: true,
                    fillColor: QuantumRescueTheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: QuantumRescueTheme.primaryCyan,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Сохранить настройки', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Instructions & Guides ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: QuantumRescueTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: QuantumRescueTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.book_open, color: QuantumRescueTheme.warningOrange, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Инструкция: Вход в Fastboot',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _instructionStep(
                  '1',
                  'Выключите телефон Xiaomi/Redmi/POCO полностью.',
                ),
                _instructionStep(
                  '2',
                  'Зажмите одновременно «Громкость ВНИЗ (-)» и «Кнопку Питания».',
                ),
                _instructionStep(
                  '3',
                  'Удерживайте 6-10 секунд, пока на экране не появится оранжевая надпись FASTBOOT или заяц.',
                ),
                _instructionStep(
                  '4',
                  'Подключите телефон кабелем Type-C к ПК или через OTG-переходник к другому смартфону.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _instructionStep(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: QuantumRescueTheme.warningOrange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: QuantumRescueTheme.warningOrange, width: 0.8),
            ),
            child: Text(step, style: const TextStyle(fontSize: 10, color: QuantumRescueTheme.warningOrange, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 11, color: Colors.white70, height: 1.3)),
          ),
        ],
      ),
    );
  }
}
