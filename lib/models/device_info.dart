enum DeviceMode {
  disconnected,
  fastboot,
  fastbootd,
  adb,
  recovery,
  edl,
}

class DeviceInfo {
  final String serial;
  final String product;
  final String brand;
  final DeviceMode mode;
  final bool isUnlocked;
  final String? currentSlot;
  final int? antiRollback;
  final int? batteryLevel;
  final String? batteryVoltage;
  final String? baseband;
  final bool? isSecure;
  final Map<String, String> rawVars;

  const DeviceInfo({
    required this.serial,
    required this.product,
    required this.brand,
    required this.mode,
    this.isUnlocked = false,
    this.currentSlot,
    this.antiRollback,
    this.batteryLevel,
    this.batteryVoltage,
    this.baseband,
    this.isSecure,
    this.rawVars = const {},
  });

  bool get isConnected => mode != DeviceMode.disconnected;

  String get displayName {
    if (product.isNotEmpty) {
      return '${brand.isNotEmpty ? "$brand " : ""}$product ($serial)';
    }
    return serial.isNotEmpty ? 'Устройство $serial' : 'Устройство не подключено';
  }

  String get modeLabel {
    switch (mode) {
      case DeviceMode.fastboot:
        return 'FASTBOOT';
      case DeviceMode.fastbootd:
        return 'FASTBOOTD';
      case DeviceMode.adb:
        return 'ADB (ANDROID)';
      case DeviceMode.recovery:
        return 'RECOVERY';
      case DeviceMode.edl:
        return 'EDL (9008)';
      case DeviceMode.disconnected:
        return 'ОТКЛЮЧЕНО';
    }
  }

  static DeviceInfo disconnected() {
    return const DeviceInfo(
      serial: '',
      product: '',
      brand: '',
      mode: DeviceMode.disconnected,
    );
  }
}
