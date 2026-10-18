import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device_info.dart';

class FastbootAdbState {
  final DeviceInfo device;
  final bool isScanning;
  final bool isFlashing;
  final double flashingProgress;
  final String statusMessage;
  final List<String> consoleLogs;
  final String fastbootPath;
  final String adbPath;

  const FastbootAdbState({
    required this.device,
    this.isScanning = false,
    this.isFlashing = false,
    this.flashingProgress = 0.0,
    this.statusMessage = 'Ожидание подключения устройства...',
    this.consoleLogs = const [],
    this.fastbootPath = 'fastboot',
    this.adbPath = 'adb',
  });

  FastbootAdbState copyWith({
    DeviceInfo? device,
    bool? isScanning,
    bool? isFlashing,
    double? flashingProgress,
    String? statusMessage,
    List<String>? consoleLogs,
    String? fastbootPath,
    String? adbPath,
  }) {
    return FastbootAdbState(
      device: device ?? this.device,
      isScanning: isScanning ?? this.isScanning,
      isFlashing: isFlashing ?? this.isFlashing,
      flashingProgress: flashingProgress ?? this.flashingProgress,
      statusMessage: statusMessage ?? this.statusMessage,
      consoleLogs: consoleLogs ?? this.consoleLogs,
      fastbootPath: fastbootPath ?? this.fastbootPath,
      adbPath: adbPath ?? this.adbPath,
    );
  }
}

class FastbootAdbNotifier extends StateNotifier<FastbootAdbState> {
  Timer? _pollingTimer;

  static const Map<String, String> _knownXiaomiCodenameMap = {
    'curtana': 'Redmi Note 9S / 9 Pro (Global)',
    'joyeuse': 'Redmi Note 9 Pro Max',
    'surya': 'POCO X3 NFC',
    'karna': 'POCO X3 (India)',
    'sweet': 'Redmi Note 10 Pro',
    'alioth': 'POCO F3 / Redmi K40',
    'vayu': 'POCO X3 Pro',
    'bhima': 'POCO X3 Pro (India)',
    'beryllium': 'POCO F1',
    'dipper': 'Xiaomi Mi 8',
    'polaris': 'Xiaomi Mi MIX 2S',
    'davinci': 'Xiaomi Mi 9T / Redmi K20',
    'raphael': 'Xiaomi Mi 9T Pro / Redmi K20 Pro',
    'cezanne': 'Redmi K30 Ultra',
    'lisa': 'Xiaomi 11 Lite 5G NE',
    'courbet': 'Xiaomi Mi 11 Lite 4G',
    'renoir': 'Xiaomi Mi 11 Lite 5G',
    'venus': 'Xiaomi Mi 11',
    'star': 'Xiaomi Mi 11 Pro / Ultra',
    'haydn': 'Xiaomi Mi 11i / Redmi K40 Pro',
    'zeus': 'Xiaomi 12 Pro',
    'cupid': 'Xiaomi 12',
    'psyche': 'Xiaomi 12X',
    'fuxi': 'Xiaomi 13',
    'nuwa': 'Xiaomi 13 Pro',
    'ishtar': 'Xiaomi 13 Ultra',
    'houji': 'Xiaomi 14',
    'shennong': 'Xiaomi 14 Pro',
    'aurora': 'Xiaomi 14 Ultra',
    'mido': 'Redmi Note 4X',
    'vince': 'Redmi 5 Plus',
    'whyred': 'Redmi Note 5 Pro',
    'tulip': 'Redmi Note 6 Pro',
    'lavender': 'Redmi Note 7',
    'ginkgo': 'Redmi Note 8',
    'begonia': 'Redmi Note 8 Pro',
  };

  FastbootAdbNotifier()
      : super(FastbootAdbState(device: DeviceInfo.disconnected())) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final fb = prefs.getString('fastboot_path') ?? 'fastboot';
    final adb = prefs.getString('adb_path') ?? 'adb';
    state = state.copyWith(fastbootPath: fb, adbPath: adb);

    startDevicePolling();
  }

  void startDevicePolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!state.isFlashing) {
        scanDevices();
      }
    });
    scanDevices();
  }

  void stopDevicePolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void appendLog(String log) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final formatted = '[$timestamp] $log';
    final updated = [...state.consoleLogs, formatted];
    if (updated.length > 300) {
      updated.removeRange(0, updated.length - 300);
    }
    state = state.copyWith(consoleLogs: updated);
  }

  void clearLogs() {
    state = state.copyWith(consoleLogs: []);
  }

  Future<void> scanDevices() async {
    // 1. Check Fastboot
    try {
      final fbResult = await Process.run(state.fastbootPath, ['devices']).timeout(
        const Duration(seconds: 3),
        onTimeout: () => ProcessResult(0, -1, '', 'timeout'),
      );

      if (fbResult.exitCode == 0 && (fbResult.stdout as String).trim().isNotEmpty) {
        final line = (fbResult.stdout as String).trim().split('\n').first;
        final parts = line.split(RegExp(r'\s+'));
        final serial = parts.first.trim();
        final modeStr = parts.length > 1 ? parts[1].toLowerCase() : 'fastboot';

        final isFastbootd = modeStr.contains('fastbootd');
        final mode = isFastbootd ? DeviceMode.fastbootd : DeviceMode.fastboot;

        // Query device parameters
        final info = await _queryFastbootInfo(serial, mode);
        state = state.copyWith(
          device: info,
          statusMessage: 'Подключено в режиме ${info.modeLabel}',
        );
        return;
      }
    } catch (_) {}

    // 2. Check ADB
    try {
      final adbResult = await Process.run(state.adbPath, ['devices']).timeout(
        const Duration(seconds: 3),
        onTimeout: () => ProcessResult(0, -1, '', 'timeout'),
      );

      if (adbResult.exitCode == 0) {
        final lines = (adbResult.stdout as String).split('\n');
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith('List of devices')) continue;
          final parts = trimmed.split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            final serial = parts[0];
            final status = parts[1];

            DeviceMode mode = DeviceMode.adb;
            if (status == 'recovery') mode = DeviceMode.recovery;
            if (status == 'sideload') mode = DeviceMode.recovery;

            final info = await _queryAdbInfo(serial, mode);
            state = state.copyWith(
              device: info,
              statusMessage: 'Подключено в режиме ${info.modeLabel}',
            );
            return;
          }
        }
      }
    } catch (_) {}

    if (state.device.isConnected) {
      appendLog('Устройство отключено.');
      state = state.copyWith(
        device: DeviceInfo.disconnected(),
        statusMessage: 'Устройство не обнаружено. Подключите телефон по USB.',
      );
    }
  }

  Future<DeviceInfo> _queryFastbootInfo(String serial, DeviceMode mode) async {
    final vars = <String, String>{};
    try {
      final res = await Process.run(state.fastbootPath, ['-s', serial, 'getvar', 'all']);
      // fastboot getvar all outputs to stderr or stdout depending on version
      final output = '${res.stdout}\n${res.stderr}';
      for (final line in output.split('\n')) {
        final match = RegExp(r'\((?:bootloader)\)\s+([a-zA-Z0-9_\-]+):\s*(.*)').firstMatch(line);
        if (match != null) {
          vars[match.group(1)!.trim()] = match.group(2)!.trim();
        }
      }
    } catch (_) {}

    final product = vars['product'] ?? '';
    final unlockedStr = vars['unlocked'] ?? vars['unlocked-token'] ?? '';
    final isUnlocked = unlockedStr.toLowerCase() == 'yes' || unlockedStr == 'true';
    final slot = vars['current-slot'] ?? vars['slot-current'];
    final anti = int.tryParse(vars['anti'] ?? '');
    final secureStr = vars['secure'] ?? '';
    final isSecure = secureStr.toLowerCase() == 'yes';

    String brand = 'Android';
    String readableProduct = product;
    if (_knownXiaomiCodenameMap.containsKey(product.toLowerCase())) {
      brand = 'Xiaomi / Redmi / POCO';
      readableProduct = _knownXiaomiCodenameMap[product.toLowerCase()]!;
    } else if (product.contains('pixel') || product.startsWith('redfin') || product.startsWith('cheetah')) {
      brand = 'Google Pixel';
    }

    return DeviceInfo(
      serial: serial,
      product: readableProduct,
      brand: brand,
      mode: mode,
      isUnlocked: isUnlocked,
      currentSlot: slot,
      antiRollback: anti,
      isSecure: isSecure,
      rawVars: vars,
    );
  }

  Future<DeviceInfo> _queryAdbInfo(String serial, DeviceMode mode) async {
    String model = '';
    String brand = '';
    try {
      final resModel = await Process.run(state.adbPath, ['-s', serial, 'shell', 'getprop', 'ro.product.model']);
      model = (resModel.stdout as String).trim();
      final resBrand = await Process.run(state.adbPath, ['-s', serial, 'shell', 'getprop', 'ro.product.brand']);
      brand = (resBrand.stdout as String).trim();
    } catch (_) {}

    return DeviceInfo(
      serial: serial,
      product: model.isNotEmpty ? model : 'Android Device',
      brand: brand.isNotEmpty ? brand.toUpperCase() : 'Android',
      mode: mode,
      isUnlocked: true,
    );
  }

  /// Flash an individual partition (e.g. boot, recovery, super, vbmeta)
  Future<bool> flashPartition(String partition, String filePath, {bool disableVerity = false}) async {
    if (!state.device.isConnected) {
      appendLog('❌ Ошибка: устройство не подключено!');
      return false;
    }

    state = state.copyWith(isFlashing: true, flashingProgress: 0.1);
    appendLog('⚡ Начало прошивки раздела [$partition] из файла: $filePath');

    try {
      final List<String> args = ['-s', state.device.serial];
      if (disableVerity && partition == 'vbmeta') {
        args.addAll(['--disable-verity', '--disable-verification', 'flash', partition, filePath]);
      } else {
        args.addAll(['flash', partition, filePath]);
      }

      state = state.copyWith(flashingProgress: 0.5);
      final process = await Process.start(state.fastbootPath, args);

      process.stdout.transform(utf8.decoder).listen((data) => appendLog(data.trim()));
      process.stderr.transform(utf8.decoder).listen((data) => appendLog(data.trim()));

      final exitCode = await process.exitCode;
      state = state.copyWith(isFlashing: false, flashingProgress: 1.0);

      if (exitCode == 0) {
        appendLog('✅ Раздел [$partition] успешно прошит!');
        return true;
      } else {
        appendLog('❌ Ошибка прошивки [$partition], код завершения: $exitCode');
        return false;
      }
    } catch (e) {
      state = state.copyWith(isFlashing: false);
      appendLog('❌ Исключение при прошивке: $e');
      return false;
    }
  }

  /// Boot temporary image without flashing (e.g. TWRP or patched boot)
  Future<bool> bootImage(String filePath) async {
    if (!state.device.isConnected) return false;
    appendLog('🚀 Запуск временного образа: $filePath (fastboot boot)');
    try {
      final res = await Process.run(state.fastbootPath, ['-s', state.device.serial, 'boot', filePath]);
      appendLog('${res.stdout}\n${res.stderr}');
      return res.exitCode == 0;
    } catch (e) {
      appendLog('❌ Ошибка загрузки образа: $e');
      return false;
    }
  }

  /// Reboot device
  Future<void> reboot(String target) async {
    if (!state.device.isConnected) return;
    appendLog('🔄 Перезагрузка устройства в: $target');

    if (state.device.mode == DeviceMode.fastboot || state.device.mode == DeviceMode.fastbootd) {
      String cmd = 'reboot';
      if (target == 'recovery') cmd = 'reboot-recovery';
      if (target == 'bootloader') cmd = 'reboot-bootloader';
      if (target == 'fastbootd') cmd = 'reboot-fastboot';
      if (target == 'edl') cmd = 'oem edl';

      await Process.run(state.fastbootPath, ['-s', state.device.serial, cmd]);
    } else {
      List<String> args = ['-s', state.device.serial, 'reboot'];
      if (target == 'recovery') args.add('recovery');
      if (target == 'bootloader') args.add('bootloader');
      if (target == 'fastbootd') args.add('fastboot');
      if (target == 'edl') args.add('edl');

      await Process.run(state.adbPath, args);
    }
    await Future.delayed(const Duration(seconds: 1));
    scanDevices();
  }

  /// Execute an arbitrary Fastboot or ADB command from Terminal
  Future<String> executeRaw(String command) async {
    final trimmed = command.trim();
    if (trimmed.isEmpty) return '';

    appendLog('> $trimmed');
    final parts = trimmed.split(RegExp(r'\s+'));
    final exe = parts.first;
    final args = parts.sublist(1);

    try {
      final result = await Process.run(exe, args);
      final out = '${result.stdout}${result.stderr}'.trim();
      if (out.isNotEmpty) {
        appendLog(out);
      }
      return out;
    } catch (e) {
      final err = 'Ошибка выполнения: $e';
      appendLog('❌ $err');
      return err;
    }
  }
}

final fastbootAdbProvider =
    StateNotifierProvider<FastbootAdbNotifier, FastbootAdbState>((ref) {
  return FastbootAdbNotifier();
});
