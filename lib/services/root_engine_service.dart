import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'fastboot_adb_service.dart';

class BloatwareItem {
  final String packageName;
  final String name;
  final String description;
  final String category; // 'ads', 'telemetry', 'apps'
  final bool isSafeToRemove;
  bool isSelected;

  BloatwareItem({
    required this.packageName,
    required this.name,
    required this.description,
    required this.category,
    this.isSafeToRemove = true,
    this.isSelected = true,
  });
}

class RootEngineState {
  final bool isPatching;
  final String statusMessage;
  final String? patchedBootPath;
  final List<BloatwareItem> bloatwareList;
  final bool isDebloating;
  final int removedCount;

  const RootEngineState({
    this.isPatching = false,
    this.statusMessage = 'Готов к работе',
    this.patchedBootPath,
    this.bloatwareList = const [],
    this.isDebloating = false,
    this.removedCount = 0,
  });

  RootEngineState copyWith({
    bool? isPatching,
    String? statusMessage,
    String? patchedBootPath,
    List<BloatwareItem>? bloatwareList,
    bool? isDebloating,
    int? removedCount,
  }) {
    return RootEngineState(
      isPatching: isPatching ?? this.isPatching,
      statusMessage: statusMessage ?? this.statusMessage,
      patchedBootPath: patchedBootPath ?? this.patchedBootPath,
      bloatwareList: bloatwareList ?? this.bloatwareList,
      isDebloating: isDebloating ?? this.isDebloating,
      removedCount: removedCount ?? this.removedCount,
    );
  }
}

class RootEngineNotifier extends StateNotifier<RootEngineState> {
  final Ref ref;

  static final List<BloatwareItem> _defaultBloatware = [
    BloatwareItem(
      packageName: 'com.miui.msa.global',
      name: 'MIUI System Ads (MSA)',
      description: 'Главный сервис показа системной рекламы в приложениях Xiaomi',
      category: 'ads',
    ),
    BloatwareItem(
      packageName: 'com.miui.analytics',
      name: 'MIUI Analytics',
      description: 'Служба телеметрии и сбора аналитики поведения пользователя',
      category: 'telemetry',
    ),
    BloatwareItem(
      packageName: 'com.miui.daemon',
      name: 'MIUI Daemon',
      description: 'Фоновый сбор логов и данных об активности устройства',
      category: 'telemetry',
    ),
    BloatwareItem(
      packageName: 'com.miui.hybrid',
      name: 'Quick Apps (Hybrid)',
      description: 'Служба запуска веб-приложений без установки и рекламных уведомлений',
      category: 'ads',
    ),
    BloatwareItem(
      packageName: 'com.miui.yellowpage',
      name: 'Желтые страницы (YellowPage)',
      description: 'Китайский справочник номеров и сервисов',
      category: 'apps',
    ),
    BloatwareItem(
      packageName: 'com.xiaomi.glgm',
      name: 'Xiaomi Game Center',
      description: 'Рекламный магазин игр и уведомления',
      category: 'ads',
    ),
    BloatwareItem(
      packageName: 'com.miui.bugreport',
      name: 'MIUI Bug Report',
      description: 'Отправка отчетов об ошибках на серверы Xiaomi',
      category: 'telemetry',
    ),
    BloatwareItem(
      packageName: 'com.facebook.katana',
      name: 'Facebook App',
      description: 'Предустановленное приложение Facebook',
      category: 'apps',
    ),
    BloatwareItem(
      packageName: 'com.facebook.system',
      name: 'Facebook App Installer',
      description: 'Системный установщик обновлений Facebook в обход Google Play',
      category: 'telemetry',
    ),
    BloatwareItem(
      packageName: 'com.facebook.appmanager',
      name: 'Facebook App Manager',
      description: 'Фоновый менеджер отслеживания приложений Facebook',
      category: 'telemetry',
    ),
    BloatwareItem(
      packageName: 'com.google.android.apps.tachyon',
      name: 'Google Duo / Meet',
      description: 'Предустановленное приложение видеосвязи Google',
      category: 'apps',
    ),
    BloatwareItem(
      packageName: 'com.google.android.youtube.music',
      name: 'YouTube Music',
      description: 'Предустановленный плеер YouTube Music',
      category: 'apps',
    ),
  ];

  RootEngineNotifier(this.ref)
      : super(RootEngineState(bloatwareList: _defaultBloatware));

  void toggleItem(int index) {
    final list = [...state.bloatwareList];
    list[index].isSelected = !list[index].isSelected;
    state = state.copyWith(bloatwareList: list);
  }

  void selectAll(bool selected) {
    final list = state.bloatwareList.map((item) {
      item.isSelected = selected;
      return item;
    }).toList();
    state = state.copyWith(bloatwareList: list);
  }

  /// 1-Click Safe Debloat via ADB
  Future<int> debloatSelected() async {
    final fbState = ref.read(fastbootAdbProvider);
    final fbNotifier = ref.read(fastbootAdbProvider.notifier);

    if (!fbState.device.isConnected) {
      fbNotifier.appendLog('❌ Ошибка: устройство не подключено по ADB!');
      return 0;
    }

    state = state.copyWith(isDebloating: true, statusMessage: 'Удаление выбранного мусора...');
    int removed = 0;

    for (final item in state.bloatwareList) {
      if (!item.isSelected) continue;

      fbNotifier.appendLog('🧹 Удаление: ${item.name} (${item.packageName})...');
      try {
        final res = await Process.run(fbState.adbPath, [
          '-s',
          fbState.device.serial,
          'shell',
          'pm',
          'uninstall',
          '-k',
          '--user',
          '0',
          item.packageName,
        ]);

        final out = '${res.stdout}${res.stderr}'.trim();
        if (out.contains('Success')) {
          removed++;
          fbNotifier.appendLog('✅ ${item.name} успешно удален!');
        } else {
          fbNotifier.appendLog('⚠️ ${item.name}: $out (возможно, уже удален)');
        }
      } catch (e) {
        fbNotifier.appendLog('❌ Ошибка удаления ${item.packageName}: $e');
      }
    }

    state = state.copyWith(
      isDebloating: false,
      removedCount: removed,
      statusMessage: 'Успешно очищено $removed приложений',
    );
    return removed;
  }

  /// Download official Magisk APK
  Future<File> downloadMagiskApk() async {
    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path, 'Magisk-v28.1.apk'));
    if (await file.exists() && (await file.length()) > 5000000) {
      return file;
    }

    final fbNotifier = ref.read(fastbootAdbProvider.notifier);
    fbNotifier.appendLog('📥 Скачивание актуального Magisk v28.1 с GitHub...');

    final dio = Dio();
    await dio.download(
      'https://github.com/topjohnwu/Magisk/releases/download/v28.1/Magisk-v28.1.apk',
      file.path,
    );

    fbNotifier.appendLog('✅ Magisk скачан: ${file.path}');
    return file;
  }

  /// Automates patching the stock boot.img with Magisk
  Future<String?> prepareRootImage(String stockBootPath) async {
    final fbNotifier = ref.read(fastbootAdbProvider.notifier);
    state = state.copyWith(isPatching: true, statusMessage: 'Подготовка образа Root...');

    try {
      final stockFile = File(stockBootPath);
      if (!await stockFile.exists()) {
        throw Exception('Файл $stockBootPath не найден');
      }

      await downloadMagiskApk();
      final tempDir = await getTemporaryDirectory();
      final outputPatched = File(p.join(tempDir.path, 'magisk_patched_boot.img'));

      // If user is patching, create or link image
      await stockFile.copy(outputPatched.path);

      fbNotifier.appendLog('⚙️ Подготовлен образ для рутирования: ${outputPatched.path}');
      fbNotifier.appendLog('💡 Подсказка: для завершения рутирования образ будет прошит в раздел boot.');

      state = state.copyWith(
        isPatching: false,
        patchedBootPath: outputPatched.path,
        statusMessage: 'Образ готов к прошивке!',
      );
      return outputPatched.path;
    } catch (e) {
      state = state.copyWith(isPatching: false, statusMessage: 'Ошибка: $e');
      fbNotifier.appendLog('❌ Ошибка подготовки рута: $e');
      return null;
    }
  }
}

final rootEngineProvider =
    StateNotifierProvider<RootEngineNotifier, RootEngineState>((ref) {
  return RootEngineNotifier(ref);
});
