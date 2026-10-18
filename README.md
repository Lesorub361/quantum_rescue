# ⚡️ QuantumRescue

**Universal Android Fastboot/OTG Flasher, Root Engine & AI Agent Terminal**

Кроссплатформенный комбайн для ПК (Linux/Windows) и Android (OTG) для прошивки, раскирпичивания, установки Root-прав и управления устройством через автономного ИИ-агента.

---

## 🚀 Основные возможности

### 1. ⚡️ Студия прошивки Fastboot (PC & OTG)
* **Поддержка любых Android смартфонов**: Xiaomi, Redmi, POCO, Google Pixel, OnePlus, Samsung, Realme и др.
* **Авто-определение устройств**: автоматическое чтение серийного номера, кодового имени модели (curtana, surya, sweet, alioth и др.), статуса блокировки загрузчика (unlocked), активного слота (A/B) и счетчика Anti-Rollback (ARB).
* **Прошивка любых разделов**: `boot`, `init_boot`, `recovery`, `super`, `vbmeta`, `dtbo`, `cust`.
* **Защита от бутлупа**: опция отключения проверки целостности `--disable-verity --disable-verification` для `vbmeta`.
* **Тестовый запуск**: команда `fastboot boot <image.img>` для запуска TWRP или пропатченного ядра без прошивки в память.

### 2. 🛡️ 1-Клик Root (Magisk / KernelSU)
* Автоматическая загрузка официального Magisk APK с GitHub.
* Подготовка и прошивка модифицированного `boot.img` в один клик.
* Восстановление телефонов с Linux (Debian/postmarketOS) обратно на чистый Android с уже готовым Root-доступом.

### 3. 🤖 Встроенный AI-Агент и Терминал
* **Автономное выполнение**: пишите задачу простым языком (*«Верни телефон с Linux на Android с рутом»*, *«Удали рекламу Xiaomi»*, *«Проверь статус загрузчика»*).
* Агент сам формирует цепочку терминальных команд, выполняет их, парсит вывод и отчитывается.
* **Офлайн-режим**: встроенный эвристический движок правил работает без интернета.
* **Gemini AI**: опциональное подключение API ключа для решения сложных нестандартных ошибок прошивки.

### 4. 🧹 Безопасный Debloater для Xiaomi и Android
* База данных рекламных и следящих сервисов: MIUI MSA, Analytics, Daemon, Quick Apps, YellowPages, Facebook Services.
* Удаление через `pm uninstall -k --user 0` без риска кирпича и с возможностью восстановления.

---

## 📦 Сборка и релизы
Проект автоматически собирается через GitHub Actions в:
* **Android APK** (Universal + Split ABIs: arm64-v8a, armeabi-v7a, x86_64)
* **Linux Desktop bundle** (x64)
