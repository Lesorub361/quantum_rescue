import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/fastboot_adb_service.dart';
import '../../services/root_engine_service.dart';
import '../theme.dart';

class DebloaterScreen extends ConsumerStatefulWidget {
  const DebloaterScreen({super.key});

  @override
  ConsumerState<DebloaterScreen> createState() => _DebloaterScreenState();
}

class _DebloaterScreenState extends ConsumerState<DebloaterScreen> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final rootState = ref.watch(rootEngineProvider);
    final rootNotifier = ref.read(rootEngineProvider.notifier);
    final fbState = ref.watch(fastbootAdbProvider);

    final filteredList = _selectedCategory == 'all'
        ? rootState.bloatwareList
        : rootState.bloatwareList.where((i) => i.category == _selectedCategory).toList();

    final selectedCount = rootState.bloatwareList.where((i) => i.isSelected).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.sparkles, color: QuantumRescueTheme.accentNeon, size: 20),
            const SizedBox(width: 8),
            Text('Debloat & Оптимизация', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.check_check, size: 18, color: QuantumRescueTheme.primaryCyan),
            tooltip: 'Выбрать все',
            onPressed: () => rootNotifier.selectAll(true),
          ),
          IconButton(
            icon: const Icon(LucideIcons.x, size: 18, color: Colors.white54),
            tooltip: 'Снять выбор',
            onPressed: () => rootNotifier.selectAll(false),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Safe Info Banner ───────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: QuantumRescueTheme.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: QuantumRescueTheme.accentNeon.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.shield_check, color: QuantumRescueTheme.accentNeon, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Безопасное удаление через ADB',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Пакеты отключаются только для пользователя 0 (--user 0). Телефон не окирпичится, обновления продолжат приходить.',
                        style: TextStyle(fontSize: 10, color: Colors.white60),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Category Filters ──────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _categoryChip('all', 'Все (${rootState.bloatwareList.length})'),
                const SizedBox(width: 6),
                _categoryChip('ads', 'Реклама и спам'),
                const SizedBox(width: 6),
                _categoryChip('telemetry', 'Слежка и логи'),
                const SizedBox(width: 6),
                _categoryChip('apps', 'Предустановленный софт'),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Bloatware Items List ──────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              itemCount: filteredList.length,
              itemBuilder: (context, i) {
                final item = filteredList[i];
                final originalIndex = rootState.bloatwareList.indexOf(item);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: QuantumRescueTheme.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: item.isSelected
                          ? QuantumRescueTheme.accentNeon.withValues(alpha: 0.4)
                          : QuantumRescueTheme.cardBorder,
                    ),
                  ),
                  child: CheckboxListTile(
                    value: item.isSelected,
                    activeColor: QuantumRescueTheme.accentNeon,
                    checkColor: Colors.black,
                    onChanged: (_) => rootNotifier.toggleItem(originalIndex),
                    title: Text(
                      item.name,
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Text(
                          item.packageName,
                          style: GoogleFonts.jetBrainsMono(fontSize: 10, color: Colors.white54),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: const TextStyle(fontSize: 10, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Bottom Action Button ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: QuantumRescueTheme.card,
              border: Border(top: BorderSide(color: QuantumRescueTheme.cardBorder)),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (selectedCount == 0 || rootState.isDebloating || !fbState.device.isConnected)
                      ? null
                      : () => rootNotifier.debloatSelected(),
                  icon: rootState.isDebloating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(LucideIcons.sparkles, size: 16),
                  label: Text(
                    rootState.isDebloating
                        ? 'ОЧИСТКА СИСТЕМЫ...'
                        : 'УДАЛИТЬ ВЫБРАННОЕ ($selectedCount)',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: QuantumRescueTheme.accentNeon,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String key, String label) {
    final isSel = _selectedCategory == key;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSel,
      selectedColor: QuantumRescueTheme.accentNeon,
      labelStyle: TextStyle(
        color: isSel ? Colors.black : Colors.white70,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: QuantumRescueTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(color: isSel ? QuantumRescueTheme.accentNeon : QuantumRescueTheme.cardBorder),
      onSelected: (_) => setState(() => _selectedCategory = key),
    );
  }
}
