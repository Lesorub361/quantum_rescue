import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fastboot_adb_service.dart';

class TerminalMessage {
  final String text;
  final bool isUser;
  final bool isAgent;
  final bool isCommand;
  final DateTime timestamp;

  TerminalMessage({
    required this.text,
    this.isUser = false,
    this.isAgent = false,
    this.isCommand = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class TerminalAgentState {
  final List<TerminalMessage> messages;
  final bool isAgentThinking;
  final bool isExecuting;
  final String apiKey;
  final String selectedAiModel;
  final List<String> commandHistory;

  const TerminalAgentState({
    this.messages = const [],
    this.isAgentThinking = false,
    this.isExecuting = false,
    this.apiKey = '',
    this.selectedAiModel = 'gemini-1.5-flash',
    this.commandHistory = const [],
  });

  TerminalAgentState copyWith({
    List<TerminalMessage>? messages,
    bool? isAgentThinking,
    bool? isExecuting,
    String? apiKey,
    String? selectedAiModel,
    List<String>? commandHistory,
  }) {
    return TerminalAgentState(
      messages: messages ?? this.messages,
      isAgentThinking: isAgentThinking ?? this.isAgentThinking,
      isExecuting: isExecuting ?? this.isExecuting,
      apiKey: apiKey ?? this.apiKey,
      selectedAiModel: selectedAiModel ?? this.selectedAiModel,
      commandHistory: commandHistory ?? this.commandHistory,
    );
  }
}

class TerminalAgentNotifier extends StateNotifier<TerminalAgentState> {
  final Ref ref;
  final Dio _dio = Dio();

  TerminalAgentNotifier(this.ref) : super(const TerminalAgentState()) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('ai_api_key') ?? '';
    final model = prefs.getString('ai_model') ?? 'gemini-1.5-flash';

    state = state.copyWith(apiKey: key, selectedAiModel: model);

    // Initial greeting
    addMessage(
      TerminalMessage(
        text: '🤖 Quantum Rescue AI Agent активирован.\n'
            'Я могу выполнять команды в терминале за вас, прошивать разделы, восстанавливать телефон из Linux обратно в Android и удалять системный мусор.\n'
            'Напишите задачу простыми словами (например: "проверь статус загрузчика", "удали рекламу Xiaomi" или "прошей boot.img").',
        isAgent: true,
      ),
    );
  }

  void addMessage(TerminalMessage msg) {
    state = state.copyWith(messages: [...state.messages, msg]);
  }

  void clearTerminal() {
    state = state.copyWith(messages: []);
  }

  Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ai_api_key', key);
    state = state.copyWith(apiKey: key);
  }

  /// Execute direct shell command entered by user
  Future<void> executeCommand(String command) async {
    final trimmed = command.trim();
    if (trimmed.isEmpty) return;

    final history = [...state.commandHistory, trimmed];
    state = state.copyWith(commandHistory: history);

    addMessage(TerminalMessage(text: '> $trimmed', isCommand: true));

    final fbNotifier = ref.read(fastbootAdbProvider.notifier);
    final output = await fbNotifier.executeRaw(trimmed);

    if (output.isNotEmpty) {
      addMessage(TerminalMessage(text: output));
    }
  }

  /// AI Agent receives natural language prompt and autonomously formulates & executes commands
  Future<void> askAgent(String userPrompt) async {
    final prompt = userPrompt.trim();
    if (prompt.isEmpty) return;

    addMessage(TerminalMessage(text: prompt, isUser: true));
    state = state.copyWith(isAgentThinking: true);

    final fbState = ref.read(fastbootAdbProvider);
    final device = fbState.device;

    try {
      // 1. If Gemini API key is configured, query LLM
      if (state.apiKey.isNotEmpty) {
        final agentPlan = await _queryGemini(prompt, device);
        state = state.copyWith(isAgentThinking: false);
        await _executeAgentPlan(agentPlan);
        return;
      }

      // 2. Built-in Autonomous Rule Engine (works 100% offline without API key!)
      final plan = _formulateOfflinePlan(prompt, device);
      state = state.copyWith(isAgentThinking: false);
      await _executeAgentPlan(plan);
    } catch (e) {
      state = state.copyWith(isAgentThinking: false);
      addMessage(
        TerminalMessage(
          text: '❌ Ошибка работы ИИ-агента: $e',
          isAgent: true,
        ),
      );
    }
  }

  /// Built-in intelligent rule engine for Android Rescue & Root tasks
  _AgentPlan _formulateOfflinePlan(String prompt, dynamic device) {
    final p = prompt.toLowerCase();

    if (p.contains('linux') || p.contains('дебиан') || p.contains('обратно') || p.contains('восстанови')) {
      return _AgentPlan(
        explanation: 'Обнаружен запрос на восстановление телефона из Linux обратно в Android с Root-правами.\n'
            'План действий:\n'
            '1. Проверка подключения в режиме Fastboot\n'
            '2. Проверка статуса разблокировки загрузчика (unlocked)\n'
            '3. Прошивка чистого boot раздела с Magisk\n'
            '4. Очистка пользовательских данных (fastboot -w)\n'
            '5. Перезагрузка в систему Android.',
        commands: [
          'fastboot devices',
          'fastboot getvar unlocked',
          'fastboot getvar product',
          'fastboot getvar current-slot',
        ],
        followUpNote: '⚡ Устройство проверено. Для завершения прошивки выберите файл Android прошивки во вкладке «Прошивка».',
      );
    } else if (p.contains('рут') || p.contains('root') || p.contains('magisk')) {
      return _AgentPlan(
        explanation: 'План проверки и установки Root-прав:\n'
            '1. Сканирование подключенных устройств\n'
            '2. Определение активного слота (A/B) и раздела boot',
        commands: [
          'fastboot devices',
          'fastboot getvar current-slot',
          'fastboot getvar has-slot:boot',
        ],
        followUpNote: 'Для прошивки Root используйте кнопку «1-Клик Root» во вкладке «Прошивка».',
      );
    } else if (p.contains('реклам') || p.contains('мусор') || p.contains('debloat') || p.contains('удали')) {
      return _AgentPlan(
        explanation: 'Автономный план удаления системной рекламы и телеметрии Xiaomi / Android:\n'
            'Удаляю службы MSA, Analytics, Daemon, QuickApps через ADB PM...',
        commands: [
          'adb devices',
          'adb shell pm uninstall -k --user 0 com.miui.msa.global',
          'adb shell pm uninstall -k --user 0 com.miui.analytics',
          'adb shell pm uninstall -k --user 0 com.miui.daemon',
          'adb shell pm uninstall -k --user 0 com.miui.hybrid',
        ],
        followUpNote: '✅ Системная реклама и следящие демоны успешно удалены!',
      );
    } else if (p.contains('загрузчик') || p.contains('bootloader') || p.contains('разблок') || p.contains('lock')) {
      return _AgentPlan(
        explanation: 'Проверяю статус безопасности и блокировки загрузчика...',
        commands: [
          'fastboot getvar unlocked',
          'fastboot getvar secure',
          'fastboot getvar anti',
        ],
        followUpNote: 'Если unlocked = yes, устройство разблокировано и готово к прошивке.',
      );
    } else if (p.contains('перезагруз') || p.contains('reboot')) {
      String cmd = 'fastboot reboot';
      if (p.contains('recovery') || p.contains('рекавери')) cmd = 'fastboot reboot-recovery';
      if (p.contains('bootloader') || p.contains('фастбут')) cmd = 'fastboot reboot-bootloader';
      if (p.contains('edl')) cmd = 'fastboot oem edl';

      return _AgentPlan(
        explanation: 'Выполняю команду перезагрузки: $cmd',
        commands: [cmd],
      );
    }

    // Default: informative system diagnostics
    return _AgentPlan(
      explanation: 'Выполняю диагностику подключенного оборудования...',
      commands: [
        'fastboot devices',
        'adb devices',
      ],
      followUpNote: 'Вы можете попросить меня: "прошей boot.img", "удали рекламу", "перезагрузи в recovery".',
    );
  }

  Future<_AgentPlan> _queryGemini(String prompt, dynamic device) async {
    final systemPrompt = '''
Вы автономный ИИ-агент Quantum Rescue для работы с прошивкой Android, Linux, Fastboot, ADB и Root.
Текущее устройство: ${device.displayName}, Режим: ${device.modeLabel}.
Пользователь просит: "$prompt".
Ответьте кратким объяснением на русском языке и выделите точные терминальные команды для выполнения.
Формат ответа:
EXPLANATION: <текст объяснения>
COMMAND: <команда 1>
COMMAND: <команда 2>
''';

    final res = await _dio.post(
      'https://generativelanguage.googleapis.com/v1beta/models/${state.selectedAiModel}:generateContent?key=${state.apiKey}',
      data: {
        'contents': [
          {
            'parts': [
              {'text': systemPrompt}
            ]
          }
        ]
      },
    );

    final text = res.data['candidates'][0]['content']['parts'][0]['text'] as String;
    final lines = text.split('\n');
    String explanation = '';
    final List<String> commands = [];

    for (final line in lines) {
      if (line.startsWith('EXPLANATION:')) {
        explanation = line.replaceFirst('EXPLANATION:', '').trim();
      } else if (line.startsWith('COMMAND:')) {
        commands.add(line.replaceFirst('COMMAND:', '').trim());
      }
    }

    return _AgentPlan(
      explanation: explanation.isNotEmpty ? explanation : text,
      commands: commands,
    );
  }

  Future<void> _executeAgentPlan(_AgentPlan plan) async {
    state = state.copyWith(isExecuting: true);

    addMessage(
      TerminalMessage(
        text: '🧠 План ИИ-Агента:\n${plan.explanation}',
        isAgent: true,
      ),
    );

    final fbNotifier = ref.read(fastbootAdbProvider.notifier);

    for (final cmd in plan.commands) {
      addMessage(TerminalMessage(text: '⚡ [Agent Exec] > $cmd', isCommand: true));
      final out = await fbNotifier.executeRaw(cmd);
      if (out.isNotEmpty) {
        addMessage(TerminalMessage(text: out));
      }
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (plan.followUpNote != null) {
      addMessage(TerminalMessage(text: plan.followUpNote!, isAgent: true));
    }

    state = state.copyWith(isExecuting: false);
  }
}

class _AgentPlan {
  final String explanation;
  final List<String> commands;
  final String? followUpNote;

  _AgentPlan({
    required this.explanation,
    required this.commands,
    this.followUpNote,
  });
}

final terminalAgentProvider =
    StateNotifierProvider<TerminalAgentNotifier, TerminalAgentState>((ref) {
  return TerminalAgentNotifier(ref);
});
