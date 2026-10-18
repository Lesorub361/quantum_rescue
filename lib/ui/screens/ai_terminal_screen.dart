import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/terminal_agent_service.dart';
import '../theme.dart';

class AiTerminalScreen extends ConsumerStatefulWidget {
  const AiTerminalScreen({super.key});

  @override
  ConsumerState<AiTerminalScreen> createState() => _AiTerminalScreenState();
}

class _AiTerminalScreenState extends ConsumerState<AiTerminalScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAiMode = true;

  void _submit() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    final notifier = ref.read(terminalAgentProvider.notifier);

    if (_isAiMode) {
      notifier.askAgent(text);
    } else {
      notifier.executeCommand(text);
    }

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final terminalState = ref.watch(terminalAgentProvider);
    final terminalNotifier = ref.read(terminalAgentProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.bot, color: QuantumRescueTheme.accentNeon, size: 20),
            const SizedBox(width: 8),
            Text('AI Terminal & Agent', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash, size: 18, color: Colors.white54),
            tooltip: 'Очистить терминал',
            onPressed: () => terminalNotifier.clearTerminal(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Mode Switch Bar ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: QuantumRescueTheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isAiMode = true),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: _isAiMode ? QuantumRescueTheme.accentNeon.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isAiMode ? QuantumRescueTheme.accentNeon : Colors.transparent,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.sparkles, size: 14, color: _isAiMode ? QuantumRescueTheme.accentNeon : Colors.white38),
                          const SizedBox(width: 6),
                          Text(
                            'ИИ-Агент (Автономный)',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _isAiMode ? QuantumRescueTheme.accentNeon : Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _isAiMode = false),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: !_isAiMode ? QuantumRescueTheme.primaryCyan.withValues(alpha: 0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: !_isAiMode ? QuantumRescueTheme.primaryCyan : Colors.transparent,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.terminal, size: 14, color: !_isAiMode ? QuantumRescueTheme.primaryCyan : Colors.white38),
                          const SizedBox(width: 6),
                          Text(
                            'Прямой Shell / Fastboot',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: !_isAiMode ? QuantumRescueTheme.primaryCyan : Colors.white60,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_isAiMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: QuantumRescueTheme.card,
              child: Row(
                children: [
                  Icon(
                    terminalState.isOpenCodeInstalled ? LucideIcons.circle_check : LucideIcons.circle_alert,
                    size: 13,
                    color: terminalState.isOpenCodeInstalled ? QuantumRescueTheme.accentNeon : Colors.amberAccent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      terminalState.isOpenCodeInstalled
                          ? 'OpenCode CLI активен (anomalyco/opencode)'
                          : 'OpenCode CLI не найден в системе',
                      style: GoogleFonts.inter(fontSize: 10.5, color: Colors.white70),
                    ),
                  ),
                  if (!terminalState.isOpenCodeInstalled)
                    TextButton.icon(
                      onPressed: () => terminalNotifier.installOpenCode(),
                      icon: const Icon(LucideIcons.download, size: 12, color: QuantumRescueTheme.accentNeon),
                      label: const Text('Установить OpenCode', style: TextStyle(fontSize: 10, color: QuantumRescueTheme.accentNeon, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      ),
                    ),
                ],
              ),
            ),

          // ── Messages / Terminal View ───────────────────────────────────────
          Expanded(
            child: Container(
              color: const Color(0xFF070911),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: terminalState.messages.length,
                itemBuilder: (context, i) {
                  final msg = terminalState.messages[i];
                  return _buildMessageTile(msg);
                },
              ),
            ),
          ),

          if (terminalState.isAgentThinking || terminalState.isExecuting)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: QuantumRescueTheme.surface,
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: QuantumRescueTheme.accentNeon),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    terminalState.isExecuting ? 'ИИ-Агент выполняет команды в терминале...' : 'ИИ-Агент формирует план действий...',
                    style: GoogleFonts.inter(fontSize: 11, color: QuantumRescueTheme.accentNeon),
                  ),
                ],
              ),
            ),

          // ── Quick Command Pills ───────────────────────────────────────────
          Container(
            height: 38,
            color: QuantumRescueTheme.surface,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _quickPill('fastboot devices', () => terminalNotifier.executeCommand('fastboot devices')),
                _quickPill('adb devices', () => terminalNotifier.executeCommand('adb devices')),
                _quickPill('fastboot getvar all', () => terminalNotifier.executeCommand('fastboot getvar all')),
                _quickPill('adb shell getprop', () => terminalNotifier.executeCommand('adb shell getprop ro.product.model')),
                _quickPill('fastboot reboot', () => terminalNotifier.executeCommand('fastboot reboot')),
                _quickPill('fastboot -w', () => terminalNotifier.executeCommand('fastboot -w')),
              ],
            ),
          ),

          // ── Prompt Input Bar ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: QuantumRescueTheme.card,
              border: Border(top: BorderSide(color: QuantumRescueTheme.cardBorder)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: _isAiMode
                            ? 'Напишите задачу ИИ-Агенту (например: "удали мусор Xiaomi")...'
                            : 'Введите команду fastboot или adb...',
                        hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 12),
                        filled: true,
                        fillColor: QuantumRescueTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: QuantumRescueTheme.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: QuantumRescueTheme.cardBorder),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      _isAiMode ? LucideIcons.sparkles : LucideIcons.send,
                      color: _isAiMode ? QuantumRescueTheme.accentNeon : QuantumRescueTheme.primaryCyan,
                    ),
                    onPressed: _submit,
                    style: IconButton.styleFrom(
                      backgroundColor: QuantumRescueTheme.surface,
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: QuantumRescueTheme.cardBorder),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTile(TerminalMessage msg) {
    if (msg.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: QuantumRescueTheme.primaryCyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: QuantumRescueTheme.primaryCyan.withValues(alpha: 0.4)),
            ),
            child: Text(
              msg.text,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
            ),
          ),
        ),
      );
    }

    if (msg.isAgent) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: QuantumRescueTheme.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: QuantumRescueTheme.accentNeon.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.bot, size: 14, color: QuantumRescueTheme.accentNeon),
                  const SizedBox(width: 6),
                  Text(
                    'QUANTUM AI AGENT',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: QuantumRescueTheme.accentNeon,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                msg.text,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.9), height: 1.4),
              ),
            ],
          ),
        ),
      );
    }

    if (msg.isCommand) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          msg.text,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            color: QuantumRescueTheme.primaryCyan,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Default terminal output
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        msg.text,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10.5,
          color: Colors.white70,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _quickPill(String cmd, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6, top: 4, bottom: 4),
      child: ActionChip(
        label: Text(cmd, style: GoogleFonts.jetBrainsMono(fontSize: 10, color: Colors.white70)),
        backgroundColor: QuantumRescueTheme.card,
        side: const BorderSide(color: QuantumRescueTheme.cardBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onPressed: onTap,
      ),
    );
  }
}
