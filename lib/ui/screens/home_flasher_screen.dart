import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/device_info.dart';
import '../../services/fastboot_adb_service.dart';
import '../../services/root_engine_service.dart';
import '../theme.dart';

class HomeFlasherScreen extends ConsumerStatefulWidget {
  const HomeFlasherScreen({super.key});

  @override
  ConsumerState<HomeFlasherScreen> createState() => _HomeFlasherScreenState();
}

class _HomeFlasherScreenState extends ConsumerState<HomeFlasherScreen> {
  String _selectedPartition = 'boot';
  String? _selectedFilePath;
  bool _disableVerity = false;

  final List<String> _partitions = [
    'boot',
    'init_boot',
    'recovery',
    'super',
    'vbmeta',
    'dtbo',
    'cust',
    'userdata',
  ];

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['img', 'bin', 'elf', 'zip'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
      });
    }
  }

  void _showRebootSheet(BuildContext context, FastbootAdbNotifier notifier) {
    showModalBottomSheet(
      context: context,
      backgroundColor: QuantumRescueTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Перезагрузка устройства',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 14),
            _rebootOption(ctx, notifier, 'system', 'В систему (Android)', LucideIcons.smartphone),
            _rebootOption(ctx, notifier, 'recovery', 'В Recovery (TWRP / OrangeFox)', LucideIcons.shield_alert),
            _rebootOption(ctx, notifier, 'bootloader', 'В Fastboot (Bootloader)', LucideIcons.zap),
            _rebootOption(ctx, notifier, 'fastbootd', 'В Fastbootd (Dynamic Partitions)', LucideIcons.layers),
            _rebootOption(ctx, notifier, 'edl', 'В аварийный режим EDL (Qualcomm 9008)', LucideIcons.triangle_alert),
          ],
        ),
      ),
    );
  }

  Widget _rebootOption(BuildContext ctx, FastbootAdbNotifier notifier, String target, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: QuantumRescueTheme.primaryCyan, size: 20),
      title: Text(title, style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
      onTap: () {
        Navigator.pop(ctx);
        notifier.reboot(target);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fbState = ref.watch(fastbootAdbProvider);
    final fbNotifier = ref.read(fastbootAdbProvider.notifier);
    final rootNotifier = ref.read(rootEngineProvider.notifier);
    final device = fbState.device;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.zap, color: QuantumRescueTheme.primaryCyan, size: 20),
            const SizedBox(width: 8),
            Text(
              'QuantumRescue',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: fbState.isScanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: QuantumRescueTheme.primaryCyan),
                  )
                : const Icon(LucideIcons.refresh_cw, size: 18, color: QuantumRescueTheme.primaryCyan),
            tooltip: 'Поиск подключенных устройств',
            onPressed: () => fbNotifier.scanDevices(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Device Status Banner ──────────────────────────────────────────
          _buildDeviceStatusCard(device, fbNotifier),

          const SizedBox(height: 16),

          // ── Quick Action Bar ──────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _quickActionChip(
                  icon: LucideIcons.shield_check,
                  label: '1-Клик Root',
                  color: QuantumRescueTheme.accentNeon,
                  onTap: () async {
                    if (_selectedFilePath == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Сначала выберите файл boot.img прошивки ниже!'),
                          backgroundColor: QuantumRescueTheme.warningOrange,
                        ),
                      );
                      return;
                    }
                    final patched = await rootNotifier.prepareRootImage(_selectedFilePath!);
                    if (patched != null) {
                      await fbNotifier.flashPartition('boot', patched);
                    }
                  },
                ),
                const SizedBox(width: 8),
                _quickActionChip(
                  icon: LucideIcons.rotate_cw,
                  label: 'Перезагрузка...',
                  color: QuantumRescueTheme.primaryCyan,
                  onTap: () => _showRebootSheet(context, fbNotifier),
                ),
                const SizedBox(width: 8),
                _quickActionChip(
                  icon: LucideIcons.trash,
                  label: 'Очистить Data (-w)',
                  color: QuantumRescueTheme.dangerRed,
                  onTap: () {
                    fbNotifier.executeRaw('fastboot -w');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── Flashing Studio Card ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: QuantumRescueTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: QuantumRescueTheme.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'СТУДИЯ ПРОШИВКИ РАЗДЕЛОВ',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: Colors.white54,
                      ),
                    ),
                    const Icon(LucideIcons.hard_drive, size: 16, color: QuantumRescueTheme.primaryCyan),
                  ],
                ),
                const SizedBox(height: 14),

                // Partition Selector
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('РАЗДЕЛ:', style: GoogleFonts.inter(fontSize: 10, color: Colors.white38)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: QuantumRescueTheme.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: QuantumRescueTheme.cardBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedPartition,
                                isExpanded: true,
                                dropdownColor: QuantumRescueTheme.surface,
                                style: GoogleFonts.jetBrainsMono(fontSize: 13, color: QuantumRescueTheme.primaryCyan, fontWeight: FontWeight.bold),
                                items: _partitions.map((p) {
                                  return DropdownMenuItem(
                                    value: p,
                                    child: Text(p),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedPartition = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ФАЙЛ ОБРАЗА (.IMG):', style: GoogleFonts.inter(fontSize: 10, color: Colors.white38)),
                          const SizedBox(height: 4),
                          OutlinedButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(LucideIcons.folder_open, size: 15, color: Colors.white70),
                            label: Text(
                              _selectedFilePath != null
                                  ? _selectedFilePath!.split('/').last
                                  : 'Выбрать файл...',
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: QuantumRescueTheme.cardBorder),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              backgroundColor: QuantumRescueTheme.surface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Checkbox: Disable Verity
                if (_selectedPartition == 'vbmeta')
                  Row(
                    children: [
                      Checkbox(
                        value: _disableVerity,
                        activeColor: QuantumRescueTheme.primaryCyan,
                        onChanged: (val) => setState(() => _disableVerity = val ?? false),
                      ),
                      const Expanded(
                        child: Text(
                          'Отключить проверку целостности (--disable-verity --disable-verification)',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 14),

                // Flash & Boot Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (_selectedFilePath == null || fbState.isFlashing || !device.isConnected)
                            ? null
                            : () => fbNotifier.flashPartition(
                                  _selectedPartition,
                                  _selectedFilePath!,
                                  disableVerity: _disableVerity,
                                ),
                        icon: fbState.isFlashing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const Icon(LucideIcons.zap, size: 16),
                        label: Text(
                          fbState.isFlashing ? 'ПРОШИВКА...' : 'ПРОШИТЬ В РАЗДЕЛ',
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: QuantumRescueTheme.primaryCyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(LucideIcons.play, color: QuantumRescueTheme.accentNeon),
                      tooltip: 'Запустить временно без прошивки (fastboot boot)',
                      onPressed: (_selectedFilePath == null || !device.isConnected)
                          ? null
                          : () => fbNotifier.bootImage(_selectedFilePath!),
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
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ── Real-Time Console Card ────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.terminal, size: 13, color: QuantumRescueTheme.primaryCyan),
                        const SizedBox(width: 6),
                        Text(
                          'ЛОГИ FASTBOOT / ADB',
                          style: GoogleFonts.jetBrainsMono(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.trash, size: 13, color: Colors.white38),
                      tooltip: 'Очистить',
                      onPressed: () => fbNotifier.clearLogs(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  height: 120,
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06080F),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: fbState.consoleLogs.isEmpty
                      ? Center(
                          child: Text(
                            'Логи действий появятся здесь...',
                            style: GoogleFonts.jetBrainsMono(fontSize: 10, color: Colors.white24),
                          ),
                        )
                      : ListView.builder(
                          reverse: true,
                          itemCount: fbState.consoleLogs.length,
                          itemBuilder: (ctx, i) {
                            final idx = fbState.consoleLogs.length - 1 - i;
                            final line = fbState.consoleLogs[idx];
                            final isSuccess = line.contains('✅') || line.contains('OKAY');
                            final isErr = line.contains('❌') || line.contains('FAIL');

                            return Text(
                              line,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                color: isSuccess
                                    ? QuantumRescueTheme.successGreen
                                    : isErr
                                        ? QuantumRescueTheme.dangerRed
                                        : Colors.white70,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceStatusCard(DeviceInfo device, FastbootAdbNotifier notifier) {
    final isConn = device.isConnected;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QuantumRescueTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConn ? QuantumRescueTheme.primaryCyan.withValues(alpha: 0.4) : QuantumRescueTheme.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isConn
                      ? QuantumRescueTheme.primaryCyan.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isConn ? LucideIcons.smartphone : LucideIcons.smartphone_charging,
                  color: isConn ? QuantumRescueTheme.primaryCyan : Colors.white38,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isConn ? 'Серийный номер: ${device.serial}' : 'Подключите телефон по USB в режиме Fastboot',
                      style: GoogleFonts.jetBrainsMono(fontSize: 11, color: Colors.white54),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isConn ? QuantumRescueTheme.successGreen.withValues(alpha: 0.2) : Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isConn ? QuantumRescueTheme.successGreen : Colors.white24,
                    width: 0.8,
                  ),
                ),
                child: Text(
                  device.modeLabel,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isConn ? QuantumRescueTheme.successGreen : Colors.white54,
                  ),
                ),
              ),
            ],
          ),
          if (isConn) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _badge(
                  device.isUnlocked ? LucideIcons.lock_keyhole_open : LucideIcons.lock,
                  device.isUnlocked ? 'ЗАГРУЗЧИК РАЗБЛОКИРОВАН' : 'ЗАБЛОКИРОВАН',
                  device.isUnlocked ? QuantumRescueTheme.successGreen : QuantumRescueTheme.dangerRed,
                ),
                if (device.currentSlot != null)
                  _badge(LucideIcons.split, 'СЛОТ ${device.currentSlot!.toUpperCase()}', QuantumRescueTheme.accentNeon),
                if (device.antiRollback != null)
                  _badge(LucideIcons.shield, 'ARB: ${device.antiRollback}', QuantumRescueTheme.warningOrange),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.jetBrainsMono(fontSize: 9, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _quickActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
